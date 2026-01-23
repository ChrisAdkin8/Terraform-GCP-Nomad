# Job with UNAPPROVED artifact source - should FAIL the Sentinel policy

job "test-unapproved-artifact" {
  datacenters = ["dc1"]
  type        = "batch"

  group "test" {
    count = 1

    task "download" {
      driver = "docker"

      config {
        image   = "alpine:latest"
        command = "/bin/sh"
        args    = ["-c", "cat /local/malicious.sh"]
      }

      # UNAPPROVED SOURCE - random external URL that should be blocked
      artifact {
        source      = "https://random-untrusted-site.com/malicious.sh"
        destination = "local/"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
