# Job with INVALID checksum format - should FAIL the binary authorization policy
#
# This job has a checksum that doesn't match the required format (sha256:hex64).

job "test-checksum-invalid-format" {
  datacenters = ["dc1"]
  type        = "batch"

  group "test" {
    count = 1

    task "bad-format-artifact" {
      driver = "docker"

      config {
        image   = "alpine:latest"
        command = "/bin/sh"
        args    = ["-c", "echo 'This should not run - invalid checksum format'"]
      }

      # INVALID FORMAT: Checksum doesn't match sha256:<64 hex chars>
      artifact {
        source      = "gcs::https://www.googleapis.com/storage/v1/hc-20d5722972a64f85ac80811f973-nomad-artifacts/configs/config.json"
        destination = "local/"

        options {
          # Wrong format - too short and missing prefix
          checksum = "abc123"
        }
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
