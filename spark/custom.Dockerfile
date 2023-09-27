# Container for Apache Spark, PySpark-Pandas, RasterFrames, GeoParquet
# FROM ubuntu:23:04 note Spark 3.4.0 will support Python 3.11

# inspired by https://stackoverflow.com/a/76309110/195651
FROM ubuntu:23.04 AS base

# Setup Spark Version Requirements
ENV SPARK_HOME=/usr/local/spark
ARG SPARK_V="3.5.0"
ARG HADOOP_V="3"
ARG SCALA_V="12"
ARG OPENJDK_V="19"

# Apache Spark 3.4.0 with Scala2.13 Checksum from https://spark.apache.org/downloads.html
# ARG spark_checksum="90531aeb69500d584087757df5c88b3ab768ee4fb6719b1c80391465dad082a7ed4a05cdfb156c122f13103fad6895b41852ff726c78e3f0a457cafe6b9899e5"
ARG spark_checksum="8883c67e0a138069e597f3e7d4edbbd5c3a565d50b28644aad02856a1ec1da7cb92b8f80454ca427118f69459ea326eaa073cf7b1a860c3b796f4b07c2101319"

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
# RUN wget -qO "spark.tgz" "https://archive.apache.org/dist/spark/spark-${SPARK_V}/spark-${SPARK_V}-bin-hadoop${HADOOP_V}-scala2.${SCALA_V}.tgz"
RUN wget -qO "spark.tgz" "https://archive.apache.org/dist/spark/spark-${SPARK_V}/spark-${SPARK_V}-bin-hadoop${HADOOP_V}.tgz"
RUN echo "${spark_checksum} *spark.tgz" | sha512sum -c -
RUN tar xzf "spark.tgz" -C /usr/local --owner root --group root --no-same-owner
RUN rm "spark.tgz"

# Handle spark home error for /usr/local/spark
#RUN rm "${SPARK_HOME}"
# RUN mv "/usr/local/spark-${SPARK_V}-bin-hadoop${HADOOP_V}-scala2.${SCALA_V}" "${SPARK_HOME}"
RUN mv "/usr/local/spark-${SPARK_V}-bin-hadoop${HADOOP_V}" "${SPARK_HOME}"

# Configure Spark
ENV SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info" PATH="${PATH}:${SPARK_HOME}/bin"
RUN mkdir -p /usr/local/bin/before-notebook.d
RUN ln -s "${SPARK_HOME}/sbin/spark-config.sh" /usr/local/bin/before-notebook.d/spark-config.sh

# Install Spark Python Packages
RUN pip3 install \
    scipy pyarrow py4j findspark \
    pyspark pyspark[sql] pyspark[pandas_on_spark] \
    --break-system-packages

# Install MongoDB Connector for Spark
RUN wget https://repo1.maven.org/maven2/org/mongodb/spark/mongo-spark-connector_2.${SCALA_V}/10.2.0/mongo-spark-connector_2.${SCALA_V}-10.2.0.jar -P "${SPARK_HOME}/jars"
RUN wget https://repo1.maven.org/maven2/org/mongodb/mongodb-driver-sync/4.8.2/mongodb-driver-sync-4.8.2.jar -P "${SPARK_HOME}/jars"
RUN wget https://repo1.maven.org/maven2/org/mongodb/mongodb-driver-core/4.8.2/mongodb-driver-core-4.8.2.jar -P "${SPARK_HOME}/jars"
RUN wget https://repo1.maven.org/maven2/org/mongodb/bson/4.8.2/bson-4.8.2.jar -P "${SPARK_HOME}/jars"
RUN wget https://repo1.maven.org/maven2/org/mongodb/bson-record-codec/4.8.2/bson-record-codec-4.8.2.jar -P "${SPARK_HOME}/jars"

RUN wget https://repo1.maven.org/maven2/org/slf4j/slf4j-api/1.7.6/slf4j-api-1.7.6.jar -P "${SPARK_HOME}/jars"
RUN wget https://repo1.maven.org/maven2/io/netty/netty-tcnative-classes/2.0.54.Final/netty-tcnative-classes-2.0.54.Final.jar -P "${SPARK_HOME}/jars"
RUN wget https://repo1.maven.org/maven2/io/netty/netty-tcnative/2.0.54.Final/netty-tcnative-2.0.54.Final.jar -P "${SPARK_HOME}/jars"

COPY spark-defaults.conf "${SPARK_HOME}/conf/"

WORKDIR /home

FROM base AS master
ENV SPARK_MASTER_HOST=spark-master
ENV SPARK_MASTER_PORT=7077
COPY start-master.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-master.sh
CMD ["/usr/local/bin/start-master.sh"]

FROM base AS worker
ENV SPARK_MASTER=spark://spark-master:7077
ENV SPARK_WORKER_CORES=2
ENV SPARK_WORKER_MEMORY=1g
COPY start-worker.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-worker.sh
CMD ["/usr/local/bin/start-worker.sh"]