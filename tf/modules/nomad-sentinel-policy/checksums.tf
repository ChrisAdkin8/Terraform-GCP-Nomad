# Checksum-based Binary Authorization for Nomad Artifacts
#
# This file manages:
# 1. Approved checksums JSON file in GCS
# 2. IAM controls to protect the checksums file
# 3. Sentinel policy for checksum enforcement

# Local checksums for artifacts managed by this module
locals {
  # Checksums for artifacts uploaded by this module
  managed_artifact_checksums = {
    "configs/config.json" = {
      checksum    = "sha256:a0d066fcf615c2093468be2428d3a940f57e2a225dc6a540d93ec26d32b4afb5"
      description = "Application configuration file"
      added_by    = "terraform"
      added_at    = "2026-01-23"
    }
    "scripts/approved-script.sh" = {
      checksum    = "sha256:35ec6141a22d11b10de302a3a7365059f821988be7f23953f6b8c94bcf6c2dc6"
      description = "Approved execution script"
      added_by    = "terraform"
      added_at    = "2026-01-23"
    }
    "app/config.yaml" = {
      checksum    = "sha256:8b1c0a9c04810980f4da4d97fa25b9097f348acba2605fe64be4afdb9fa2cb05"
      description = "Application YAML configuration"
      added_by    = "terraform"
      added_at    = "2026-01-23"
    }
  }

  # Merge managed checksums with any additional approved checksums
  all_approved_checksums = merge(local.managed_artifact_checksums, var.additional_approved_checksums)

  # Extract just the checksum values for the Sentinel policy
  approved_checksum_values = [for k, v in local.all_approved_checksums : v.checksum]
}

# Store the approved checksums manifest in GCS
resource "google_storage_bucket_object" "approved_checksums_manifest" {
  name         = "security/approved-checksums.json"
  bucket       = google_storage_bucket.nomad_artifacts.name
  content_type = "application/json"

  content = jsonencode({
    version     = "1.0"
    description = "Approved artifact checksums for Nomad binary authorization"
    updated_at  = timestamp()
    checksums   = local.all_approved_checksums
  })

  lifecycle {
    # Prevent accidental deletion
    prevent_destroy = false  # Set to true in production
  }
}

# IAM: Restrict who can modify the checksums file
# Only the CI/CD service account and admins can update checksums
resource "google_storage_bucket_iam_member" "checksums_admin" {
  for_each = toset(var.checksums_admin_members)

  bucket = google_storage_bucket.nomad_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = each.value

  condition {
    title       = "checksums_file_only"
    description = "Only allow admin access to the checksums manifest file"
    expression  = "resource.name.endsWith('/security/approved-checksums.json')"
  }
}

# Sentinel policy for checksum-based binary authorization
resource "nomad_sentinel_policy" "artifact_checksum_authorization" {
  name              = "artifact-checksum-authorization"
  description       = "Enforces that all artifacts must have approved checksums (binary authorization)"
  enforcement_level = var.checksum_policy_enforcement_level
  scope             = "submit-job"

  policy = <<-EOT
    # artifact-checksum-authorization.sentinel
    # Ensures all artifacts have approved checksums for binary authorization

    import "strings"

    # Approved checksums from the secure manifest
    approved_checksums = ${jsonencode(local.approved_checksum_values)}

    # Configuration
    require_checksum = ${var.require_artifact_checksum}

    # Extract checksum from artifact options
    # Nomad stores artifact options in getter_options (snake_case in Sentinel)
    get_checksum = func(artifact) {
      options = artifact.getter_options else {}
      return options["checksum"] else ""
    }

    # Get artifact source for error messages
    get_source = func(artifact) {
      return artifact.getter_source else "unknown"
    }

    # Verify checksum format is valid (sha256:hex)
    is_valid_checksum_format = func(checksum) {
      return checksum matches "^sha256:[a-f0-9]{64}$"
    }

    # Verify checksum is in the approved list
    is_approved_checksum = func(checksum) {
      for approved_checksums as approved {
        if checksum == approved {
          return true
        }
      }
      return false
    }

    # Check all artifacts in a task have approved checksums
    task_has_approved_artifacts = func(task) {
      task_name = task.name else "unknown"
      artifacts = task.artifacts else []

      # No artifacts is allowed
      if length(artifacts) == 0 {
        return true
      }

      for artifacts as artifact {
        source = get_source(artifact)
        checksum = get_checksum(artifact)

        # Check if checksum is required
        if require_checksum and checksum == "" {
          print("DENIED: Task", task_name, "- artifact", source, "has no checksum specified")
          print("  All artifacts must include a checksum for binary authorization")
          return false
        }

        # If checksum is provided, validate it
        if checksum != "" {
          # Validate format
          if not is_valid_checksum_format(checksum) {
            print("DENIED: Task", task_name, "- artifact", source, "has invalid checksum format:", checksum)
            print("  Expected format: sha256:<64 hex characters>")
            return false
          }

          # Validate against approved list
          if not is_approved_checksum(checksum) {
            print("DENIED: Task", task_name, "- artifact", source, "has unapproved checksum:", checksum)
            print("  This checksum is not in the approved checksums manifest")
            print("  Contact your CI/CD team to add this artifact to the approved list")
            return false
          }

          print("APPROVED: Task", task_name, "- artifact", source, "has valid approved checksum")
        }
      }

      return true
    }

    # Main rule: all tasks must have approved artifact checksums
    main = rule {
      all job.task_groups as tg {
        all tg.tasks as task {
          task_has_approved_artifacts(task)
        }
      }
    }
  EOT
}

# Output the approved checksums for reference
output "approved_checksums" {
  description = "Map of approved artifact checksums"
  value       = local.all_approved_checksums
}

output "approved_checksums_manifest_url" {
  description = "URL of the approved checksums manifest file"
  value       = "gs://${google_storage_bucket.nomad_artifacts.name}/security/approved-checksums.json"
}

output "checksum_policy_name" {
  description = "Name of the checksum authorization Sentinel policy"
  value       = nomad_sentinel_policy.artifact_checksum_authorization.name
}
