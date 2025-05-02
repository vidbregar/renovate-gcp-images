resource "google_service_account" "this" {
  project = var.project

  account_id   = "rnvt-gcp-dtsrc"
  display_name = "Service account used by the Renovate custom GCP datasource cloud function"
}

resource "google_project_iam_member" "disk_viewer" {
  for_each = var.disk_image_viewer_projects

  project = each.key
  role    = "roles/compute.imageUser"
  member  = "serviceAccount:${google_service_account.this.email}"
}
