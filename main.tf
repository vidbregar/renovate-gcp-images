locals {
  gcp_project_name = "my-project"
}

module "gcp_datasource" {
  source = "modules/gcp_datasource"

  project = local.gcp_project_name

  disk_image_viewer_projects = [
    "my-project",
  ]
}

module "renovate" {
  source = "modules/renovate"

  project = local.gcp_project_name

  gcp_datasource_func = {
    project  = module.gcp_datasource.func_project
    location = module.gcp_datasource.func_location
    name     = module.gcp_datasource.func_name
  }
}
