resource "google_storage_bucket" "this" {
  name          = "${var.project}-renovate-gcp-datasource"
  project       = var.project
  location      = local.region
  force_destroy = true

  versioning {
    enabled = false
  }
}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "/tmp/renovate-gcp-datasource.zip"
}

resource "google_storage_bucket_object" "this" {
  bucket       = google_storage_bucket.this.name
  name         = "${data.archive_file.this.output_md5}.zip"
  content_type = "application/zip"
  source       = data.archive_file.this.output_path
}
