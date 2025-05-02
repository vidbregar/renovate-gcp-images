resource "google_service_account" "renovate" {
  project      = var.project
  account_id   = "renovate"
  display_name = "Renovate Service Account"
}

resource "google_cloud_run_service_iam_member" "gcp_datasource_invoker" {
  project  = var.gcp_datasource_func.project
  location = var.gcp_datasource_func.location
  service  = var.gcp_datasource_func.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.renovate.email}"
}

resource "google_service_account_key" "renovate" {
  service_account_id = google_service_account.renovate.name
}

resource "gitlab_project_variable" "renovate_sa_key" {
  project       = "your-renovate-gitlab-project"
  key           = "RENOVATE_SA_KEY"
  value         = base64decode(google_service_account_key.renovate.private_key)
  protected     = true
  variable_type = "file"
}
