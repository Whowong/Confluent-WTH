
terraform {
  required_version = ">= 1.11.4"
}


provider "confluent" {
  kafka_id            = var.kafka_id                   # optionally use KAFKA_ID env var
  kafka_rest_endpoint = var.kafka_rest_endpoint        # optionally use KAFKA_REST_ENDPOINT env var
  kafka_api_key       = var.kafka_api_key              # optionally use KAFKA_API_KEY env var
  kafka_api_secret    = var.kafka_api_secret           # optionally use KAFKA_API_SECRET env var

  flink_api_key       = var.flink_api_key              # optionally use FLINK_API_KEY env var
  flink_api_secret    = var.flink_api_secret           # optionally use FLINK_API_SECRET env var
  flink_rest_endpoint = var.flink_rest_endpoint        # optionally use FLINK_REST_ENDPOINT env var
  flink_compute_pool_id = var.flink_compute_pool_id    # optionally use FLINK_COMPUTE_POOL_ID env var
  flink_principal_id  = var.flink_principal_id         # optionally use FLINK_PRINCIPAL_ID 
  organization_id   = var.confluent_organization_id    # optionally use ORGANIZATION_ID env var
  environment_id   = var.confluent_environment_id      # optionally use ENVIRONMENT_ID env var

  schema_registry_id = var.schema_registry_id                       # optionally use SCHEMA_REGISTRY_ID env var
  schema_registry_rest_endpoint = var.schema_registry_rest_endpoint # optionally use SCHEMA_REGISTRY_REST_ENDPOINT env var
  schema_registry_api_key = var.schema_registry_api_key             # optionally use SCHEMA_REGISTRY_API_KEY env var
  schema_registry_api_secret = var.schema_registry_api_secret       # optionally use SCHEMA_REGISTRY_API_SECRET env var
}

