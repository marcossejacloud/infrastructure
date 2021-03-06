/* ========================================================================= */
/*                                               /admin whitelist protection */
/* ========================================================================= */

/* =============================================================== variables */
variable "app_name" {
}

variable "environment" {
}

variable "alb_arn" {
}

variable "protected_endpoint" {
}

variable "admin_remote_ipset" {
  type = list(string)
}

/* ================================================================= outputs */
output "waf_acl_id" {
  value = aws_wafregional_web_acl.acl.id
}

/* =================================================================== rules */
resource "aws_wafregional_ipset" "admin_remote_ipset" {
  name = "${var.environment}-${var.app_name}-match-admin-remote-ip"
  dynamic "ip_set_descriptor" {
    for_each = var.admin_remote_ipset
    content {
      # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
      # which keys might be set in maps assigned here, so it has
      # produced a comprehensive set here. Consider simplifying
      # this after confirming which keys can be set in practice.

      type  = ip_set_descriptor.value.type
      value = ip_set_descriptor.value.value
    }
  }
}

resource "aws_wafregional_byte_match_set" "match_admin_url" {
  name = "${var.environment}-${var.app_name}-match-admin-url"
  byte_match_tuples {
    text_transformation   = "URL_DECODE"
    target_string         = var.protected_endpoint
    positional_constraint = "STARTS_WITH"
    field_to_match {
      type = "URI"
    }
  }
}

resource "aws_wafregional_rule" "detect_admin_access" {
  name        = "${var.environment}-${var.app_name}-detect-admin-access"
  metric_name = "${var.environment}${var.app_name}detectadminaccess"

  predicate {
    data_id = aws_wafregional_ipset.admin_remote_ipset.id
    negated = true
    type    = "IPMatch"
  }

  predicate {
    data_id = aws_wafregional_byte_match_set.match_admin_url.id
    negated = false
    type    = "ByteMatch"
  }
}

resource "aws_wafregional_web_acl" "acl" {
  name        = "${var.environment}-${var.app_name}-admin-acl"
  metric_name = "${var.environment}${var.app_name}adminacl"

  default_action {
    type = "ALLOW"
  }

  rule {
    action {
      type = "BLOCK"
    }
    priority = 1
    rule_id  = aws_wafregional_rule.detect_admin_access.id
    type     = "REGULAR"
  }
}

resource "aws_wafregional_web_acl_association" "acl-association" {
  resource_arn = var.alb_arn
  web_acl_id   = aws_wafregional_web_acl.acl.id
}

/* ========================================================================= */
