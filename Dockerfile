FROM jupyter/pyspark-notebook:latest
# Install compatible versions of pyspark and delta-spark
RUN pip install pyspark==3.4.2 delta-spark==2.4.0
