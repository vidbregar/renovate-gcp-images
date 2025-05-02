variable "project" {
  type = string
}

variable "disk_image_viewer_projects" {
  description = "A list of projects that the function will be able to access for listing disk images."
  type        = set(string)
}
