# Exemplo de PySpark com Delta Lake e Dados de Vendas de Carros

Este repositório demonstra como trabalhar com o **Delta Lake** usando **PySpark** e **Docker**, simulando dados de vendas de carros.

## Pré-requisitos

- Docker instalado em sua máquina
- Conhecimentos básicos de PySpark e Delta Lake

## Parte 1 — Configurando o Delta e PySpark com Docker

Em vez de usar ferramentas como o Poetry, utilizaremos o Docker para configurar o ambiente. Siga os passos abaixo para colocar tudo em funcionamento.

### Passo 1: Criar o diretório do projeto

```bash
mkdir pyspark-delta-venda-carros
cd pyspark-delta-venda-carros
```

### Passo 2: Criar o Dockerfile

Crie um arquivo chamado `docker-compose.yml` com o seguinte conteúdo:

```docker-compose.yml
version: "3.8"

services:
  hadoop:
    image: bde2020/hadoop-namenode:2.0.0-hadoop2.7.4-java8
    container_name: hadoop
    environment:
      - CLUSTER_NAME=test
    volumes:
      - hadoop_namenode:/hadoop/dfs/name
    ports:
      - "9870:9870"
      - "9000:9000"

  spark:
    image: bitnami/spark:3.5.0
    environment:
      - SPARK_MASTER_HOST=spark
      - SPARK_WORKER_CORES=1
      - SPARK_RPC_AUTHENTICATION_ENABLED=no
      - SPARK_RPC_ENCRYPTION_ENABLED=no
      - SPARK_LOCAL_STORAGE_ENCRYPTION_ENABLED=no
      - SPARK_SSL_ENABLED=no
      - SPARK_JARS_PACKAGES=io.delta:delta-core_2.12:2.4.0
    ports:
      - "8080:8080"
      - "7077:7077"
    depends_on:
      - hadoop
    volumes:
      - ./spark_data:/opt/spark/work-dir

  jupyterlab:
    build: .
    container_name: jupyterlab
    environment:
      - JUPYTER_ENABLE_LAB=yes
      - JUPYER_TOKEN=senhasecreta
      - SPARK_JARS_PACKAGES=io.delta:delta-core_2.12:2.4.0
    ports:
      - "8888:8888"
    volumes:
      - ./work:/home/jovyan/work
      - ./data:/home/jovyan/data
    depends_on:
      - spark

volumes:
  hadoop_namenode:
  spark_data:
    driver: local

```

### Passo 3: Subir os containers

```bash
docker-compose up -d .
```

Agora, você pode acessar o JupyterLab visitando `http://localhost:8888` em seu navegador.

## Parte 2 — Configuração do Delta Lake

### Imports:

```python
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, StringType, FloatType
from delta import *
```

### Iniciando a Spark Session:

```python
spark = (
    SparkSession
    .builder
    .master("local[*]")
    .config("spark.jars.packages", "io.delta:delta-core_2.12:2.4.0")
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")
    .getOrCreate()
)
```

## Parte 3 — Criando Tabelas Delta

### Exemplo de Dados de Vendas de Carros:

```python
data_venda_carros = [
    ("ABC1234", "Corolla", "SP", 50000.00),
    ("DEF5678", "Civic", "RJ", 75000.00),
    ("GHI9012", "Gol", "MG", 100000.00),
    ("JKL3456", "Onix", "SP", 65000.00),
    ("MNO7890", "HB20", "PR", 85000.00),
    ("PQR2345", "Sandero", "RS", 90000.00),
    ("STU6789", "Uno", "BA", 45000.00),
    ("VWX3456", "Kwid", "SC", 70000.00),
    ("YZA8901", "Argo", "ES", 55000.00),
    ("BCD1234", "Renegade", "PE", 80000.00),
    ("EFG5678", "T-Cross", "GO", 95000.00),
    ("HIJ9012", "Creta", "DF", 120000.00),
    ("KLM3456", "Compass", "TO", 65000.00),
    ("NOP7890", "Strada", "AL", 60000.00),
    ("QRS2345", "HR-V", "PB", 85000.00),
    ("TUV6789", "Tracker", "CE", 70000.00),
    ("WXY3456", "Tiggo", "AM", 50000.00),
    ("ZAB8901", "Duster", "SE", 75000.00),
    ("CDE1234", "S10", "MT", 100000.00),
    ("FGH5678", "Hilux", "PA", 45000.00)
]

schema = (
    StructType([
        StructField("PLACA", StringType(), True),
        StructField("MODELO_CARRO", StringType(), True),
        StructField("UF", StringType(), True),
        StructField("VALOR_CARRO", FloatType(), True)
    ])
)

df = spark.createDataFrame(data=data_venda_carros, schema=schema)
df.show(truncate=False)
```

### Salvando os Dados como Tabela Delta:

```python
df.write.format("delta").mode('overwrite').save("/app/delta/venda_carros")
```

## Parte 4 — Exemplo de Upsert/Merge

Agora, vamos simular a chegada de novos dados de vendas de carros ao nosso Delta Lake:

```python
new_data = [
    ("ABC1234", "Corolla", "SP", 52000.00),
    ("DEF5678", "Civic", "RJ", 77000.00),
    ("NOP7890", "Strada", "AL", 62000.00)
]

df_new = spark.createDataFrame(data=new_data, schema=schema)
df_new.show()
```

Para realizar o upsert (merge), execute o seguinte:

```python
from delta.tables import DeltaTable

deltaTable = DeltaTable.forPath(spark, "/app/delta/venda_carros")

deltaTable.alias("dados_atuais").merge(
    df_new.alias("novos_dados"),
    "dados_atuais.PLACA = novos_dados.PLACA"
).whenMatchedUpdateAll().whenNotMatchedInsertAll().execute()
```

## Parte 5 — Excluindo Registros

Para excluir registros onde o valor do carro esteja abaixo de um determinado valor:

```python
deltaTable.delete("VALOR_CARRO < 50000.00")
```

## Parte 6 — Visualizando o Histórico da Tabela Delta

Você pode visualizar o histórico de transformações da sua tabela Delta da seguinte maneira:

```python
deltaTable.history().select("version", "timestamp", "operation", "operationMetrics").show()
```

## Parte 7 — Time Travel

O Delta Lake suporta o recurso de **time travel**, permitindo que você reverta para versões anteriores dos seus dados.

### Lendo uma versão anterior:

```python
spark.read.format("delta").option("versionAsOf", 1).load("/app/delta/venda_carros").show()
```

### Restaurando uma versão antiga:

```python
deltaTable.restoreToVersion(0)
```
