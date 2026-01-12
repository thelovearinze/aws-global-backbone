
terraform {

  required_providers {

    aws = {

      source  = "hashicorp/aws"

      version = "~> 5.0"

    }

  }

}



# The Primary Hub Region (Ireland)

provider "aws" {

  region = "eu-west-1"

  alias  = "hub"

}



# The Africa Spoke Region (Cape Town)

provider "aws" {

  region = "af-south-1"

  alias  = "africa"

}

