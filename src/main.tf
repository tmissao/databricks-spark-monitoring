resource "azurerm_resource_group" "this" {
  name     = var.resource_group.name
  location = var.resource_group.location
  tags     = local.tags
}

resource "azurerm_key_vault" "this" {
  name                       = var.keyvault.name
  location                   = azurerm_resource_group.this.location
  sku_name                   = var.keyvault.sku
  resource_group_name        = azurerm_resource_group.this.name
  tenant_id                  = data.azurerm_subscription.current.tenant_id
  soft_delete_retention_days = var.keyvault.soft_delete_retention_days
  purge_protection_enabled   = var.keyvault.purge_protection_enabled
  tags                       = local.tags
}

resource "azurerm_key_vault_access_policy" "this" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  secret_permissions = [
    "Backup", "Delete", "Get", "List", "Recover", "Restore", "Set"
  ]
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.log_analytics.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = var.log_analytics.sku
  retention_in_days   = var.log_analytics.retention_in_days
}

resource "azurerm_key_vault_secret" "log_analytics_workspace_id" {
  name         = "log-analytics-workspace-id"
  value        = azurerm_log_analytics_workspace.this.workspace_id
  key_vault_id = azurerm_key_vault.this.id
  depends_on = [azurerm_key_vault_access_policy.this]
}

resource "azurerm_key_vault_secret" "log_analytics_workspace_key" {
  name         = "log-analytics-workspace-key"
  value        = azurerm_log_analytics_workspace.this.primary_shared_key
  key_vault_id = azurerm_key_vault.this.id
  depends_on = [azurerm_key_vault_access_policy.this]
}

resource "azurerm_databricks_workspace" "this" {
  name                = var.databrick.name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = var.databrick.sku
  tags = local.tags
}

resource "databricks_secret_scope" "this" {
  name                     = azurerm_key_vault.this.name
  initial_manage_principal = "users"
  keyvault_metadata {
    resource_id = azurerm_key_vault.this.id
    dns_name    = azurerm_key_vault.this.vault_uri
  }
  depends_on = [azurerm_databricks_workspace.this, azurerm_key_vault.this]
}

resource "databricks_dbfs_file" "spark_monitoring" {
  source = var.spark_monitoring_script_local_path
  path   = var.databricks_spark_monitoring_script_path
}

resource "databricks_dbfs_file" "spark_monitoring_libs" {
  for_each = toset(var.spark_libs_names)
  source = "${var.spark_libs_local_path}/${each.value}"
  path   = "${var.databricks_spark_monitoring_libs_path}/${each.value}"
}

resource "databricks_cluster" "this" {
  cluster_name            = var.databrick.cluster.name
  spark_version           = data.databricks_spark_version.this.id
  node_type_id            = data.databricks_node_type.this.id
  autotermination_minutes = var.databrick.cluster.autotermination_minutes
  spark_conf = {
    # Single-node
    "spark.databricks.cluster.profile" : "singleNode"
    "spark.master" : "local[*]"
  }
  custom_tags = {
    # Single-node
    "ResourceClass" = "SingleNode"
  }
  azure_attributes {
    availability       = "SPOT_AZURE"
  }
  init_scripts {
    dbfs {
      destination = "dbfs:/databricks/spark-monitoring/spark-monitoring.sh"
    }
  }
  spark_env_vars = local.databricks_spark_environment_vars
  depends_on = [
    databricks_secret_scope.this,
    azurerm_key_vault_secret.log_analytics_workspace_key,
    azurerm_key_vault_secret.log_analytics_workspace_id
  ]
}

resource "databricks_dbfs_file" "spark_sample_job_jar" {
  source = var.databricks_spark_sample_job.jar_local_path
  path   = var.databricks_spark_sample_job.jar_databricks_path
}

resource "databricks_library" "spark_sample_job_jar" {
  cluster_id = databricks_cluster.this.id
  jar        = databricks_dbfs_file.spark_sample_job_jar.dbfs_path
}

resource "databricks_job" "spark_sample_job" {
  name = var.databricks_spark_sample_job.name
  existing_cluster_id = databricks_cluster.this.id
  library {
    jar = databricks_dbfs_file.spark_sample_job_jar.dbfs_path
  }
  spark_jar_task {
    main_class_name = var.databricks_spark_sample_job.jar_main_class_name
  }
}