resource "aws_s3_bucket" "bucketM" {
  bucket = "bucketM"

  tags = {
    Name        = "bucketM"
    project     = "Mtest"
    environment = "production"
    module      = "s3"
  }
}

resource "aws_s3_bucket_ownership_controls" "s3_rule_bucketM_OC" {
  bucket = aws_s3_bucket.bucketM.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_rule_bucketM_Pub" {
  bucket = aws_s3_bucket.bucketM.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "read_gitbook" {
  bucket = aws_s3_bucket.bucketM.id
  policy = data.aws_iam_policy_document.iam_bucketM_s3_read.json
}

resource "aws_s3_bucket_acl" "s3_acl_bucketM" {
  bucket = aws_s3_bucket.bucketM.id
  acl    = "public-read"
}

data "aws_iam_policy_document" "iam_bucketM_s3_read" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucketM.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.cf_BucketM_OAI.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.bucketM.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.cf_BucketM_OAI.iam_arn]
    }
  }
}