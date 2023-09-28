# Use Ubuntu 23.04 as a base image
FROM ubuntu:23.04

# The environment variable ensures that the python output is set straight
# to the terminal with out buffering it first
ENV PYTHONUNBUFFERED 1
ENV DEBIAN_FRONTEND noninteractive

# Install OpenJDK 19, Python3, pip and setup environment
RUN apt-get update && apt-get install -y \
    python3 \
    python3-venv \
    python3-pip \
    openjdk-8-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

# Set up JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Set working directory to /app
WORKDIR /app


# Create jovyan user
RUN useradd -ms /bin/bash jovyan

# Change to jovyan user
USER jovyan

# Setup Python Virtualenv
RUN python3 -m venv /home/jovyan/pyspark_venv
ENV PATH="/home/jovyan/pyspark_venv/bin:$PATH"

# Install Jupyter Lab and PySpark
COPY --chown=jovyan requirements.txt /app
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose Jupyter lab port
EXPOSE 8888

# add jovyan to sudo group
USER root
RUN usermod -a -G sudo jovyan

# change user back to jovyan
USER jovyan
WORKDIR /home/jovyan/notebooks

# Start Jupyter lab when container is run
CMD ["jupyter", "lab", "--ip='*'", "--port=8888", "--no-browser"]