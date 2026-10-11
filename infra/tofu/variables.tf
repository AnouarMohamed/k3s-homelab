variable "cloudflare_account_id" {
  description = "Cloudflare account identifier supplied through TF_VAR_cloudflare_account_id."
  type        = string
  sensitive   = true
  nullable    = false

  validation {
    condition     = length(var.cloudflare_account_id) > 0
    error_message = "cloudflare_account_id must not be empty."
  }
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone identifier supplied through TF_VAR_cloudflare_zone_id."
  type        = string
  sensitive   = true
  nullable    = false

  validation {
    condition     = length(var.cloudflare_zone_id) > 0
    error_message = "cloudflare_zone_id must not be empty."
  }
}
