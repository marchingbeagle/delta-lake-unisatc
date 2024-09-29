FROM jupyter/pyspark-notebook:latest
# Install compatible versions of pyspark and delta-spark
RUN pip install pyspark==3.2.1 delta-spark==1.0.0
