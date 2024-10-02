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

Crie um arquivo chamado `Dockerfile` com o seguinte conteúdo:

```Dockerfile
FROM bitnami/spark:latest

USER root

# Instalar JupyterLab
RUN pip install jupyterlab delta-spark==2.4.0

# Configurar o diretório de trabalho
WORKDIR /app

# Expor as portas necessárias
EXPOSE 8888 4040
```

### Passo 3: Construir a imagem Docker

```bash
docker build -t pyspark-delta-venda-carros .
```

### Passo 4: Rodar o contêiner Docker

```bash
docker run -p 8888:8888 -v $(pwd):/app -it pyspark-delta-venda-carros bash
```

Dentro do contêiner Docker, inicie o JupyterLab:

```bash
jupyter-lab --ip=0.0.0.0 --no-browser --allow-root
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
