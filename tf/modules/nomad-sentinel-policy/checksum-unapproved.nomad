# Job with UNAPPROVED checksum - should FAIL the binary authorization policy
#
# This job attempts to download an artifact with a checksum that is NOT in the
# approved manifest. This simulates a tampered or unauthorized artifact.

job "test-checksum-unapproved" {
  datacenters = ["dc1"]
  type        = "batch"

  group "test" {
    count = 1

    task "suspicious-artifact" {
      driver = "docker"

      config {
        image   = "alpine:latest"
        command = "/bin/sh"
        args    = ["-c", "echo 'This should never run - checksum not approved'"]
      }

      # UNAPPROVED: This checksum is NOT in the approved manifest
      # Even though the source URL might be allowed, the checksum is not approved
      artifact {
        source      = "gcs::https://www.googleapis.com/storage/v1/hc-20d5722972a64f85ac80811f973-nomad-artifacts/configs/config.json"
        destination = "local/"

        options {
          # Fake/tampered checksum - not in approved list
          checksum = "sha256:0000000000000000000000000000000000000000000000000000000000000000"
        }
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
