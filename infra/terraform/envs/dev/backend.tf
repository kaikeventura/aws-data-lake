terraform {
  backend "s3" {
    bucket       = "aws-data-lake-dev-tfstate-2025"
    key          = "envs/dev/terraform.tfstate"
    region       = "us-east-1"
    profile      = "app-automatic-pipeline-dev"
    encrypt      = true
    use_lockfile = true
  }
}
