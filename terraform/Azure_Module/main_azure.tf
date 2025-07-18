terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.35.0"
    }
  }

  required_version = ">= 1.11.4"
}

provider "azurerm" {
  features {
  }
  subscription_id = "a8df2f8c-b201-497e-82cf-026956b63875"
}

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string

  validation {
    condition     = length(var.name_prefix) <= 6 && can(regex("^[a-z0-9]+$", var.name_prefix))
    error_message = "The name_prefix must be 6 characters or fewer and contain only lowercase letters (a-z) or numbers (0-9)."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "westus2"
}


# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.name_prefix}-confluentwth-rg"
  location = var.location
}

# Azure AI Search Instance
resource "azurerm_search_service" "search" {
  name                = "${var.name_prefix}-confluentwth-search"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "standard"
  partition_count     = 1
  replica_count       = 1
  local_authentication_enabled = true
  public_network_access_enabled = true
}

# Azure Redis Cache
# resource "azurerm_redis_cache" "redis" {
#   name                = "${var.name_prefix}-confluentwth-redis"
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
#   capacity            = 1    # C1 (1 GB)
#   family              = "C"
#   sku_name            = "Standard"  # Basic, Standard or Premium
#   non_ssl_port_enabled = false
#   minimum_tls_version  = "1.2"
#   access_keys_authentication_enabled = true
# }

# Azure Cosmos DB (SQL API)
resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = "${var.name_prefix}-confluentwth-cosmos"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Strong"
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }
}

# Cosmos DB SQL Database
resource "azurerm_cosmosdb_sql_database" "retailstore" {
  name                = "${var.name_prefix}-confluentwth-retailstore"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.cosmosdb.name

  throughput          = 400 # Provisioned throughput at the database level (optional if you want)
}

# Purchases Container
resource "azurerm_cosmosdb_sql_container" "purchases" {
  name                = "${var.name_prefix}-confluentwth-purchases"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.cosmosdb.name
  database_name       = azurerm_cosmosdb_sql_database.retailstore.name

  partition_key_paths  = ["/customer_id"]
  throughput          = 400 # optional: you can set throughput here too, or rely on database throughput
}

# Returns Container
resource "azurerm_cosmosdb_sql_container" "returns" {
  name                = "${var.name_prefix}-confluentwth-returns"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.cosmosdb.name
  database_name       = azurerm_cosmosdb_sql_database.retailstore.name

  partition_key_paths  = ["/customer_id"]
  throughput          = 400
}

# Replenishments Container
resource "azurerm_cosmosdb_sql_container" "replenishments" {
  name                = "${var.name_prefix}-confluentwth-replenishments"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.cosmosdb.name
  database_name       = azurerm_cosmosdb_sql_database.retailstore.name

  partition_key_paths  = ["/vendor_id"]
  throughput          = 400
}


# Azure Blob Storage (Storage Account)
resource "azurerm_storage_account" "storage" {
  name                     = "${var.name_prefix}confluentwthstore"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  account_kind             = "StorageV2"
}

# Define a list of blob container names
locals {
  container_names = [
    "${var.name_prefix}-confluentwth-departments",
    "${var.name_prefix}-confluentwth-product-pricing",
    "${var.name_prefix}-confluentwth-product-skus"
  ]
}

# Create containers using a loop
resource "azurerm_storage_container" "containers" {
  for_each              = toset(local.container_names)
  name                  = each.value
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

