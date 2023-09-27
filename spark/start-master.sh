#!/bin/bash

if [ -z "$SPARK_HOME" ]; then
    echo "Error: SPARK_HOME is not set."
    exit 1
fi

if [ -z "$SPARK_MASTER_HOST" ]; then
    echo "Error: SPARK_MASTER_HOST is not set."
    exit 1
fi

if [ -z "$SPARK_MASTER_PORT" ]; then
    echo "Error: SPARK_MASTER_PORT is not set."
    exit 1
fi

"$SPARK_HOME/bin/spark-class" org.apache.spark.deploy.master.Master --host "$SPARK_MASTER_HOST" --port "$SPARK_MASTER_PORT"