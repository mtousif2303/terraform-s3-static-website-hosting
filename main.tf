# -----------------------------------------------------------
# STEP 1: Setup AWS Provider
# -----------------------------------------------------------
provider "aws" {
  region = var.aws_region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"

  # -----------------------------------------------------------
  # STEP 8: Save the state (remote backend using S3)
  # Uncomment and configure after creating a separate state bucket
  # -----------------------------------------------------------
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "static-site/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# -----------------------------------------------------------
# STEP 2: Create Empty Bucket
# -----------------------------------------------------------
resource "aws_s3_bucket" "static_site" {
  bucket        = "mohamed_tousif_portfolio"
  force_destroy = true

  tags = {
    Name        = "mohamed_tousif_portfolio"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# -----------------------------------------------------------
# STEP 3: Setup Ownership Controls to Bucket Owner
# -----------------------------------------------------------
resource "aws_s3_bucket_ownership_controls" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# -----------------------------------------------------------
# STEP 4: Make the Bucket public access block
# -----------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  depends_on = [aws_s3_bucket_ownership_controls.static_site]
}

# -----------------------------------------------------------
# STEP 5: Assign ACL to bucket
# -----------------------------------------------------------
resource "aws_s3_bucket_acl" "static_site" {
  bucket = aws_s3_bucket.static_site.id
  acl    = "public-read"

  depends_on = [
    aws_s3_bucket_ownership_controls.static_site,
    aws_s3_bucket_public_access_block.static_site
  ]
}

# -----------------------------------------------------------
# STEP 6: Move files inside bucket
# -----------------------------------------------------------
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.static_site.id
  key          = "index.html"
  source       = "${path.module}/website/index.html"
  content_type = "text/html"
  acl          = "public-read"

  depends_on = [aws_s3_bucket_acl.static_site]
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.static_site.id
  key          = "error.html"
  source       = "${path.module}/website/error.html"
  content_type = "text/html"
  acl          = "public-read"

  depends_on = [aws_s3_bucket_acl.static_site]
}

# -----------------------------------------------------------
# STEP 7: Setup the main and error pages
# -----------------------------------------------------------
resource "aws_s3_bucket_website_configuration" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Bucket policy to allow public read access
resource "aws_s3_bucket_policy" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_site.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.static_site]
}
