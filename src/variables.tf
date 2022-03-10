locals {
  tags = merge(
    var.tags,
    {
      subscription   = data.azurerm_subscription.current.display_name
      resource_group = var.resource_group.name
    }
  )
  databricks_spark_environment_vars = {
    PYSPARK_PYTHON="/databricks/python3/bin/python3"
    LOG_ANALYTICS_WORKSPACE_ID = "{{secrets/${databricks_secret_scope.this.name}/${azurerm_key_vault_secret.log_analytics_workspace_id.name}}}"
    LOG_ANALYTICS_WORKSPACE_KEY = "{{secrets/${databricks_secret_scope.this.name}/${azurerm_key_vault_secret.log_analytics_workspace_key.name}}}"
    AZ_SUBSCRIPTION_ID = data.azurerm_subscription.current.subscription_id
    AZ_RSRC_GRP_NAME = azurerm_resource_group.this.name
    AZ_RSRC_PROV_NAMESPACE = "Microsoft.Databricks"
    AZ_RSRC_TYPE = "workspaces"
    AZ_RSRC_NAME = var.databrick.cluster.name
  }
}

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

data "databricks_spark_version" "this" {
  spark_version = var.databrick.cluster.spark_version
  scala   = var.databrick.cluster.scala_version
  depends_on = [azurerm_databricks_workspace.this]
}

data "databricks_node_type" "this" {
  local_disk = true
  depends_on = [azurerm_databricks_workspace.this]
}

variable "resource_group" {
  type = object({
    name = string, location = string
  })
  default = {
    name     = "databricks-monitoring-rg"
    location = "westus2"
  }
}

variable "keyvault" {
  type = object({
    name                       = string, sku = string, 
    purge_protection_enabled = bool, soft_delete_retention_days = number
  })
  default = {
    name                       = "databricks-monitoring-kv"
    sku                        = "standard"
    purge_protection_enabled   = false
    soft_delete_retention_days = 7
  }
}

variable "log_analytics" {
  type = object({
    name = string, sku = string, retention_in_days = number
  })
  default = {
    name = "databricks-la"
    sku = "PerGB2018"
    retention_in_days  = 30
  }
}

variable "databrick" {
  type = object({
    sku  = string
    name = string
    cluster = object({
      name = string, spark_version = string, scala_version = string
      autotermination_minutes = number
    })
  })
  default = {
    name = "demo-dbk"
    sku  = "standard"
    cluster = {
      name = "demo"
      spark_version = "3.1.2"
      scala_version = "2.12"
      autotermination_minutes = 30
    }
  }
}

variable "spark_monitoring_script_local_path" {
  type = string
  default = "../artifacts/scripts/spark-monitoring.sh"
}

variable "spark_libs_local_path" {
  type = string
  default = "../artifacts/libs"
}

variable "spark_libs_names" {
  type = list(string)
  default = [
    "spark-listeners-loganalytics_2.4.5_2.11-1.0.0.jar",
    "spark-listeners-loganalytics_3.1.2_2.12-1.0.0.jar",
    "spark-listeners-loganalytics_3.0.1_2.12-1.0.0.jar",
    "spark-listeners-loganalytics_3.2.0_2.12-1.0.0.jar",
    "spark-listeners_2.4.5_2.11-1.0.0.jar",
    "spark-listeners_3.1.2_2.12-1.0.0.jar",
    "spark-listeners_3.0.1_2.12-1.0.0.jar",
    "spark-listeners_3.2.0_2.12-1.0.0.jar"
  ]
}

variable "databricks_spark_monitoring_script_path" {
  type = string
  default = "/databricks/spark-monitoring/spark-monitoring.sh"
}

variable "databricks_spark_monitoring_libs_path" {
  type = string
  default = "/databricks/spark-monitoring"
}

variable "databricks_spark_sample_job" {
  type = object({
    name = string, jar_local_path = string, jar_databricks_path = string, 
    jar_main_class_name = string
  })
  default = {
    name = "Spark Sample Job"
    jar_local_path = "../artifacts/sample/spark-sample-job/target/spark-sample-job-0.0.1.jar"
    jar_databricks_path = "/databricks/spark-monitoring/spark-sample-job-0.0.1.jar"
    jar_main_class_name = "br.com.missao.samplejob.LogSampleJob"
  }
}

variable tags {
  type = map(string)
  default = {
    "environment" = "poc"
  }
}
