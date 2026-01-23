# Job that downloads and executes an approved script from GCS
# This tests both the Sentinel policy approval AND artifact execution
#
# NOTE: Replace PROJECT_ID with your actual GCP project ID before running

job "test-execute-artifact" {
  datacenters = ["dc1"]
  type        = "batch"

  group "execute" {
    count = 1

    task "run-script" {
      driver = "docker"

      config {
        image   = "alpine:latest"
        command = "/bin/sh"
        args    = ["-c", "chmod +x /local/approved-script.sh && /local/approved-script.sh"]
      }

      # APPROVED SOURCE - executable script from GCS bucket
      artifact {
        source      = "gcs::https://www.googleapis.com/storage/v1/hc-20d5722972a64f85ac80811f973-nomad-artifacts/scripts/approved-script.sh"
        destination = "local/"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
