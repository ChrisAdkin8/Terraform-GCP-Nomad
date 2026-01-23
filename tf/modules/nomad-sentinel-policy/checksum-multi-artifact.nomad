# Job with MULTIPLE artifacts - tests that ALL artifacts must have approved checksums
#
# This job downloads multiple artifacts, all with approved checksums.
# Demonstrates binary authorization for complex jobs.

job "test-checksum-multi-artifact" {
  datacenters = ["dc1"]
  type        = "batch"

  group "app" {
    count = 1

    task "multi-artifact-task" {
      driver = "docker"

      config {
        image   = "alpine:latest"
        command = "/bin/sh"
        args = ["-c", <<-EOF
          echo "=== Binary Authorization Test: Multiple Artifacts ==="
          echo ""
          echo "Artifact 1 - config.json:"
          cat /local/config.json
          echo ""
          echo "Artifact 2 - approved-script.sh:"
          cat /local/approved-script.sh
          echo ""
          echo "Artifact 3 - config.yaml:"
          cat /local/config.yaml
          echo ""
          echo "=== All artifacts verified with approved checksums! ==="
        EOF
        ]
      }

      # Artifact 1: JSON config with approved checksum
      artifact {
        source      = "gcs::https://www.googleapis.com/storage/v1/hc-20d5722972a64f85ac80811f973-nomad-artifacts/configs/config.json"
        destination = "local/"

        options {
          checksum = "sha256:a0d066fcf615c2093468be2428d3a940f57e2a225dc6a540d93ec26d32b4afb5"
        }
      }

      # Artifact 2: Shell script with approved checksum
      artifact {
        source      = "gcs::https://www.googleapis.com/storage/v1/hc-20d5722972a64f85ac80811f973-nomad-artifacts/scripts/approved-script.sh"
        destination = "local/"

        options {
          checksum = "sha256:35ec6141a22d11b10de302a3a7365059f821988be7f23953f6b8c94bcf6c2dc6"
        }
      }

      # Artifact 3: YAML config with approved checksum
      artifact {
        source      = "gcs::https://www.googleapis.com/storage/v1/hc-20d5722972a64f85ac80811f973-nomad-artifacts/app/config.yaml"
        destination = "local/"

        options {
          checksum = "sha256:8b1c0a9c04810980f4da4d97fa25b9097f348acba2605fe64be4afdb9fa2cb05"
        }
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
