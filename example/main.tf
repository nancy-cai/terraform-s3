module "example-bucket" {
  source = "https://github.com/nancy-cai/terraform-s3.git//module"
  providers = {
    aws.replication = aws.replication
  }
  environment-name                  = "dev"
  bucket-prefix                     = "example"
  force-destroy-s3-buckets            = false
  enable-versioning                   = true
  replication-enabled                 = true
  replication-kms-encrypted-enabled   = true
  replication-source-kms-key-arn      = "xxxxx"
  replication-destination-kms-key-arn = "xxxxx"
  replication-source-region           = "ap-southeast-2"
  replication-destination-region      = "ap-southeast-1"
  lifecycle-enabled                   = true
  objects-expiration                  = 30
  logs-expiration                     = 90
  aws-principles-object-readwrite     = ["arn:aws:iam::123456789:role/example"]
  aws-principles-bucket-object        = ["arn:aws:iam::123456789:root"] 
}
