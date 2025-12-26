# Azure Serverless Zotero WebDAV

This repository provides a complete, ready-to-deploy solution for hosting your own Zotero synchronization server on Microsoft Azure.

It leverages **Azure Container Apps** to offer a "serverless" experience. The server automatically shuts down when you are not syncing, reducing infrastructure costs to near zero while maintaining a robust and secure backend for your research library.

## Key Features

*   **Serverless & Cost-Effective**: The container scales to zero replicas when idle. You only pay for the compute resources used during synchronization.
*   **Secure by Default**: Enforces HTTPS connections and protects your data with HTTP Basic Authentication.
*   **Persistent Storage**: Your Zotero attachments (PDFs, images) are stored in Azure Files, ensuring data safety independent of the application lifecycle.
*   **Optimized WebDAV**: Uses a lightweight, pre-configured Nginx Docker image specifically tuned for Zotero's requirements (large file support, correct WebDAV verbs).

## Deployment Guide

You can deploy this infrastructure in minutes using Terraform.

### Prerequisites

*   **Azure Subscription**: You need an active Azure account.
*   **Azure CLI**: Installed and logged in (`az login`).
*   **Terraform**: Installed on your local machine.

### Step-by-Step Deployment

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/by3nrique/azure-zotero-serverless.git
    cd azure-zotero-serverless/infra
    ```

2.  **Initialize Terraform**:
    ```bash
    terraform init
    ```

3.  **Deploy**:
    Run the following command. Replace `YOUR_SECURE_PASSWORD` with a strong password of your choice. This will be the password you enter in Zotero.
    ```bash
    terraform apply -var="webdav_password=YOUR_SECURE_PASSWORD"
    ```
    Type `yes` when prompted to confirm the creation of resources.

4.  **Get your Server URL**:
    Once the deployment finishes, Terraform will output a value named `app_url`. It will look something like:
    `https://ca-zotero-webdav.gentleground-123456.eastus.azurecontainerapps.io`

## Configuring Zotero

1.  Open Zotero on your computer.
2.  Go to **Preferences** (or Settings) -> **Sync**.
3.  In the **File Syncing** section, change the mode from "Zotero" to **WebDAV**.
4.  Enter the following details:
    *   **URL**: The `app_url` you obtained from Terraform.
    *   **Username**: `zotero` (default) or the custom user you defined.
    *   **Password**: The password you used in the `terraform apply` command.
5.  Click **Verify Server**. Zotero will check the connection and ensure it can write files.

## Architecture Overview

This solution deploys the following Azure resources:

*   **Azure Container App**: Hosts the WebDAV server using the public image `ghcr.io/by3nrique/azure-zotero-serverless:latest`.
*   **Azure Storage Account**: Provides the file share (`zotero-data`) mounted to the container.

## Advanced Configuration

For details on how to customize the region, storage quotas, or compute resources, please refer to the [Infrastructure Documentation](infra/README.md).
