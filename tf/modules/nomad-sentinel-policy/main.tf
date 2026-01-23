resource "nomad_sentinel_policy" "restrict_artifact_sources" {
  name              = "restrict-artifact-sources"
  description       = "Only allow artifacts from approved sources"
  enforcement_level = "hard-mandatory"
  scope             = "submit-job"

  policy = <<-EOT
    # restrict-artifact-sources.sentinel
    # Ensures all artifacts are sourced from approved locations

    import "strings"

    # Approved artifact source prefixes
    allowed_prefixes = ${jsonencode(local.artifact_prefixes)}

    # Check if artifact source starts with an allowed prefix
    is_approved_source = func(source) {
      for allowed_prefixes as prefix {
        if (strings.has_prefix(source, prefix) else false) {
          return true
        }
      }
      return false
    }

    # Check if task has only approved artifacts
    has_approved_artifacts = func(task) {
      # Use else operator to safely get artifacts with default empty list
      task_artifacts = task.artifacts else []

      # If no artifacts, that's fine
      if length(task_artifacts) == 0 {
        return true
      }

      for task_artifacts as artifact {
        # Safely get the source with else operator
        # Note: Sentinel uses snake_case - getter_source from GetterSource
        artifact_source = artifact.getter_source else ""

        if artifact_source == "" {
          print("Task", task.name else "unknown", "has artifact with no source defined")
          return false
        }
        if not is_approved_source(artifact_source) {
          print("Task", task.name else "unknown", "has unapproved artifact source:", artifact_source)
          return false
        }
      }

      return true
    }

    # Main rule: all tasks must have approved artifacts
    main = rule {
      all job.task_groups as tg {
        all tg.tasks as task {
          has_approved_artifacts(task)
        }
      }
    }
  EOT
}
