variable "nomad_address" {
  type        = string
  description = "Nomad cluster API address"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region for the artifacts bucket"
  default     = "us-central1"
}

variable "allowed_artifact_prefixes" {
  description = "List of allowed artifact source prefixes. If not specified, defaults to the GCS bucket created by this module."
  type        = list(string)
  default     = null
}

variable "artifact_reader_members" {
  description = "List of IAM members that should have read access to the artifacts bucket (e.g., service accounts used by Nomad nodes). Format: 'serviceAccount:email@project.iam.gserviceaccount.com'"
  type        = list(string)
  default     = []
}

variable "additional_approved_checksums" {
  description = "Additional approved artifact checksums beyond those managed by this module. Map of artifact path to checksum info."
  type = map(object({
    checksum    = string
    description = string
    added_by    = string
    added_at    = string
  }))
  default = {}
}

variable "checksums_admin_members" {
  description = "IAM members allowed to modify the approved checksums manifest (e.g., CI/CD service accounts)"
  type        = list(string)
  default     = []
}

variable "checksum_policy_enforcement_level" {
  description = "Enforcement level for the checksum authorization policy: soft-mandatory, hard-mandatory, or advisory"
  type        = string
  default     = "hard-mandatory"

  validation {
    condition     = contains(["soft-mandatory", "hard-mandatory", "advisory"], var.checksum_policy_enforcement_level)
    error_message = "Enforcement level must be soft-mandatory, hard-mandatory, or advisory."
  }
}

variable "require_artifact_checksum" {
  description = "If true, all artifacts MUST have a checksum specified. If false, artifacts without checksums are allowed but checksums that are specified must be approved."
  type        = bool
  default     = true
}

locals {
  # Default to the GCS bucket URL if no prefixes are explicitly provided
  # Use gcs:: prefix for proper authentication with go-getter
  artifact_prefixes = var.allowed_artifact_prefixes != null ? var.allowed_artifact_prefixes : [
    "gcs::https://www.googleapis.com/storage/v1/${var.project_id}-nomad-artifacts/",
  ]
}
