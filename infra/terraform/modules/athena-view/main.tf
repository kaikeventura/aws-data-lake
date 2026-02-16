resource "aws_glue_catalog_database" "spec" {
  name = var.database_name
}

resource "aws_athena_named_query" "create_view" {
  name      = "create-${var.view_name}"
  database  = aws_glue_catalog_database.spec.name
  workgroup = "primary"
  query     = "CREATE OR REPLACE VIEW ${var.database_name}.${var.view_name} AS SELECT v.order_id, v.valor_total as valor_pago, v.status, v.show_id, v.user_id, v.ingestion_at as data_venda, v.valor_total * 0.10 as comissao_plataforma FROM ${var.silver_database}.vendas_ingressos v"
}
