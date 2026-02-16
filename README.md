# 🎫 AWS Data Lake - Sistema de Vendas de Ingressos

## 📋 Índice
- [Visão Geral](#-visão-geral)
- [Arquitetura](#-arquitetura)
- [Camadas do Data Lake](#-camadas-do-data-lake)
- [Fluxo de Dados](#-fluxo-de-dados)
- [Componentes AWS](#-componentes-aws)
- [Deploy](#-deploy)
- [Monitoramento](#-monitoramento)

---

## 🎯 Visão Geral

Este projeto implementa uma arquitetura completa de **Data Lake** na AWS para democratização de dados de vendas de ingressos, seguindo as melhores práticas de **Data Mesh** e arquitetura **Medallion** (Bronze → Silver → Gold → Spec).

### 🎪 Caso de Uso
Sistema de vendas de ingressos para shows que processa transações em tempo real e disponibiliza dados analíticos para times de negócio via Athena.

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CAMADA TRANSACIONAL                          │
│  DynamoDB (TicketingSystem) → DynamoDB Streams → Lambda Filter     │
└─────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      CAMADA BRONZE (SOR - Raw)                      │
│  Kinesis Firehose → S3 Bronze (JSON) → Glue Crawler → bronze_db    │
└─────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    CAMADA SILVER (SOT - Curated)                    │
│  Glue Job (Dedup + Clean) → S3 Silver (Parquet) → silver_db        │
└─────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                  CAMADA GOLD (Spec - Aggregated)                    │
│  Glue Job (Filter + Calc) → S3 Gold (Parquet) → gold_db            │
└─────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    CAMADA SPEC (Virtual Views)                      │
│              Athena Views → spec_db (Custo Zero)                    │
└─────────────────────────────────────────────────────────────────────┘
```

**[ADICIONAR PRINT: Diagrama de arquitetura completo do AWS Console]**

---

## 📊 Camadas do Data Lake

### 🥉 Camada Bronze (SOR - System of Record)

**Objetivo:** Armazenar dados brutos exatamente como chegam da fonte transacional.

#### 📦 Componentes:
- **DynamoDB Table:** `TicketingSystem`
  - PK: `USER#{uuid}` ou `SHOW#{uuid}`
  - SK: `ORDER#{uuid}` ou `TOUR#{uuid}#{year}`
  - Stream habilitado: `NEW_IMAGE`

**[ADICIONAR PRINT: Tabela DynamoDB com dados de exemplo]**

- **Lambda Filter:** `lambda-sales-filter`
  - Filtra apenas registros com `SK` começando em `ORDER#`
  - Adiciona metadados: `evento_tipo`, `ingestion_at`
  - Envia para Kinesis Firehose

**[ADICIONAR PRINT: Código da Lambda Filter no console]**

- **Kinesis Firehose:** `show-tickets-bronze-stream`
  - Buffer: 1MB ou 60 segundos
  - Formato: JSON (newline delimited)
  - Particionamento: `vendas_ingressos/year=YYYY/month=MM/day=DD/`

**[ADICIONAR PRINT: Configuração do Kinesis Firehose]**

- **S3 Bronze:** `show-tickets-lake-bronze-{id}`
  - Formato: JSON
  - Versionamento: Habilitado
  - Estrutura:
    ```
    vendas_ingressos/
    ├── year=2026/
    │   ├── month=02/
    │   │   ├── day=16/
    │   │   │   └── *.json
    ```

**[ADICIONAR PRINT: Estrutura de pastas no S3 Bronze]**

- **Glue Crawler:** `bronze-vendas-crawler`
  - Schedule: Diário às 2h UTC
  - Database: `bronze_db`
  - Tabela: `vendas_ingressos`

**[ADICIONAR PRINT: Configuração do Glue Crawler Bronze]**

#### 📋 Schema Bronze:
```json
{
  "pk": "USER#30f923d5-e4e1-4624-ac98-bb427f78f05d",
  "sk": "ORDER#693917ff-4df4-4389-814a-c6c9136b8a35",
  "details": {
    "status": "CONFIRMED",
    "amount": "190",
    "showid": "2b95692d-5dbf-4b57-8af3-713665229ea7"
  },
  "evento_tipo": "venda_ingresso",
  "ingestion_at": "2026-02-16T15:23:37.626637"
}
```

---

### 🥈 Camada Silver (SOT - Single Source of Truth)

**Objetivo:** Dados limpos, deduplicados e transformados para análise.

#### 📦 Componentes:
- **Glue Job:** `silver-transform-job`
  - Tipo: Python Shell (0.0625 DPU - econômico)
  - Schedule: Diário às 3h UTC (1h após crawler Bronze)
  - Biblioteca: `awswrangler` + `pandas`

**[ADICIONAR PRINT: Configuração do Glue Job Silver]**

#### 🔄 Transformações:
1. **Deduplicação:** Remove duplicatas por `order_id`, mantendo registro mais recente
2. **Limpeza:**
   - Remove prefixos: `ORDER#`, `USER#`
   - Extrai campos do JSON `details`: `valor_total`, `status`, `show_id`
   - Converte tipos: `valor_total` → float, `ingestion_at` → datetime
3. **Particionamento:** `year`, `month`, `day` (baseado em `ingestion_at`)

**[ADICIONAR PRINT: Logs do Glue Job mostrando transformações]**

- **S3 Silver:** `show-tickets-lake-silver-{id}`
  - Formato: Parquet
  - Compressão: Snappy
  - Estrutura:
    ```
    vendas_ingressos/
    ├── year=2026/
    │   ├── month=2/
    │   │   ├── day=16/
    │   │   │   └── *.snappy.parquet
    ```

**[ADICIONAR PRINT: Estrutura de pastas no S3 Silver]**

- **Glue Crawler:** `silver-vendas-crawler`
  - Schedule: Diário às 2h UTC
  - Database: `silver_db`
  - Tabela: `vendas_ingressos`

**[ADICIONAR PRINT: Tabela Silver no Glue Catalog]**

#### 📋 Schema Silver:
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `order_id` | string | ID único da venda |
| `user_id` | string | ID do usuário (sem prefixo) |
| `valor_total` | double | Valor da venda |
| `status` | string | CONFIRMED, PENDING, CANCELLED |
| `show_id` | string | ID do show |
| `ingestion_at` | timestamp | Data/hora da ingestão |
| `year` | int | Partição: Ano |
| `month` | int | Partição: Mês |
| `day` | int | Partição: Dia |

---

### 🥇 Camada Gold (Spec - Materializada)

**Objetivo:** Dados agregados e otimizados para consumo por dashboards e BI.

#### 📦 Componentes:
- **Glue Job:** `gold-transform-job`
  - Tipo: Python Shell (0.0625 DPU)
  - Schedule: Diário às 4h UTC (após Silver)
  - Biblioteca: `awswrangler` + `pandas`

**[ADICIONAR PRINT: Configuração do Glue Job Gold]**

#### 🔄 Transformações:
1. **Filtro:** Apenas vendas com `status = 'CONFIRMED'`
2. **Cálculos:**
   - `comissao_plataforma`: 10% do `valor_total`
   - `nome_do_show`: Concatenação `'Show-' + show_id`
3. **Particionamento:** `year`, `month`, `day` (data da venda confirmada)
4. **MSCK REPAIR:** Atualiza partições automaticamente no Athena

**[ADICIONAR PRINT: Query Athena mostrando dados Gold]**

- **S3 Gold:** `show-tickets-lake-gold-{id}`
  - Formato: Parquet
  - Compressão: Snappy
  - Estrutura:
    ```
    vendas_confirmadas/
    ├── year=2026/
    │   ├── month=2/
    │   │   ├── day=16/
    │   │   │   └── *.snappy.parquet
    ```

**[ADICIONAR PRINT: Estrutura de pastas no S3 Gold]**

- **Glue Crawler:** `gold-vendas-crawler`
  - Schedule: Diário às 2h UTC
  - Database: `gold_db`
  - Tabela: `vendas_confirmadas`

**[ADICIONAR PRINT: Tabela Gold no Glue Catalog]**

#### 📋 Schema Gold:
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `order_id` | string | ID único da venda |
| `valor_pago` | double | Valor pago pelo cliente |
| `status` | string | Sempre CONFIRMED |
| `show_id` | string | ID do show |
| `user_id` | string | ID do usuário |
| `data_venda` | timestamp | Data/hora da venda |
| `comissao_plataforma` | double | 10% do valor |
| `nome_do_show` | string | Nome amigável do show |
| `year` | int | Partição: Ano |
| `month` | int | Partição: Mês |
| `day` | int | Partição: Dia |

---

### 🌟 Camada Spec (Virtual - Custo Zero)

**Objetivo:** Views virtuais no Athena para acesso direto pelos times de negócio.

#### 📦 Componentes:
- **Athena Named Query:** `create-vw_vendas_consolidadas_gold`
  - Database: `spec_db`
  - View: `vw_vendas_consolidadas_gold`
  - Custo: Zero armazenamento (apenas query)

**[ADICIONAR PRINT: View no Athena Query Editor]**

#### 📋 SQL da View:
```sql
CREATE OR REPLACE VIEW spec_db.vw_vendas_consolidadas_gold AS 
SELECT 
  v.order_id, 
  v.valor_total as valor_pago, 
  v.status, 
  v.show_id,
  v.user_id,
  v.ingestion_at as data_venda,
  v.valor_total * 0.10 as comissao_plataforma 
FROM silver_db.vendas_ingressos v
```

**[ADICIONAR PRINT: Resultado da query na view Spec]**

---

## 🔄 Fluxo de Dados

### ⏱️ Timeline Diária:

```
00:00 UTC - Lambda Populator gera dados de teste
          ↓
Real-time - DynamoDB Stream → Lambda Filter → Firehose → S3 Bronze
          ↓
02:00 UTC - Crawlers (Bronze, Silver, Gold) catalogam dados
          ↓
03:00 UTC - Glue Job Silver: Bronze → Silver (dedup + clean)
          ↓
04:00 UTC - Glue Job Gold: Silver → Gold (filter + calc)
          ↓
24/7      - Athena Views disponíveis para consulta
```

### 📈 Latência por Camada:

| Camada | Latência | Atualização |
|--------|----------|-------------|
| Bronze | ~1-2 min | Real-time (Firehose buffer) |
| Silver | ~1 hora | Diária às 3h UTC |
| Gold | ~2 horas | Diária às 4h UTC |
| Spec | Instantânea | Query on-demand |

**[ADICIONAR PRINT: CloudWatch Metrics mostrando latências]**

---

## 🛠️ Componentes AWS

### 💾 Armazenamento:
- **DynamoDB:** Banco transacional NoSQL
- **S3:** Data Lake (Bronze, Silver, Gold)
  - Bronze: `show-tickets-lake-bronze-{id}`
  - Silver: `show-tickets-lake-silver-{id}`
  - Gold: `show-tickets-lake-gold-{id}`

**[ADICIONAR PRINT: Lista de buckets S3]**

### ⚡ Processamento:
- **Lambda Functions:**
  - `lambda-data-populator`: Gera dados de teste
  - `lambda-sales-filter`: Filtra eventos do Stream
- **Kinesis Firehose:** Ingestão em tempo real
- **Glue Jobs:**
  - `silver-transform-job`: Transformação Bronze → Silver
  - `gold-transform-job`: Transformação Silver → Gold

**[ADICIONAR PRINT: Lista de Glue Jobs]**

### 📚 Catálogo:
- **Glue Data Catalog:**
  - `bronze_db`: Dados brutos (JSON)
  - `silver_db`: Dados limpos (Parquet)
  - `gold_db`: Dados agregados (Parquet)
  - `spec_db`: Views virtuais

**[ADICIONAR PRINT: Databases no Glue Catalog]**

- **Glue Crawlers:**
  - `bronze-vendas-crawler`
  - `silver-vendas-crawler`
  - `gold-vendas-crawler`

**[ADICIONAR PRINT: Lista de Crawlers]**

### 🔍 Consulta:
- **Amazon Athena:** Query engine SQL serverless
  - Workgroup: `primary`
  - Resultados: Armazenados em cada bucket

**[ADICIONAR PRINT: Athena Query Editor com exemplo de consulta]**

---

## 🚀 Deploy

### 📋 Pré-requisitos:
- AWS CLI configurado
- Terraform >= 1.6.0
- Python 3.9+
- Conta AWS com permissões adequadas

### 🔧 Passo a Passo:

#### 1️⃣ Clone o Repositório:
```bash
git clone <repo-url>
cd aws-data-lake
```

#### 2️⃣ Configure o Backend (Bootstrap):
```bash
cd infra/terraform/bootstrap
terraform init
terraform apply
```

**[ADICIONAR PRINT: Output do terraform apply do bootstrap]**

#### 3️⃣ Deploy da Infraestrutura:
```bash
cd ../envs/dev
terraform init
terraform apply
```

**[ADICIONAR PRINT: Output do terraform apply completo]**

#### 4️⃣ Crie a View Spec (Manual):
No console do Athena, execute:
```sql
CREATE OR REPLACE VIEW spec_db.vw_vendas_consolidadas_gold AS 
SELECT 
  v.order_id, 
  v.valor_total as valor_pago, 
  v.status, 
  v.show_id,
  v.user_id,
  v.ingestion_at as data_venda,
  v.valor_total * 0.10 as comissao_plataforma 
FROM silver_db.vendas_ingressos v
```

**[ADICIONAR PRINT: Execução da query de criação da view]**

#### 5️⃣ Teste o Pipeline:
```bash
# Invocar Lambda Populator para gerar dados
aws lambda invoke \
  --function-name lambda-data-populator \
  --region us-east-1 \
  /tmp/response.json
```

**[ADICIONAR PRINT: Response da invocação da Lambda]**

---

## 📊 Monitoramento

### 🔍 CloudWatch Logs:

#### Lambda Filter:
```
/aws/lambda/lambda-sales-filter
```
**[ADICIONAR PRINT: Logs da Lambda Filter]**

#### Glue Jobs:
```
/aws-glue/jobs/output
/aws-glue/jobs/error
```
**[ADICIONAR PRINT: Logs do Glue Job Silver]**

### 📈 Métricas Importantes:

| Métrica | Componente | Alerta |
|---------|------------|--------|
| `IncomingRecords` | Kinesis Firehose | < 1 por 5 min |
| `Duration` | Lambda Filter | > 30s |
| `Errors` | Glue Jobs | > 0 |
| `DataScanned` | Athena | > 10GB/dia |

**[ADICIONAR PRINT: Dashboard CloudWatch com métricas]**

### 🔔 Alarmes Recomendados:
1. **Firehose Delivery Failures:** > 0
2. **Lambda Errors:** > 5 em 5 minutos
3. **Glue Job Failures:** > 0
4. **S3 Bucket Size:** > 100GB (revisar retenção)

**[ADICIONAR PRINT: Configuração de alarmes CloudWatch]**

---

## 💰 Custos Estimados

### 📊 Breakdown Mensal (1M eventos):

| Serviço | Custo Estimado | Observação |
|---------|----------------|------------|
| DynamoDB | $5-10 | On-demand pricing |
| Lambda | $1-2 | 1M invocações |
| Kinesis Firehose | $10-15 | Ingestão + transformação |
| S3 | $5-20 | Depende da retenção |
| Glue Crawlers | $1-2 | 3 crawlers diários |
| Glue Jobs | $2-3 | Python Shell (0.0625 DPU) |
| Athena | $5-10 | Depende das queries |
| **TOTAL** | **$29-62/mês** | Altamente escalável |

**[ADICIONAR PRINT: AWS Cost Explorer com breakdown]**

### 💡 Dicas de Otimização:
- ✅ Use particionamento para reduzir scan do Athena
- ✅ Parquet + Snappy reduz custos de armazenamento em ~80%
- ✅ Python Shell Jobs são 10x mais baratos que Spark
- ✅ Views virtuais (Spec) não custam armazenamento
- ✅ Configure lifecycle policies no S3 para dados antigos

---

## 🎓 Conceitos Aplicados

### 🏛️ Arquitetura Medallion:
- **Bronze (Raw):** Dados brutos, imutáveis
- **Silver (Curated):** Dados limpos, confiáveis
- **Gold (Aggregated):** Dados prontos para negócio
- **Spec (Virtual):** Camada de acesso democratizado

### 🌐 Data Mesh:
- **Domain-Oriented:** Cada camada é um domínio
- **Self-Serve:** Infraestrutura como código (Terraform)
- **Product Thinking:** Dados como produto para consumo
- **Federated Governance:** Glue Catalog centralizado

### 🔄 CDC (Change Data Capture):
- DynamoDB Streams captura mudanças em tempo real
- Lambda processa apenas eventos relevantes (ORDER#)
- Deduplicação na Silver garante consistência

---

## 📚 Referências

- [AWS Data Lake Best Practices](https://aws.amazon.com/big-data/datalakes-and-analytics/)
- [Medallion Architecture](https://www.databricks.com/glossary/medallion-architecture)
- [Data Mesh Principles](https://martinfowler.com/articles/data-mesh-principles.html)
- [AWS Glue Documentation](https://docs.aws.amazon.com/glue/)
- [Amazon Athena Best Practices](https://docs.aws.amazon.com/athena/latest/ug/performance-tuning.html)

---

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch: `git checkout -b feature/nova-camada`
3. Commit: `git commit -m 'feat: adiciona camada platinum'`
4. Push: `git push origin feature/nova-camada`
5. Abra um Pull Request

---

## 📝 Licença

Este projeto está sob a licença MIT.

---

## 👥 Autores

Desenvolvido com ❤️ para democratização de dados na AWS.

**[ADICIONAR PRINT: Arquitetura final completa com todas as camadas]**

---

## 🆘 Troubleshooting

### ❌ Problema: View não aparece no Athena
**Solução:** Execute manualmente a saved query `create-vw_vendas_consolidadas_gold`

### ❌ Problema: Glue Job falha com "Access Denied"
**Solução:** Verifique IAM roles e permissões S3

### ❌ Problema: Partições não aparecem
**Solução:** Execute `MSCK REPAIR TABLE` ou aguarde o crawler

### ❌ Problema: Dados duplicados na Silver
**Solução:** Verifique lógica de deduplicação por `order_id` + `ingestion_at`

**[ADICIONAR PRINT: Exemplo de erro e solução no CloudWatch]**

---

🎉 **Parabéns! Você tem um Data Lake completo rodando na AWS!** 🎉
