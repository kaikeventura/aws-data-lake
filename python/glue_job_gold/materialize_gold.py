import awswrangler as wr
import pandas as pd
import sys

args = {}
for i in range(1, len(sys.argv), 2):
    key = sys.argv[i].replace('--', '')
    args[key] = sys.argv[i + 1]

silver_database = args['silver_database']
output_path = args['output_path']
athena_output = args['athena_output']
gold_database = args['gold_database']

query = f"""
SELECT 
    order_id,
    valor_total as valor_pago,
    status,
    show_id,
    user_id,
    ingestion_at as data_venda,
    valor_total * 0.10 as comissao_plataforma,
    'Show-' || show_id as nome_do_show
FROM "{silver_database}"."vendas_ingressos"
WHERE status = 'CONFIRMED'
"""

df = wr.athena.read_sql_query(
    query,
    database=silver_database,
    s3_output=athena_output
)

df['data_venda'] = pd.to_datetime(df['data_venda'])
df['year'] = df['data_venda'].dt.year
df['month'] = df['data_venda'].dt.month
df['day'] = df['data_venda'].dt.day

wr.s3.to_parquet(
    df=df,
    path=output_path,
    dataset=True,
    mode='overwrite',
    compression='snappy',
    partition_cols=['year', 'month', 'day'],
    database=gold_database,
    table='vendas_confirmadas'
)

wr.athena.repair_table(
    table='vendas_confirmadas',
    database=gold_database,
    s3_output=athena_output
)
