# GCS bucket for storing approved Nomad job artifacts

resource "google_storage_bucket" "nomad_artifacts" {
  name          = "${var.project_id}-nomad-artifacts"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  labels = {
    purpose = "nomad-artifacts"
    managed = "terraform"
  }
}

# Grant read access to specified service accounts for Nomad to fetch artifacts
resource "google_storage_bucket_iam_member" "artifact_reader" {
  for_each = toset(var.artifact_reader_members)

  bucket = google_storage_bucket.nomad_artifacts.name
  role   = "roles/storage.objectViewer"
  member = each.value
}

# Upload the executable script artifact to the bucket
resource "google_storage_bucket_object" "approved_script" {
  name         = "scripts/approved-script.sh"
  bucket       = google_storage_bucket.nomad_artifacts.name
  source       = "${path.module}/artifacts/approved-script.sh"
  content_type = "application/x-sh"
}

# Upload a config file artifact
resource "google_storage_bucket_object" "config_json" {
  name         = "configs/config.json"
  bucket       = google_storage_bucket.nomad_artifacts.name
  source       = "${path.module}/artifacts/config.json"
  content_type = "application/json"
}

# Upload another config file for testing
resource "google_storage_bucket_object" "app_config" {
  name         = "app/config.yaml"
  bucket       = google_storage_bucket.nomad_artifacts.name
  source       = "${path.module}/artifacts/app-config.yaml"
  content_type = "application/x-yaml"
}

# Output the bucket URL prefix for use in allowed_artifact_prefixes
output "artifact_bucket_url_prefix" {
  description = "The GCS bucket URL prefix for allowed artifacts"
  value       = "https://storage.googleapis.com/${google_storage_bucket.nomad_artifacts.name}/"
}

output "artifact_bucket_name" {
  description = "The name of the GCS artifacts bucket"
  value       = google_storage_bucket.nomad_artifacts.name
}
