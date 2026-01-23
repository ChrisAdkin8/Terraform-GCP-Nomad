# Job with approved artifact source - should PASS the Sentinel policy
# Uses GCS bucket created by this module as the approved artifact source
#
# NOTE: Replace PROJECT_ID with your actual GCP project ID before running

job "test-approved-artifact" {
  datacenters = ["dc1"]
  type        = "batch"

  group "test" {
    count = 1

    task "download" {
      driver = "docker"

      config {
        image   = "alpine:latest"
        command = "/bin/sh"
        args    = ["-c", "cat /local/config.json && echo 'Artifact downloaded successfully!'"]
      }

      # APPROVED SOURCE - GCS bucket created by this module
      # The URL pattern matches the allowed_artifact_prefixes in the Sentinel policy
      artifact {
        source      = "gcs::https://www.googleapis.com/storage/v1/hc-20d5722972a64f85ac80811f973-nomad-artifacts/configs/config.json"
        destination = "local/"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
