terraform {
  required_version = ">= 0.13"
  required_providers {
    alks = {
      source = "Cox-Automotive/alks"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}
