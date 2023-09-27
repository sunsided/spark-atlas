#!/bin/bash

if [ -z "$SPARK_HOME" ]; then
    echo "Error: SPARK_HOME is not set."
    exit 1
fi

if [ -z "$SPARK_MASTER" ]; then
    echo "Error: SPARK_MASTER is not set."
    exit 1
fi

if [ -z "$SPARK_WORKER_CORES" ]; then
    echo "Error: SPARK_WORKER_CORES is not set."
    exit 1
fi

"$SPARK_HOME/bin/spark-class" org.apache.spark.deploy.worker.Worker --cores "$SPARK_WORKER_CORES" --memory "$SPARK_WORKER_MEMORY" "$SPARK_MASTER"