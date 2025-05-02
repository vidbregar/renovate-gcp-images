locals {
  region = "europe-west1"
}

resource "google_cloudfunctions2_function" "func" {
  name        = "renovate-gcp-datasource"
  project     = var.project
  location    = local.region
  description = "Function that acts as an Renovate custom datasource for GCP"

  build_config {
    runtime     = "python311"
    entry_point = "main"

    source {
      storage_source {
        bucket = google_storage_bucket.this.name
        object = google_storage_bucket_object.this.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "512Mi"
    timeout_seconds    = 30
    ingress_settings   = "ALLOW_ALL"

    environment_variables = {
      PROJECT = var.project
    }

    service_account_email = google_service_account.this.email
  }

  depends_on = [
    google_project_iam_member.disk_viewer,
  ]
}
