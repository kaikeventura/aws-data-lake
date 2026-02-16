import awswrangler as wr
import pandas as pd
import sys
from datetime import datetime

args = {}
for i in range(1, len(sys.argv), 2):
    key = sys.argv[i].replace('--', '')
    args[key] = sys.argv[i + 1]

database = args['database']
table = args['table']
output_path = args['output_path']
athena_output = args['athena_output']

query = f'SELECT * FROM "{database}"."{table}"'

df = wr.athena.read_sql_query(
    query, 
    database=database,
    s3_output=athena_output
)

df['order_id'] = df['sk'].str.replace('ORDER#', '')
df['ingestion_at'] = pd.to_datetime(df['ingestion_at'])

df = df.sort_values('ingestion_at').drop_duplicates(subset=['order_id'], keep='last')

df = df.rename(columns={
    'pk': 'user_id',
    'sk': 'order_key'
})

if 'details' in df.columns:
    df['valor_total'] = pd.to_numeric(df['details'].str.extract(r'"Amount":\s*"([^"]+)"')[0], errors='coerce')
    df['status'] = df['details'].str.extract(r'"Status":\s*"([^"]+)"')[0]
    df['show_id'] = df['details'].str.extract(r'"ShowID":\s*"([^"]+)"')[0]
    df = df.drop(columns=['details'])

df = df.drop(columns=['evento_tipo'], errors='ignore')

df['ano_venda'] = df['ingestion_at'].dt.year
df['mes_venda'] = df['ingestion_at'].dt.month

wr.s3.to_parquet(
    df=df,
    path=output_path,
    dataset=True,
    mode='overwrite',
    compression='snappy',
    partition_cols=['ano_venda', 'mes_venda']
)
