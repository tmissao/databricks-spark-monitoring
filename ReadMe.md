# Databricks Monitoring

1. Install Databricks CLI e configure token (https://docs.databricks.com/dev-tools/cli/index.html#install-the-cli)
2. Build .jar spark monitoring (https://github.com/mspnp/spark-monitoring)
```bash
 docker run -it --rm -v `pwd`:/spark-monitoring -v "$HOME/.m2":/root/.m2 -w /spark-monitoring/src mcr.microsoft.com/java/maven:8-zulu-debian10 mvn install -P "scala-2.12_spark-3.1.2"
```

sample

profiles:
scala-2.11_spark-2.4.5
scala-2.12_spark-3.0.1
scala-2.12_spark-3.1.2
scala-2.12_spark-3.2.0

docker run -it --rm -v `pwd`/sample/spark-sample-job:/spark-sample-job -v "$HOME/.m2":/root/.m2 -w /spark-sample-job mcr.microsoft.com/java/maven:8-zulu-debian10 mvn install -P scala-2.12_spark-3.1.2


# notebook
https://github.com/mspnp/spark-monitoring/issues/28
https://www.youtube.com/watch?v=fktz63uDzM4&ab_channel=DustinVannoy

## Result
---

![Results](./artifacts/results.gif)