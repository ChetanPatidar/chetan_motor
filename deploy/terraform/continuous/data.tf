data "aws_vpc" "vpc" {
    id = "${var.vpc_id}"
}

data "aws_route53_zone" "public_hosted_zone" {
    name         = "${var.route53_zone_name}."
    private_zone = false
}

data "template_file" "aws_cf_sns_stack" {
  template =  "${file("${path.module}/cloudformation/cf.yml")}"
  vars = {
   sns_subscription_email_address_list  = "${var.email_alarm_notification_list}"
   sns_topic_https_endpoint             = "${var.pagerduty_alarm_notification_endpoint}"
   topic_arn                            = "${aws_sns_topic.alarm.arn}"
   }
}
