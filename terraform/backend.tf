terraform {
  backend "remote" {
    organization = "your-org-name"
    workspaces {
      name = "voxinsights-workspace"
    }
  }
}