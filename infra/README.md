# Infrastructure Configuration

This document details the Terraform configuration used to deploy the Serverless Zotero WebDAV server.

## Configuration Variables

The following variables can be customized to adapt the deployment to your needs. You can override them by passing `-var="name=value"` to the `terraform apply` command.

| Variable Name | Description | Default Value |
| :--- | :--- | :--- |
| `location` | Azure Region where resources will be created. | `eastus` |
| `resource_group_name` | Name of the Azure Resource Group. | `rg-zotero-serverless` |
| `webdav_username` | Username for Zotero WebDAV authentication. | `zotero` |
| `webdav_password` | Password for Zotero WebDAV authentication. | `ZoteroPass!` |
| `github_username` | GitHub username owning the container image. | `by3nrique` |

### ⚠️ Important Security Note
While a default password is provided for quick testing (`ZoteroPass!`), it is **highly recommended** to override it for production use to secure your data.

## Customization Examples

### 1. Basic Deployment (Default Settings)
Deploy with all default values (East US, user `zotero`, default password).
```bash
terraform apply
```

### 2. Custom Region and Password (Recommended)
Deploy to West Europe with a secure custom password.
```bash
terraform apply \
  -var="location=westeurope" \
  -var="webdav_password=MySuperSecretPassword99!"
```

### 3. Custom Username and Resource Group
Deploy with a specific username and resource group name.
```bash
terraform apply \
  -var="webdav_username=researcher" \
  -var="resource_group_name=rg-my-library"
```

## Resources Created

*   **Resource Group**: A logical container for the solution.
*   **Storage Account**: Standard LRS storage for persistence.
*   **File Share**: Named `zotero-data`, mounted to `/var/www/webdav` in the container.
*   **Container App Environment**: The managed environment for the serverless app.
*   **Container App**: The WebDAV server instance. It is configured to scale between 0 and 1 replica based on HTTP traffic.

### Increasing Storage Quota
The default storage quota for the file share is 5 GB. To increase this limit, you will need to modify the `main.tf` file directly:

1.  Open `infra/main.tf`.
2.  Locate the `azurerm_storage_share` resource.
3.  Update the `quota` value (in GB).

```hcl
resource "azurerm_storage_share" "share" {
  name                 = "zotero-data"
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 50 # Changed to 50 GB
}
```

### Clean Up
To remove all resources and stop incurring costs (warning: this will delete your Zotero data stored in Azure):

```bash
terraform destroy
```
