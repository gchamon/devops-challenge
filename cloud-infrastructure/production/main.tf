terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "devops-challenge"

    workspaces {
      name = "production"
    }
  }
}
