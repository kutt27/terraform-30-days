resource "aws_s3_bucket" "s3_bucket" {
  bucket = "amal-s3-bucket-terraform30days-15"
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "demo-oac"
  description                       = "Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "allow_cf" {
  bucket = aws_s3_bucket.s3_bucket.id
  depends_on = [ aws_s3_bucket_public_access_block.block ]
  policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "AllowCloudFrontServicePrincipal",
          "Effect": "Allow",
          "Principal": {
            "Service": "cloudfront.amazonaws.com"
          },
          "Action": [
            "s3:GetObject"
          ],
          "Resource": "${aws_s3_bucket.s3_bucket.arn}/*",
          Condition: {
            "StringEquals": {
              "AWS:SourceArn": aws_cloudfront_distribution.s3_distribution.arn
            }
          }
        }
      ]
  })
}

resource "aws_s3_object" "object" {
  for_each = fileset("${path.module}/www", "**/*")
  bucket = aws_s3_bucket.s3_bucket.id
  key    = each.value
  source = "${path.module}/www/${each.value}"
  etag = filemd5("${path.module}/www/${each.value}")
  content_type = lookup({
    "html" = "text/html",
    "css"  = "text/css",
    "js"   = "application/javascript",
    "json" = "application/json",
    "png"  = "image/png",
    "jpg"  = "image/jpeg",
    "jpeg" = "image/jpeg",
    "gif"  = "image/gif",
    "svg"  = "image/svg+xml",
    "ico"  = "image/x-icon",
    "txt"  = "text/plain"
  }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  aliases = [
    local.domain_name,
    "www.${local.domain_name}"
  ]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  // Updated the certificate
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 404 # Show a 404, even if S3 returns 403 (due to OAC)
    response_page_path = "/index.html" # Assuming single page app or index page handles errors
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/index.html"
    error_caching_min_ttl = 300
  }
}

resource "aws_route53_zone" "primary" {
  name = local.domain_name
}

# Create the Alias Record for the root domain (e.g., yourdomain.com)
resource "aws_route53_record" "root_alias" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = local.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# (Optional) Create a 'www' CNAME record for sub-domain (e.g., www.yourdomain.com)
resource "aws_route53_record" "www_alias" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.${local.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# Request a public certificate for your domain(s)
resource "aws_acm_certificate" "cert" {
  provider          = aws.acm
  domain_name       = local.domain_name
  validation_method = "DNS"
  subject_alternative_names = [
    "*.${local.domain_name}"
  ]
}

# Create a CloudFront Response Headers Policy
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name    = "Security-Headers-Policy"
  comment = "Adds standard security headers to all responses."

  security_headers_config {
    content_security_policy {
      content_security_policy = "default-src 'self'; style-src 'self' 'unsafe-inline';" # Adjust as needed
      override                = true
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
      preload                    = true
    }

    xss_protection {
      # mode   = true
      protection = true
      override   = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    content_type_options {
      override = true
    }
  }
}