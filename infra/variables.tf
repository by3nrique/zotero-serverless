variable "location" {
  description = "Azure region"
  default     = "italynorth"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "rg-zotero-serverless2"
}

variable "github_username" {
  description = "GitHub username (owner of the GHCR package)"
  type        = string
  default     = "by3nrique"
}

variable "webdav_username" {
  description = "Username for Zotero WebDAV authentication"
  type        = string
  default     = "zotero"
}

variable "webdav_password" {
  description = "Password for Zotero WebDAV authentication"
  type        = string
  sensitive   = true
  default     = "ZoteroPass!"
}
