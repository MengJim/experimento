resource "aws_route53_zone" "testM" {
  name = "testm.com"
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.testM.zone_id
  name    = "testm.com"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.lb-app-1.domain_name
    zone_id                = aws_cloudfront_distribution.lb-app-1.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.testM.zone_id
  name    = "www.testm.com"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.lb-app-1.domain_name
    zone_id                = aws_cloudfront_distribution.lb-app-1.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "lb-app-1" {
  zone_id = aws_route53_zone.testM.zone_id
  name    = "lb-app-1.testm.com"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.lb-app-1.domain_name
    zone_id                = aws_cloudfront_distribution.lb-app-1.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "assets" {
  zone_id = aws_route53_zone.testM.zone_id
  name    = "assets.testm.com"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.s3-bucketM.domain_name
    zone_id                = aws_cloudfront_distribution.s3-bucketM.hosted_zone_id
    evaluate_target_health = true
  }
}