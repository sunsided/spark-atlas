ARG flavor=master

# https://github.com/big-data-europe/docker-spark
FROM bde2020/spark-${flavor}:3.3.0-hadoop3.3
LABEL authors="Markus Mayer"

# Download MongoDB Spark Connector and move it to the jars directory
# See https://www.mongodb.com/docs/spark-connector/current/
RUN wget https://repo1.maven.org/maven2/org/mongodb/spark/mongo-spark-connector_2.12/10.2.0/mongo-spark-connector_2.12-10.2.0.jar -P /spark/jars
RUN wget https://repo1.maven.org/maven2/org/mongodb/mongodb-driver-sync/4.8.2/mongodb-driver-sync-4.8.2.jar -P /spark/jars
RUN wget https://repo1.maven.org/maven2/org/mongodb/mongodb-driver-core/4.8.2/mongodb-driver-core-4.8.2.jar -P /spark/jars
RUN wget https://repo1.maven.org/maven2/org/mongodb/bson/4.8.2/bson-4.8.2.jar -P /spark/jars
RUN wget https://repo1.maven.org/maven2/org/mongodb/bson-record-codec/4.8.2/bson-record-codec-4.8.2.jar -P /spark/jars
RUN chown 1000:1000 /spark/jars/*.jar

ENV SPARK_HOME /spark
COPY log4j2.properties /spark/conf/
COPY spark-defaults.conf /spark/conf/