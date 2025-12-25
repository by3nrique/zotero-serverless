resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# --- Persistent Storage ---
resource "azurerm_storage_account" "sa" {
  name                     = "stzotero${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_share" "share" {
  name                 = "zotero-data"
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 5 # GB
}

# --- Container Apps Environment ---

resource "azurerm_container_app_environment" "env" {
  name                       = "cae-zotero"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
}

# Link Storage Account to Environment
resource "azurerm_container_app_environment_storage" "storage_mount" {
  name                         = "zotero-files-mount"
  container_app_environment_id = azurerm_container_app_environment.env.id
  account_name                 = azurerm_storage_account.sa.name
  share_name                   = azurerm_storage_share.share.name
  access_key                   = azurerm_storage_account.sa.primary_access_key
  access_mode                  = "ReadWrite"
}

# --- Container App ---
resource "azurerm_container_app" "app" {
  name                         = "ca-zotero-webdav"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  secret {
    name  = "webdav-password-secret"
    value = var.webdav_password
  }

  template {
    container {
      name   = "zotero-webdav"
      image  = "ghcr.io/${var.github_username}/zotero-serverless:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "WEBDAV_USERNAME"
        value = var.webdav_username
      }
      
      env {
        name        = "WEBDAV_PASSWORD"
        secret_name = "webdav-password-secret"
      }

      volume_mounts {
        name = "zotero-volume"
        path = "/var/www/webdav"
      }
    }

    # Volume definition within the app
    volume {
      name         = "zotero-volume"
      storage_name = azurerm_container_app_environment_storage.storage_mount.name
      storage_type = "AzureFile"
    }

    # Scale to zero (Pure Serverless)
    min_replicas = 0
    max_replicas = 1
  }

  ingress {
    external_enabled           = true
    target_port                = 80
    allow_insecure_connections = false # Force HTTPS
    transport                  = "auto"

    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }
}

output "app_url" {
  value = azurerm_container_app.app.latest_revision_fqdn
}
