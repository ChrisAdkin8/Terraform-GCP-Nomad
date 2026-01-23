# Job with MISSING checksum - should FAIL if require_artifact_checksum=true
#
# This job attempts to download an artifact without specifying a checksum.
# When checksum verification is required, this will be rejected.

job "test-checksum-missing" {
  datacenters = ["dc1"]
  type        = "batch"

  group "test" {
    count = 1

    task "no-checksum-artifact" {
      driver = "docker"

      config {
        image   = "alpine:latest"
        command = "/bin/sh"
        args    = ["-c", "echo 'This should not run if checksums are required'"]
      }

      # MISSING CHECKSUM: No checksum specified
      # This is a security risk as we cannot verify the artifact integrity
      artifact {
        source      = "gcs::https://www.googleapis.com/storage/v1/hc-20d5722972a64f85ac80811f973-nomad-artifacts/configs/config.json"
        destination = "local/"
        # No options.checksum specified!
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
