# Container for Apache Spark, PySpark-Pandas, RasterFrames, GeoParquet
# FROM ubuntu:23:04 note Spark 3.4.0 will support Python 3.11

# inspired by https://stackoverflow.com/a/76309110/195651
FROM ubuntu:23.04 AS base

# Setup Spark Version Requirements
ENV SPARK_HOME=/usr/local/spark
ARG SPARK_V="3.4.0"
ARG HADOOP_V="3"
ARG SCALA_V="13"
ARG OPENJDK_V="19"

# Apache Spark 3.4.0 with Scala2.13 Checksum from https://spark.apache.org/downloads.html
ARG spark_checksum="90531aeb69500d584087757df5c88b3ab768ee4fb6719b1c80391465dad082a7ed4a05cdfb156c122f13103fad6895b41852ff726c78e3f0a457cafe6b9899e5"

# Handle user-prompt for Ubuntu installation time zone selection
ENV TZ=America
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# Update Ubuntu
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y apt-utils && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install python
RUN apt-get update --fix-missing && apt-get upgrade -y && \
    apt-get install -y sudo dialog git openssh-server wget \
    curl cmake nano python3 python3-pip python3-setuptools \
    build-essential libpq-dev gdal-bin libgdal-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    "openjdk-${OPENJDK_V}-jre-headless" \
    ca-certificates-java && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get autoclean && apt-get autoremove && \
    apt-get update --fix-missing && apt-get upgrade -y && \
    dpkg --configure -a && apt-get install -f && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Non-Spark Python Packages

# PEP668 - StackOverflow (apt & pip collision avoidance via venv)
# https://stackoverflow.com/questions/75602063/pip-install-r-requirements-txt-is-failing-this-environment-is-externally-manag
# Option1: python3 -m venv .venv && source .venv/bin/activate
# Option2: pip install xyz --break-system-packages

RUN pip3 install \
    GDAL numpy pandas rtree IPython \
    geopandas geoparquet plotly \
    rasterio folium descartes \
    cloudpathlib \
    --break-system-packages

# Spark installation
WORKDIR /tmp
RUN wget -qO "spark.tgz" "https://archive.apache.org/dist/spark/spark-${SPARK_V}/spark-${SPARK_V}-bin-hadoop${HADOOP_V}-scala2.${SCALA_V}.tgz"
RUN echo "${spark_checksum} *spark.tgz" | sha512sum -c -
RUN tar xzf "spark.tgz" -C /usr/local --owner root --group root --no-same-owner
RUN rm "spark.tgz"

# Handle spark home error for /usr/local/spark
#RUN rm "${SPARK_HOME}"
RUN mv /usr/local/spark-3.4.0-bin-hadoop3-scala2.13 "${SPARK_HOME}"

# Configure Spark
ENV SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info" PATH="${PATH}:${SPARK_HOME}/bin"
RUN mkdir -p /usr/local/bin/before-notebook.d
RUN ln -s "/usr/local/spark/sbin/spark-config.sh" /usr/local/bin/before-notebook.d/spark-config.sh

# Install Spark Python Packages
RUN pip3 install \
    scipy pyarrow py4j findspark \
    pyspark pyspark[sql] pyspark[pandas_on_spark] \
    --break-system-packages

# Install MongoDB Connector for Spark
RUN wget https://repo1.maven.org/maven2/org/mongodb/spark/mongo-spark-connector/10.0.5/mongo-spark-connector-10.0.5.jar -P "${SPARK_HOME}/jars"
RUN wget https://repo1.maven.org/maven2/org/mongodb/spark/mongo-spark-connector_2.${SCALA_V}/10.2.0/mongo-spark-connector_2.${SCALA_V}-10.2.0.jar -P "${SPARK_HOME}/jars"
RUN wget https://repo1.maven.org/maven2/org/mongodb/mongodb-driver-sync/4.8.2/mongodb-driver-sync-4.8.2.jar -P "${SPARK_HOME}/jars"
RUN wget https://repo1.maven.org/maven2/org/mongodb/mongodb-driver-core/4.8.2/mongodb-driver-core-4.8.2.jar -P "${SPARK_HOME}/jars"
RUN wget https://repo1.maven.org/maven2/org/mongodb/bson/4.8.2/bson-4.8.2.jar -P "${SPARK_HOME}/jars"
RUN wget https://repo1.maven.org/maven2/org/mongodb/bson-record-codec/4.8.2/bson-record-codec-4.8.2.jar -P "${SPARK_HOME}/jars"

COPY spark-defaults.conf "${SPARK_HOME}/conf/"

WORKDIR /home