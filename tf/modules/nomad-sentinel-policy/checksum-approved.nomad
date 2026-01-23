# Job with APPROVED checksum - should PASS the binary authorization policy
#
# This job downloads an artifact with a checksum that is in the approved manifest.
# The checksum ensures the artifact hasn't been tampered with.

job "test-checksum-approved" {
  datacenters = ["dc1"]
  type        = "batch"

  group "test" {
    count = 1

    task "verify-artifact" {
      driver = "docker"

      config {
        image   = "alpine:latest"
        command = "/bin/sh"
        args    = ["-c", "echo 'Artifact with approved checksum:' && cat /local/config.json && echo '' && echo 'Binary authorization PASSED!'"]
      }

      # APPROVED: This checksum is in the approved-checksums.json manifest
      artifact {
        source      = "gcs::https://www.googleapis.com/storage/v1/hc-20d5722972a64f85ac80811f973-nomad-artifacts/configs/config.json"
        destination = "local/"

        options {
          checksum = "sha256:a0d066fcf615c2093468be2428d3a940f57e2a225dc6a540d93ec26d32b4afb5"
        }
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
