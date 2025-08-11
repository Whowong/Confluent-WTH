# Outputs (Used Later for Setting Up Confluent Resources)
output "resource_group_name" {
  description = "The name of the resource group"
  value       = module.azure.resource_group_name
}

output "cosmosdb_endpoint" {
  description = "Endpoint URI for CosmosDB Account"
  value       = module.azure.cosmos_account_endpoint
}

output "cosmosdb_account_name" {
  description = "The name of the Cosmos DB account"
  value       = module.azure.cosmos_account_name
}

output "cosmosdb_primary_key" {
  description = "Primary key for CosmosDB Account"
  value       = module.azure.cosmos_primary_key
  sensitive   = true
}

output "cosmosdb_database_name" {
  description = "The name of the Cosmos DB SQL database"
  value       = module.azure.cosmos_database_name
}

output "search_service_name" {
  description = "The name of the Azure AI Search instance"
  value       = module.azure.search_service_name
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = module.azure.storage_account_name
}

output "storage_account_primary_access_key" {
  description = "Primary Access Key for Azure Storage Account"
  value       = module.azure.storage_account_primary_key
  sensitive   = true
}

# output "redis_hostname" {
#   description = "Redis Cache Hostname"
#   value       = azurerm_redis_cache.redis.hostname
# }
# 
# output "redis_primary_access_key" {
#   description = "Primary Access Key for Azure Redis Cache"
#   value       = azurerm_redis_cache.redis.primary_access_key
#   sensitive   = true
# }

