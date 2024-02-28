resource "aws_wafv2_web_acl" "nginx_waf" {
  name  = "nginx-waf-acl"
  scope = "REGIONAL"
  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "nginxWaf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 0
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommon"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_wafv2_web_acl_association" "nginx_waf_association" {
  resource_arn = aws_lb.assessment_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.nginx_waf.arn
}
