variable "project" {
  type = string
}

variable "gcp_datasource_func" {
  type = object({
    project  = string
    location = string
    name     = string
  })
}
