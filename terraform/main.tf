
terraform {
  required_version = ">= 1.11.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.35.0"
    }
  }
}

# ------------------
# Root Variables
# ------------------
variable "name_prefix" { type = string }
variable "azure_location" {
  type    = string
  default = "westus2"
}

variable "azure_subscription_id" { type = string }

# Confluent variables (passed through to module)
variable "kafka_cluster_id" { type = string }
variable "kafka_rest_endpoint" { type = string }
variable "kafka_api_key" { type = string }
variable "kafka_api_secret" { type = string }
variable "flink_api_key" { type = string }
variable "flink_api_secret" { type = string }
variable "flink_rest_endpoint" { type = string }
variable "flink_compute_pool_id" { type = string }
variable "flink_principal_id" { type = string }
variable "confluent_organization_id" { type = string }
variable "confluent_environment_id" { type = string }
variable "schema_registry_id" { type = string }
variable "schema_registry_rest_endpoint" { type = string }
variable "schema_registry_api_key" { type = string }
variable "schema_registry_api_secret" { type = string }
variable "cloud_api_key" { type = string }
variable "cloud_api_secret" { type = string }
variable "kafka_partitions_count" {
  type    = number
  default = 6
}
variable "kafka_service_account_id" { type = string }

# Connector maps
variable "blob_store_connectors" {
  type = map(object({
    connector_name = string
    topic_name     = string
    container_name = string
  }))
}

variable "cosmos_db_connectors" {
  type = map(object({
    connector_name    = string
    topic_name        = string
    container_mapping = string
  }))
}

# ------------------
# Modules
# ------------------
module "azure" {
  source      = "./Azure_Module"
  name_prefix = var.name_prefix
  location    = var.azure_location
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

module "confluent" {
  source = "./Confluent_Module"


  kafka_cluster_id              = var.kafka_cluster_id
  kafka_rest_endpoint           = var.kafka_rest_endpoint
  kafka_api_key                 = var.kafka_api_key
  kafka_api_secret              = var.kafka_api_secret
  flink_api_key                 = var.flink_api_key
  flink_api_secret              = var.flink_api_secret
  flink_rest_endpoint           = var.flink_rest_endpoint
  flink_compute_pool_id         = var.flink_compute_pool_id
  flink_principal_id            = var.flink_principal_id
  confluent_organization_id     = var.confluent_organization_id
  confluent_environment_id      = var.confluent_environment_id
  schema_registry_id            = var.schema_registry_id
  schema_registry_rest_endpoint = var.schema_registry_rest_endpoint
  schema_registry_api_key       = var.schema_registry_api_key
  schema_registry_api_secret    = var.schema_registry_api_secret
  cloud_api_key                 = var.cloud_api_key
  cloud_api_secret              = var.cloud_api_secret
  kafka_partitions_count        = var.kafka_partitions_count
  kafka_service_account_id      = var.kafka_service_account_id

  # Pass Azure outputs into Confluent module inputs
  azure_blob_account_name       = module.azure.storage_account_name
  azure_blob_account_key        = module.azure.storage_account_primary_key
  azure_blob_container_name     = "${var.name_prefix}-confluentwth-departments" # example; adjust if you want dynamic mapping
  cosmos_db_account_endpoint    = module.azure.cosmos_account_endpoint
  cosmos_db_master_key          = module.azure.cosmos_primary_key
  cosmos_db_database_name       = module.azure.cosmos_database_name

  blob_store_connectors         = var.blob_store_connectors
  cosmos_db_connectors          = var.cosmos_db_connectors
}

