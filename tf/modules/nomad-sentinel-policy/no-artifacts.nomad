# Job with NO artifacts - should PASS the Sentinel policy

job "test-no-artifacts" {
  datacenters = ["dc1"]
  type        = "batch"

  group "test" {
    count = 1

    task "hello" {
      driver = "docker"

      config {
        image   = "alpine:latest"
        command = "/bin/sh"
        args    = ["-c", "echo 'Hello! This job has no artifacts.'"]
      }

      # No artifact stanza - policy should allow this

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
