resource "aws_cloudfront_cache_policy" "lb-app-1" {
  name        = "custom-cache-policy"
  default_ttl = 180
  max_ttl     = 300
  min_ttl     = 1
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Host", "Origin", "Referer", "CUSTOM-HEADER"]
      }
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

resource "aws_cloudfront_origin_request_policy" "lb-app-1" {
  name = "custom-origin-request-policy"
  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Host", "Origin", "Referer", "CUSTOM-HEADER"]
    }
  }
  query_strings_config {
    query_string_behavior = "none"
  }
}

resource "aws_cloudfront_distribution" "lb-app-1" {
  enabled         = true
  is_ipv6_enabled = true
  aliases         = ["www.testm.com", "*.testm.com", "testm.com"]
  price_class     = "PriceClass_100"

  origin {
    domain_name = aws_lb.lbM-pub2pri-app-1.dns_name
    origin_id   = aws_lb.lbM-pub2pri-app-1.id
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
    origin_shield {
      enabled              = false
      origin_shield_region = "ap-southeast-1"
    }
  }

  default_cache_behavior {
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = aws_lb.lbM-pub2pri-app-1.id
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    origin_request_policy_id = aws_cloudfront_origin_request_policy.lb-app-1.id
    cache_policy_id          = aws_cloudfront_cache_policy.lb-app-1.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cf_testM.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }
  depends_on = [aws_lb.lbM-pub2pri-app-1]
}

resource "aws_cloudfront_distribution" "s3-bucketM" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = [aws_s3_bucket.bucketM.bucket]

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.bucketM.bucket
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    min_ttl     = 0
    default_ttl = 5 * 60
    max_ttl     = 60 * 60

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }
  }

  origin {
    domain_name = aws_s3_bucket.bucketM.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.bucketM.bucket

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cf_BucketM_OAI.cloudfront_access_identity_path
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cf_testM.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }
}

resource "aws_cloudfront_origin_access_identity" "cf_BucketM_OAI" {
  comment = "f_BucketM_OAI"
}

resource "aws_acm_certificate_validation" "cf_testM" {
  certificate_arn = aws_acm_certificate.cert_testM.arn
}

resource "aws_acm_certificate" "cert_testM" {
  domain_name       = "testm.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}
