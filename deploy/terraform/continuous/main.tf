#----------------------------------------
# Import lastest chetan_motors CIDR lists
#----------------------------------------
module "chetan_motors_cidr_blocks" {
  source = "../../../../cc-terraform-modules/chetan_motors_cidr_blocks"
}

#----------------------------------------
# KMS Key
#----------------------------------------
resource "aws_kms_key" "kms_key" {
  description             = "${var.app_family}-${var.app_name} ${var.env_name} Key"
  description             = "${var.app_family}-${var.app_name} ${var.env_name} Key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "IAM specific Policy",
    "Statement": [
        {
            "Sid": "Enable Specific IAM Role Full Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                  "arn:aws:iam::${var.account_id}:role/cl/sso/chetan_motors_superadmin",
                  "arn:aws:iam::${var.account_id}:role/cl/app/crossaccount/JenkinsDeploy"
                ]
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
          "Sid": "Enable Specific IAM Role encrypt and decrypt Permissions",
          "Effect": "Allow",
          "Principal": {
            "AWS": [
              "${aws_iam_role.ecs_container_role.arn}"
            ]
          },
          "Action": [
            "kms:DescribeKey",
            "kms:GenerateDataKey*",
            "kms:Encrypt",
            "kms:ReEncrypt*",
            "kms:Decrypt"
          ],
          "Resource": "*"
        }
    ]
}
POLICY

  tags = "${merge(
    local.common_tags,
    var.tags,
    map("Name", "${var.app_family}-${var.app_name}-${var.env_name}"),
    map("tr:role", "kms"),
  )}"
}

# common ecs task role
resource "aws_iam_role" "ecs_container_role" {
    name               = "ecs-${var.app_family}-${var.app_name}-${var.env_name}-role"
    path               = "/cl/app/${var.app_family}/"
    assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ecs-tasks.amazonaws.com",
          "ecs.amazonaws.com",
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

#----------------------------------------
# ECS security-group
#----------------------------------------
resource "aws_security_group" "ecs_container_security_group" {
  name        = "ecs-${var.app_family}-${var.app_name}-${var.env_name}"
  description = "Outbound Traffic Only"
  vpc_id      = "${data.aws_vpc.vpc.id}"

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

}

#----------------------------------------
# ALB for ECS Services
#----------------------------------------
resource "aws_alb" "ecs_load_balancer" {
  name            = "${var.app_family}-${var.app_name}-${var.env_name}"
  security_groups = ["${aws_security_group.lb-sg0.id}","${aws_security_group.lb-sg1.id}","${aws_security_group.lb-sg2.id}","${aws_security_group.lb-sg3.id}"]
  subnets         = "${split(",","${var.public_subnets}")}"
  internal        = false
  idle_timeout    = 600

  access_logs {
    bucket  = "${var.account_name}-logging"
    prefix  = "${var.app_family}/${var.env_name}/common-infra/lb"
    enabled = true
  }

  tags = "${merge(
    local.common_tags,
    var.tags,
    map("Name", "${var.app_family}-${var.app_name}-${var.env_name}"),
    map("tr:role", "alb"),
  )}"
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = "${aws_alb.ecs_load_balancer.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Bad Path"
      status_code  = "200"
    }
  }
}

#----------------------------------------
# RDS configuration
#----------------------------------------
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier              = "${var.app_family}-${var.app_name}-${var.env_name}"
  engine                          = "aurora-postgresql"
  database_name                   = "cvtdb"
  master_username                 = "${aws_ssm_parameter.rds_master_username.value}"
  master_password                 = "${random_password.master_password.result}"
  backup_retention_period         = 14
  preferred_backup_window         = "02:00-03:00"
  preferred_maintenance_window    = "wed:03:00-wed:04:00"
  db_subnet_group_name            = "${aws_db_subnet_group.aurora_subnet_group.id}"
  db_cluster_parameter_group_name = "${aws_rds_cluster_parameter_group.aurora_cluster_parameter_group.id}"
  final_snapshot_identifier       = "${var.app_name}-${var.env_name}-${replace(replace(timestamp(),"T","-"),":","-")}"
  vpc_security_group_ids          = ["${aws_security_group.aurora_cluster_security_group.id}"]
  deletion_protection             = true

  tags = "${merge(
    local.common_tags,
    var.tags,
    map("Name", "${var.app_name}-${var.env_name}"),
    map("tr:role", "rds"),
  )}"

  lifecycle {
    ignore_changes  = ["final_snapshot_identifier", "master_password"]
    prevent_destroy = true
  }
}

resource "aws_rds_cluster_parameter_group" "aurora_cluster_parameter_group" {
  name        = "${var.app_family}-${var.app_name}-${var.env_name}"
  family      = "aurora-postgresql10"
  description = "RDS postgresql10 cluster parameter group"

  parameter {
    name  = "tcp_keepalives_idle"
    value = "7200"
  }
  parameter {
    name  = "tcp_keepalives_interval"
    value = "3"
  }
  parameter {
    name  = "tcp_keepalives_count"
    value = "1024"
  }
  tags = "${merge(
    local.common_tags,
    var.tags,
    map("Name", "${var.app_family}-${var.app_name}-${var.env_name}"),
    map("tr:role", "rds-parameter-group"),
  )}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "aurora_cluster_security_group" {
  name        = "${var.app_family}-${var.app_name}-${var.env_name}-db"
  description = "Allow traffic for PostgreSQL"
  vpc_id      = "${data.aws_vpc.vpc.id}"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["${var.jenkins_cidr}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = "${merge(
    local.common_tags,
    var.tags,
    map("Name", "rds-${var.app_family}-${var.app_name}-${var.env_name}"),
    map("tr:role", "sg"),
  )}"

  lifecycle {
    create_before_destroy = true
  }
}

#----------------------------------------
# SQS Queues
#----------------------------------------
resource "aws_sqs_queue" "cps_input_queue" {
  name                      = "chetan_motors-ocr-cps-input-queue-${var.env_name}"
  visibility_timeout_seconds = 3600

  tags = "${merge(
    local.common_tags,
    var.tags,
    map("Name", "${var.app_family}-${var.app_name}-${var.env_name}"),
    map("tr:role", "sqs"),
  )}"
}

resource "aws_sqs_queue_policy" "cps_input_queue_policy" {
  queue_url = "${aws_sqs_queue.cps_input_queue.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "chetan_motorssqs",
  "Statement": [
    {
      "Sid": "contentingestionintegration",
      "Effect": "Allow",
      "Principal": {
        "AWS": [ "${var.cc_content_ingestion_role_arn}" ]
      },
      "Action": [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage"
      ],
      "Resource": "${aws_sqs_queue.cps_input_queue.arn}"
    }
  ]
}
POLICY
}

#----------------------------------------
# SSM configuration
#----------------------------------------

resource "aws_ssm_parameter" "rds_endpoint" {
  type  = "String"
  name  = "/${var.app_family}/${var.app_name}/rds/${var.env_name}/endpoint"
  value = "${aws_rds_cluster.aurora_cluster.endpoint}"

  tags = "${merge(
    local.common_tags,
    var.tags,
    map("Name", "${var.app_family}-${var.app_name}-${var.env_name}"),
    map("tr:role", "param"),
  )}"
}

resource "aws_ssm_parameter" "rds_master_username" {
  type  = "SecureString"
  name  = "/${var.app_family}/${var.app_name}/rds/${var.env_name}/master_username"
  value = "${var.db_username_prefix}_dba"
  key_id  = "${aws_kms_key.kms_key.key_id}"

  tags = "${merge(
    local.common_tags,
    var.tags,
    map("Name", "${var.app_family}-${var.app_name}-${var.env_name}"),
    map("tr:role", "param"),
  )}"
}

resource "aws_ssm_parameter" "rds_master_password" {
  type    = "SecureString"
  name    = "/${var.app_family}/${var.app_name}/rds/${var.env_name}/master_password"
  value   = "${random_password.master_password.result}"
  key_id  = "${aws_kms_key.kms_key.key_id}"

  tags = "${merge(
    local.common_tags,
    var.tags,
    map("Name", "${var.app_family}-${var.app_name}-${var.env_name}"),
    map("tr:role", "param"),
  )}"
}


resource "aws_ssm_parameter" "rds_app_username" {
  type  = "SecureString"
  name  = "/${var.app_family}/${var.app_name}/rds/${var.env_name}/app_username"
  value = "${var.db_username_prefix}_app_user"
  key_id  = "${aws_kms_key.kms_key.key_id}"

  tags = "${merge(
    local.common_tags,
    var.tags,
    map("Name", "${var.app_family}-${var.app_name}-${var.env_name}"),
    map("tr:role", "param"),
  )}"
}

resource "aws_ssm_parameter" "rds_app_password" {
  type    = "SecureString"
  name    = "/${var.app_family}/${var.app_name}/rds/${var.env_name}/app_password"
  value   = "${random_password.app_password.result}"
  key_id  = "${aws_kms_key.kms_key.key_id}"

  tags = "${merge(
    local.common_tags,
    var.tags,
    map("Name", "${var.app_family}-${var.app_name}-${var.env_name}"),
    map("tr:role", "param"),
  )}"
}

resource "aws_ssm_parameter" "rds_readonly_username" {
  type  = "SecureString"
  name  = "/${var.app_family}/${var.app_name}/rds/${var.env_name}/readonly_username"
  value = "${var.db_username_prefix}_ro"
  key_id  = "${aws_kms_key.kms_key.key_id}"

  tags = "${merge(
    local.common_tags,
    var.tags,
    map("Name", "${var.app_family}-${var.app_name}-${var.env_name}"),
    map("tr:role", "param"),
  )}"
}

resource "aws_ssm_parameter" "rds_readonly_password" {
  type    = "SecureString"
  name    = "/${var.app_family}/${var.app_name}/rds/${var.env_name}/readonly_password"
  value   = "${random_password.readonly_password.result}"
  key_id  = "${aws_kms_key.kms_key.key_id}"

  tags = "${merge(
    local.common_tags,
    var.tags,
    map("Name", "${var.app_family}-${var.app_name}-${var.env_name}"),
    map("tr:role", "param"),
  )}"
}

resource "random_password" "master_password" {
  length = 16
  special = false
  override_special = "/@\" "
}

resource "random_password" "app_password" {
  length = 16
  special = false
  override_special = "/@\" "
}

resource "random_password" "readonly_password" {
  length = 16
  special = false
  override_special = "/@\" "
}


#----------------------------------------
# terraform backend stub - DO NOT MODIFY
#----------------------------------------
terraform {
  required_version = "0.12.6"

  backend "s3" {
    bucket         = "unset"
    key            = "chetan_motors/common/unset.tfstate"
    region         = "unset"
    dynamodb_table = "unset"
  }
}
