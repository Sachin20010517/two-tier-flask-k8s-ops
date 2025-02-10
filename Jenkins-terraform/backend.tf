terraform {
  backend "s3" {
    bucket = "two-tier-flask-k8s-ops-s3-bucket"
    key    = "Jenkins-Terraform/terraform.tfstate"
    region = "ap-south-1"
  }
}
