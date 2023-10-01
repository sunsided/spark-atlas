# PySpark / MongoDB

Use Docker Compose to start the setup

```shell
docker compose up
```

This will start a setup of

- Spark Master (at [localhost:8090](http://localhost:8090/))
- Spark Worker with 2 CPUs and 4 GB RAM (at [localhost:8081](http://localhost:8081/))
- Spark Worker with 4 CPUs and 4 GB RAM (at [localhost:8082](http://localhost:8082/))
- Spark History Server (at [localhost:18081](http://localhost:18081/))

and

- Jupyter Lab (at [localhost:8888](http://127.0.0.1:8888/lab?token=5f69150501c3c0c4f94f5d4ae38123e2f556777f794bf48b))

Open JupyterLab [here](http://127.0.0.1:8888/lab?token=5f69150501c3c0c4f94f5d4ae38123e2f556777f794bf48b)
or connect to the Jupyter server at `127.0.0.1:8888` and use the following token:

```
5f69150501c3c0c4f94f5d4ae38123e2f556777f794bf48b
```

Use the [Aggegation Pipelines](notebooks/AggregationPipelines.ipynb) notebook
as a starting point.

## About the Dockerfile

The [Dockerfile](spark/Dockerfile) (as used in [docker-compose.yml](docker-compose.yml))
provides three different Docker targets, namely `master`, `worker` and `jupyter`.
All three targets share the same `base` images consisting of: 

- [Spark 3.4.1] (Scala 2.12 + Hadoop 3.3) + PySpark 3.4.1 + [MongoDB Connector for Spark 10.2]
- Ubuntu 23.04 with Java/OpenJDK 17 and Python 3.11

Using the same base image for Jupyter Lab and Spark was the only way to
get this setup working; specifically, having only `master` and `worker` images
and a predefined PySpark image would consistently fail with either JARs not being
found or serialization issues happening when running PySpark programs.

[Spark 3.4.1]: https://spark.apache.org/downloads.html
[MongoDB Connector for Spark 10.2]: https://www.mongodb.com/docs/spark-connector/v10.2/