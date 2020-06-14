variable "account_id" { }
variable "account_name" { }
variable "vpc_id" { }
variable "jenkins_cidr" { }
variable "route53_zone_name" { }
variable "s3_content_bucket" { }
variable "db_subnet_names" { }
variable "num_db_subnets" { }
variable "db_instance_type" { }
variable "app_name" { }
variable "app_family" { }
variable "region"           { default = "us-west-2" }
variable "git_repo"         { default = "https://norepo" }
variable "git_revision"     { default = "000000" }
variable "aws_profile"      { }
variable "aws_creds"        { default = "~/.aws/credentials" }
variable "env_name"         { }
variable "public_subnets" { }
variable "private_subnets" { }
variable "db_username_prefix" { }
variable "acm_certificate_arn" { }
variable "ssh_key" { }
variable "ecs_ec2_cluster_minmax" { }
variable "ecs_ec2_ami" { }
variable "ecs_ec2_instance_size" { }
variable "revision"         { }
variable "ds_integration_role_arn" { }
variable "cc_content_ingestion_role_arn" { }
variable "amp_integration_bucket" { }
variable "teams_alarm_notification_endpoint" {}
variable "email_alarm_notification_list" {}
variable "pagerduty_alarm_notification_endpoint" {}
variable "cf_distribution" {}

variable "tags" {
    type="map"
}
locals {
  common_tags = {
    Name                  = "${var.app_family}-${var.app_name}-${var.env_name}"
    "tr:appName"          = "${var.app_family}-${var.app_name}"
    "tr:appFamily"        = "${var.app_family}"
    "tr:environment-type" = "${var.env_name}"
    terraform             = "devsng/pdf2xml-common-infra/deploy/terraform/continuous"
    git_repo              = "${var.git_repo}"
    git_revision          = "${var.git_revision}"
    singularity           = "true"
    revision              = "${var.revision}"
  }
}

variable "pingdom_cidr_blocks_list" {
  type        = "list"
  description = "pingdom IPs"

  default = [
    "10.10.2.46/12",
  ]
}
