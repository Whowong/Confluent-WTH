
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
  kafka_id                      = var.kafka_cluster_id
  kafka_rest_endpoint           = var.kafka_rest_endpoint
  kafka_api_key                 = var.kafka_api_key
  kafka_api_secret              = var.kafka_api_secret

  flink_api_key                 = var.flink_api_key
  flink_api_secret              = var.flink_api_secret
  flink_rest_endpoint           = var.flink_rest_endpoint
  flink_compute_pool_id         = var.flink_compute_pool_id
  flink_principal_id            = var.flink_principal_id
  organization_id               = var.confluent_organization_id
  environment_id                = var.confluent_environment_id

  schema_registry_id            = var.schema_registry_id
  schema_registry_rest_endpoint = var.schema_registry_rest_endpoint
  schema_registry_api_key       = var.schema_registry_api_key
  schema_registry_api_secret    = var.schema_registry_api_secret
  
  cloud_api_key                 = var.cloud_api_key
  cloud_api_secret              = var.cloud_api_secret
}


variable "kafka_partitions_count" {
  description = "Number of Partitions in Kafka Cluster"
  type        = number
  default     = 6
}

# Confluent Cloud Configuration Variables
variable "kafka_cluster_id" {
  description = "Kafka Cluster ID"
  type        = string
}

variable "kafka_rest_endpoint" {
  description = "Kafka REST Endpoint URL"
  type        = string
}

variable "kafka_api_key" {
  description = "Kafka API Key"
  type        = string
}

variable "kafka_api_secret" {
  description = "Kafka API Secret"
  type        = string
  sensitive   = true
}

variable "flink_api_key" {
  description = "Flink API Key"
  type        = string
}

variable "flink_api_secret" {
  description = "Flink API Secret"
  type        = string
  sensitive   = true
}

variable "flink_rest_endpoint" {
  description = "Flink REST Endpoint URL"
  type        = string
}

variable "flink_compute_pool_id" {
  description = "Flink Compute Pool ID"
  type        = string
}

variable "flink_principal_id" {
  description = "Flink Principal ID"
  type        = string
}

variable "confluent_organization_id" {
  description = "Confluent Organization ID"
  type        = string
}

variable "confluent_environment_id" {
  description = "Confluent Environment ID"
  type        = string
}

variable "schema_registry_id" {
  description = "Schema Registry ID"
  type        = string
}

variable "schema_registry_rest_endpoint" {
  description = "Schema Registry REST Endpoint URL"
  type        = string
}

variable "schema_registry_api_key" {
  description = "Schema Registry API Key"
  type        = string
}

variable "schema_registry_api_secret" {
  description = "Schema Registry API Secret"
  type        = string
  sensitive   = true
}

variable "cloud_api_key" {
  description = "Confluent Cloud API Key"
  type        = string
}

variable "cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

# Azure Blob Storage Configuration
variable "azure_blob_account_name" {
  description = "Azure Blob Storage Account Name"
  type        = string
}

variable "azure_blob_account_key" {
  description = "Azure Blob Storage Account Key"
  type        = string
  sensitive   = true
}

variable "azure_blob_container_name" {
  description = "Azure Blob Storage Container Name"
  type        = string
}

variable "kafka_service_account_id" {
  description = "Kafka Service Account ID for connector authentication"
  type        = string
}

variable "blob_store_connectors" {
  description = "Map of blob store connectors configuration"
  type = map(object({
    connector_name = string
    topic_name     = string
    container_name = string
  }))
}

# Azure Cosmos DB Configuration
variable "cosmos_db_account_endpoint" {
  description = "Azure Cosmos DB Account Endpoint URL"
  type        = string
}

variable "cosmos_db_master_key" {
  description = "Azure Cosmos DB Master Key"
  type        = string
  sensitive   = true
}

variable "cosmos_db_database_name" {
  description = "Azure Cosmos DB Database Name"
  type        = string
}

variable "cosmos_db_connectors" {
  description = "Map of Cosmos DB sink connectors configuration"
  type = map(object({
    connector_name    = string
    topic_name        = string
    container_mapping = string
  }))
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
  subject_name        = "${each.value}-key-terraform"
  format              = "JSON"
  schema              = file("../retail_store/${each.value}/schemas/${each.value}-key.json")
  hard_delete         = true # Optional: Set to true if you want to hard delete the schema
}

# Create the Schema Registry Entries for each Topic Value 
resource "confluent_schema" "value_schemas" {
  for_each            = toset(local.kafka_topic_names)
  subject_name        = "${each.value}-value-terraform"
  format              = "JSON"
  schema              = file("../retail_store/${each.value}/schemas/${each.value}-value.json")
  hard_delete         = true # Optional: Set to true if you want to hard delete the schema
}

# Create the Source Connectors for Azure Blob Storage - WORKING CONFIGURATION
resource "confluent_connector" "blob_store_connectors" {
  for_each = var.blob_store_connectors
  
  environment {
    id = var.confluent_environment_id
  }

  kafka_cluster {
    id = var.kafka_cluster_id
  }

  config_sensitive = {
    "azblob.account.key"  = var.azure_blob_account_key
  }

  config_nonsensitive = {
    "name"                                           = each.value.connector_name
    "connector.class"                                = "AzureBlobSource"
    "topic.regex.list"                               = "${each.value.topic_name}:.*"
    "schema.context.name"                            = "default"
    "kafka.auth.mode"                                = "SERVICE_ACCOUNT"
    "kafka.service.account.id"                       = var.kafka_service_account_id
    "azblob.account.name"                            = var.azure_blob_account_name
    "azblob.container.name"                          = var.azure_blob_container_name
    "azblob.retry.type"                              = "EXPONENTIAL"
    "input.data.format"                              = "JSON"
    "output.data.format"                             = "JSON"
    "topics.dir"                                     = "topics"
    "directory.delim"                                = "/"
    "behavior.on.error"                              = "FAIL"
    "format.bytearray.separator"                     = "\n"
    "task.batch.size"                                = "10"
    "file.discovery.starting.timestamp"              = "0"
    "azblob.poll.interval.ms"                        = "60000"
    "record.batch.max.size"                          = "200"
    "tasks.max"                                      = "1"
    "value.converter.decimal.format"                 = "BASE64"
    "value.converter.replace.null.with.default"     = "true"
    "value.converter.reference.subject.name.strategy" = "DefaultReferenceSubjectNameStrategy"
    "value.converter.schemas.enable"                 = "false"
    "errors.tolerance"                               = "none"
    "value.converter.value.subject.name.strategy"    = "TopicNameStrategy"
    "key.converter.key.subject.name.strategy"        = "TopicNameStrategy"
    "value.converter.ignore.default.for.nullables"  = "false"
    "auto.restart.on.user.error"                     = "true"
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

# Create Cosmos DB Sink Connectors
resource "confluent_connector" "cosmos_db_connectors" {
  for_each = var.cosmos_db_connectors
  
  environment {
    id = var.confluent_environment_id
  }

  kafka_cluster {
    id = var.kafka_cluster_id
  }

  config_sensitive = {
    "connect.cosmos.master.key" = var.cosmos_db_master_key
  }

  config_nonsensitive = {
    "name"                                           = each.value.connector_name
    "connector.class"                                = "CosmosDbSink"
    "schema.context.name"                            = "default"
    "input.data.format"                              = "JSON"
    "kafka.auth.mode"                                = "SERVICE_ACCOUNT"
    "kafka.service.account.id"                       = var.kafka_service_account_id
    "topics"                                         = each.value.topic_name
    "connect.cosmos.connection.endpoint"             = var.cosmos_db_account_endpoint
    "connect.cosmos.databasename"                    = var.cosmos_db_database_name
    "connect.cosmos.containers.topicmap"             = each.value.container_mapping
    "cosmos.id.strategy"                             = "FullKeyStrategy"
    "max.poll.interval.ms"                           = "300000"
    "max.poll.records"                               = "500"
    "tasks.max"                                      = "1"
    "auto.restart.on.user.error"                     = "true"
    "value.converter.decimal.format"                 = "BASE64"
    "value.converter.reference.subject.name.strategy" = "DefaultReferenceSubjectNameStrategy"
    "value.converter.value.subject.name.strategy"    = "TopicNameStrategy"
    "key.converter.key.subject.name.strategy"        = "TopicNameStrategy"
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
