terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "digitrans-cm-terraform-rg"
    storage_account_name = "digitranscmtfstate"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

provider "azuread" {}

# Variables
variable "azure_region" {
  description = "Azure Region (South Africa North for data sovereignty)"
  type        = string
  default     = "southafricanorth"
}

variable "environment" {
  description = "Environment (dev, test, prod)"
  type        = string
  default     = "prod"
}

variable "admin_group_members" {
  description = "List of admin user principal names"
  type        = list(string)
  default     = []
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "digitrans-cm-${var.environment}-rg"
  location = var.azure_region

  tags = {
    Project     = "DIGITRANS-CM"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Client      = "AGROCAM-SA"
  }
}

# Azure AD Groups for RBAC
resource "azuread_group" "admins" {
  display_name     = "DIGITRANS-CM-Admins-${var.environment}"
  description      = "Administrators for DIGITRANS-CM project"
  security_enabled = true
}

resource "azuread_group" "managers" {
  display_name     = "DIGITRANS-CM-Managers-${var.environment}"
  description      = "Managers for DIGITRANS-CM project"
  security_enabled = true
}

resource "azuread_group" "agents" {
  display_name     = "DIGITRANS-CM-Agents-${var.environment}"
  description      = "Field agents for DIGITRANS-CM project"
  security_enabled = true
}

resource "azuread_group" "viewers" {
  display_name     = "DIGITRANS-CM-Viewers-${var.environment}"
  description      = "Read-only viewers for DIGITRANS-CM project"
  security_enabled = true
}

# Azure Key Vault for secrets management
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                       = "digitrans-cm-kv-${var.environment}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = var.environment == "prod" ? true : false

  enable_rbac_authorization = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = [] # Add your IP ranges
  }

  tags = {
    Name = "digitrans-cm-keyvault-${var.environment}"
  }
}

# Key Vault Access Policies
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = azuread_group.admins.object_id
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_group.managers.object_id
}

# Store database credentials in Key Vault
resource "azurerm_key_vault_secret" "db_username" {
  name         = "db-username"
  value        = "admin"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "jwt_secret" {
  name         = "jwt-secret"
  value        = "agrocam-digitrans-secret-key-2024-very-long-secret"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

# Log Analytics Workspace for centralized monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "digitrans-cm-logs-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.environment == "prod" ? 30 : 7

  tags = {
    Name = "digitrans-cm-logs-${var.environment}"
  }
}

# Application Insights for application monitoring
resource "azurerm_application_insights" "main" {
  name                = "digitrans-cm-appinsights-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = {
    Name = "digitrans-cm-appinsights-${var.environment}"
  }
}

# Azure Monitor Action Group for alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "digitrans-cm-alerts-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "dtcm-alert"

  email_receiver {
    name          = "ops-team"
    email_address = "ops@camtechsolutions.cm"
  }

  sms_receiver {
    name         = "ops-sms"
    country_code = "237"
    phone_number = "699000001"
  }

  tags = {
    Name = "digitrans-cm-alerts-${var.environment}"
  }
}

# Azure Monitor Metric Alerts
resource "azurerm_monitor_metric_alert" "high_response_time" {
  name                = "digitrans-cm-high-response-time-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_insights.main.id]
  description         = "Alert when application response time is too high"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "requests/duration"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 1000 # 1 second
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = {
    Name = "digitrans-cm-response-time-alert-${var.environment}"
  }
}

resource "azurerm_monitor_metric_alert" "high_error_rate" {
  name                = "digitrans-cm-high-error-rate-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_insights.main.id]
  description         = "Alert when application error rate is too high"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "requests/failed"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 10
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = {
    Name = "digitrans-cm-error-rate-alert-${var.environment}"
  }
}

# Azure Storage Account for backup and logs
resource "azurerm_storage_account" "backup" {
  name                     = "digitranscmbackup${var.environment}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
  }

  tags = {
    Name = "digitrans-cm-backup-${var.environment}"
  }
}

resource "azurerm_storage_container" "db_backups" {
  name                  = "database-backups"
  storage_account_name  = azurerm_storage_account.backup.name
  container_access_type = "private"
}

# Outputs
output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "key_vault_uri" {
  value     = azurerm_key_vault.main.vault_uri
  sensitive = true
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.main.id
}

output "application_insights_instrumentation_key" {
  value     = azurerm_application_insights.main.instrumentation_key
  sensitive = true
}

output "application_insights_connection_string" {
  value     = azurerm_application_insights.main.connection_string
  sensitive = true
}

output "admin_group_id" {
  value = azuread_group.admins.object_id
}

output "storage_account_name" {
  value = azurerm_storage_account.backup.name
}
