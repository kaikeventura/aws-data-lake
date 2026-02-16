# 🎫 Arquitetura Data Lake - Diagrama Mermaid

## Diagrama Completo

```mermaid
graph TB
    subgraph TRANSACIONAL["🔵 TRANSACIONAL"]
        DDB[(DynamoDB<br/>TicketingSystem)]
        Stream[DynamoDB Stream]
        PopLambda[Lambda<br/>data-populator]
        
        PopLambda -->|INSERT| DDB
        DDB -->|NEW_IMAGE| Stream
    end
    
    subgraph BRONZE["🟤 BRONZE / SOR"]
        FilterLambda[Lambda<br/>sales-filter]
        Firehose[Kinesis Firehose<br/>bronze-stream]
        S3Bronze[(S3 Bronze<br/>JSON)]
        CrawlerBronze[Glue Crawler<br/>bronze-vendas]
        DBBronze[(Glue DB<br/>bronze_db)]
        
        Stream -->|Trigger| FilterLambda
        FilterLambda -->|put_record| Firehose
        Firehose -->|Partition by date| S3Bronze
        S3Bronze -->|Scan| CrawlerBronze
        CrawlerBronze -->|Catalog| DBBronze
    end
    
    subgraph SILVER["⚪ SILVER / SOT"]
        JobSilver[Glue Job<br/>silver-transform]
        S3Silver[(S3 Silver<br/>Parquet)]
        CrawlerSilver[Glue Crawler<br/>silver-vendas]
        DBSilver[(Glue DB<br/>silver_db)]
        
        DBBronze -->|Read| JobSilver
        JobSilver -->|Dedup + Clean| S3Silver
        S3Silver -->|Scan| CrawlerSilver
        CrawlerSilver -->|Catalog| DBSilver
    end
    
    subgraph GOLD["🟡 GOLD / SPEC"]
        JobGold[Glue Job<br/>gold-transform]
        S3Gold[(S3 Gold<br/>Parquet)]
        CrawlerGold[Glue Crawler<br/>gold-vendas]
        DBGold[(Glue DB<br/>gold_db)]
        
        DBSilver -->|Read| JobGold
        JobGold -->|Filter + Calc| S3Gold
        S3Gold -->|Scan| CrawlerGold
        CrawlerGold -->|Catalog| DBGold
    end
    
    subgraph SPEC["🌟 SPEC / VIRTUAL"]
        DBSpec[(Glue DB<br/>spec_db)]
        AthenaView[Athena View<br/>vw_vendas_consolidadas]
        Athena[Amazon Athena<br/>Query Engine]
        
        DBSilver -.->|Virtual JOIN| AthenaView
        AthenaView -->|Registered in| DBSpec
        DBSpec -->|Query| Athena
    end
    
    subgraph SCHEDULE["⏰ SCHEDULES"]
        Cron2h[02:00 UTC<br/>Crawlers]
        Cron3h[03:00 UTC<br/>Silver Job]
        Cron4h[04:00 UTC<br/>Gold Job]
        
        Cron2h -.->|Trigger| CrawlerBronze
        Cron2h -.->|Trigger| CrawlerSilver
        Cron2h -.->|Trigger| CrawlerGold
        Cron3h -.->|Trigger| JobSilver
        Cron4h -.->|Trigger| JobGold
    end
    
    Users[👥 Business Users] -->|SQL Queries| Athena
    
    style TRANSACIONAL fill:#1e3a8a,stroke:#3b82f6,stroke-width:2px,color:#fff
    style BRONZE fill:#78350f,stroke:#f59e0b,stroke-width:2px,color:#fff
    style SILVER fill:#374151,stroke:#9ca3af,stroke-width:2px,color:#fff
    style GOLD fill:#713f12,stroke:#fbbf24,stroke-width:2px,color:#fff
    style SPEC fill:#14532d,stroke:#22c55e,stroke-width:2px,color:#fff
    style SCHEDULE fill:#831843,stroke:#ec4899,stroke-width:2px,color:#fff
```

## Fluxo de Dados Detalhado

```mermaid
sequenceDiagram
    participant User as 👤 User
    participant DDB as DynamoDB
    participant Stream as DDB Stream
    participant Lambda as Lambda Filter
    participant Firehose as Kinesis Firehose
    participant S3B as S3 Bronze
    participant CrawlerB as Crawler Bronze
    participant JobS as Glue Job Silver
    participant S3S as S3 Silver
    participant CrawlerS as Crawler Silver
    participant JobG as Glue Job Gold
    participant S3G as S3 Gold
    participant Athena as Athena

    User->>DDB: INSERT ORDER
    DDB->>Stream: Capture Change
    Stream->>Lambda: Trigger Event
    Lambda->>Lambda: Filter ORDER#
    Lambda->>Firehose: put_record
    Firehose->>S3B: Store JSON (partitioned)
    
    Note over CrawlerB: Daily 02:00 UTC
    CrawlerB->>S3B: Scan files
    CrawlerB->>CrawlerB: Create bronze_db.vendas_ingressos
    
    Note over JobS: Daily 03:00 UTC
    JobS->>S3B: Read via Athena
    JobS->>JobS: Dedup + Clean + Transform
    JobS->>S3S: Write Parquet
    
    Note over CrawlerS: Daily 02:00 UTC
    CrawlerS->>S3S: Scan files
    CrawlerS->>CrawlerS: Create silver_db.vendas_ingressos
    
    Note over JobG: Daily 04:00 UTC
    JobG->>S3S: Read via Athena
    JobG->>JobG: Filter CONFIRMED + Calc
    JobG->>S3G: Write Parquet
    JobG->>JobG: MSCK REPAIR TABLE
    
    User->>Athena: SELECT * FROM spec_db.vw_vendas
    Athena->>S3S: Query Silver data
    Athena->>User: Return results
```

## Arquitetura Medallion

```mermaid
graph LR
    subgraph Bronze["🟤 BRONZE - SOR"]
        B1[Raw Data<br/>JSON<br/>Immutable]
    end
    
    subgraph Silver["⚪ SILVER - SOT"]
        S1[Curated Data<br/>Parquet<br/>Deduplicated]
    end
    
    subgraph Gold["🟡 GOLD - Spec"]
        G1[Aggregated Data<br/>Parquet<br/>Business Ready]
    end
    
    subgraph Spec["🌟 SPEC - Virtual"]
        SP1[Virtual Views<br/>Zero Storage<br/>On-Demand]
    end
    
    Bronze -->|Clean + Transform| Silver
    Silver -->|Filter + Calculate| Gold
    Silver -.->|Virtual JOIN| Spec
    
    style Bronze fill:#78350f,stroke:#f59e0b,stroke-width:2px,color:#fff
    style Silver fill:#374151,stroke:#9ca3af,stroke-width:2px,color:#fff
    style Gold fill:#713f12,stroke:#fbbf24,stroke-width:2px,color:#fff
    style Spec fill:#14532d,stroke:#22c55e,stroke-width:2px,color:#fff
```

## Componentes por Camada

```mermaid
mindmap
  root((Data Lake))
    Transacional
      DynamoDB Table
      DynamoDB Stream
      Lambda Populator
    Bronze SOR
      Lambda Filter
      Kinesis Firehose
      S3 Bronze JSON
      Glue Crawler
      bronze_db
    Silver SOT
      Glue Job Python Shell
      S3 Silver Parquet
      Glue Crawler
      silver_db
    Gold Aggregated
      Glue Job Python Shell
      S3 Gold Parquet
      Glue Crawler
      gold_db
    Spec Virtual
      Athena Views
      spec_db
      Zero Storage Cost
```

## Timeline Diária

```mermaid
gantt
    title 📅 Pipeline Diário de Processamento
    dateFormat HH:mm
    axisFormat %H:%M
    
    section Real-time
    DynamoDB Stream → Lambda → Firehose → S3 Bronze :active, rt1, 00:00, 24h
    
    section Catalogação
    Crawlers (Bronze, Silver, Gold) :crit, c1, 02:00, 30m
    
    section Transformação
    Glue Job Silver (Bronze → Silver) :done, s1, 03:00, 1h
    Glue Job Gold (Silver → Gold) :done, g1, 04:00, 1h
    
    section Consulta
    Athena Views disponíveis 24/7 :active, a1, 00:00, 24h
```

## Custos por Serviço

```mermaid
pie title 💰 Estimativa de Custos Mensais (1M eventos)
    "DynamoDB" : 10
    "Lambda" : 2
    "Kinesis Firehose" : 15
    "S3 Storage" : 20
    "Glue Crawlers" : 2
    "Glue Jobs" : 3
    "Athena Queries" : 10
```

---

## Como Visualizar

### No GitHub/GitLab
Os diagramas Mermaid são renderizados automaticamente em arquivos `.md`

### No VS Code
Instale a extensão: **Markdown Preview Mermaid Support**

### Online
Cole o código em: https://mermaid.live/

### Exportar PNG
```bash
# Instale mermaid-cli
npm install -g @mermaid-js/mermaid-cli

# Gere PNG
mmdc -i ARCHITECTURE.md -o architecture.png
```
