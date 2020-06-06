resource "aws_cloudfront_origin_access_identity" "main" {}

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name]
  price_class         = "PriceClass_All"

  origin {
    domain_name = module.s3_bucket_static.bucket.bucket_regional_domain_name
    origin_id   = "frontend"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

    origin {
      domain_name = module.load_balancer.load_balancer.dns_name
      origin_id   = "api"

      custom_origin_config {
        http_port = 80
        https_port = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols = ["TLSv1.2"]
      }
    }

  default_cache_behavior {
    target_origin_id       = "frontend"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"]

    min_ttl     = 259200
    default_ttl = 259200
    max_ttl     = 31536000
    compress    = true

    forwarded_values {
      query_string = false
      headers = [
        "Origin",
        "Access-Control-Allow-Origin",
        "Access-Control-Request-Headers",
        "Access-Control-Request-Methods"
      ]

      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern     = "/api*"
    allowed_methods  = ["GET", "PUT", "DELETE", "PATCH", "POST", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "OPTIONS", "HEAD"]
    target_origin_id = "api"

    forwarded_values {
      query_string = false
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }

    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = false
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = module.acm_certificate_domain.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

  custom_error_response {
    error_code            = "403"
    error_caching_min_ttl = "300"
    response_page_path    = "/index.html"
    response_code         = "200"
  }

  tags = {
    ManagedBy = "Terraform"
  }
}

