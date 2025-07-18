
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.32.0"
    }
  }

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


# Define a list of Kafka topic names
locals {
  kafka_topic_names = [
    "departments",
    "product_pricing",
    "product_skus",
    "purchases",
    "replenishments",
    "returns",
    "net_sales",
    "product_inventory" 
  ]
}

# Create the Retail Store Kafka Topics
resource "confluent_kafka_topic" "topics" {
  for_each            = toset(local.kafka_topic_names)
  topic_name          = each.value
  partitions_count    = var.kafka_partitions_count

  lifecycle {
    prevent_destroy = false
  } 
}

# Create the Schema Registry Entries for each Topic Key 
resource "confluent_schema" "key_schemas" {
  for_each            = toset(local.kafka_topic_names)
  subject_name        = "${each.value}-key"
  format              = "JSON"
  schema              = file("../retail_store/${each.value}/schemas/${each.value}-key.json")
  hard_delete         = true # Optional: Set to true if you want to hard delete the schema
}

# Create the Schema Registry Entries for each Topic Value 
resource "confluent_schema" "value_schemas" {
  for_each            = toset(local.kafka_topic_names)
  subject_name        = "${each.value}-value"
  format              = "JSON"
  schema              = file("../retail_store/${each.value}/schemas/${each.value}-value.json")
  hard_delete         = true # Optional: Set to true if you want to hard delete the schema
}

# Create the Source Connectors for Azure Blob Storage
resource "confluent_kafka_connector" "blob_store_connectors" {
  for_each = var.blob_store_connectors

  environment {
    id = var.confluent_environment_id
  }

  kafka_cluster {
    id = var.kafka_id
  }

  config_sensitive {
    "azure.blob.account.name" = var.azure_blob_account_name
    "azure.blob.account.key"  = var.azure_blob_account_key
  }

  config_non_sensitive {
    name            = each.value.name
    connector.class = "io.confluent.connect.azure.blob.AzureBlobStorageSourceConnector"
    tasks.max       = "1"
    topics         = each.value.topic
    azure.blob.container = each.value.container
  }

  depends_on = [
        confluent_kafka_topic.topics,
        confluent_schema.key_schemas,
        confluent_schema.value_schemas
]

lifecycle {
    prevent_destroy = false
  }
}
