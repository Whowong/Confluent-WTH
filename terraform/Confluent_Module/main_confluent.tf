
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.32.0"
    }
  }

  required_version = ">= 1.11.4"
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
    azure.blob.account.name = var.azure_blob_account_name
    azure.blob.account.key  = var.azure_blob_account_key
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
