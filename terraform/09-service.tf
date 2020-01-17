# The ECS Service role.
data "aws_iam_policy_document" "ecs-service-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

# Role with the policy
resource "aws_iam_role" "ecs-service-role" {
  name                = "ecs-service-role"
  path                = "/"
  assume_role_policy  = "${data.aws_iam_policy_document.ecs-service-policy.json}"
}

#Policy attachment
resource "aws_iam_role_policy_attachment" "ecs-service-role-attachment" {
  role       = "${aws_iam_role.ecs-service-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}


#IAM
resource "aws_iam_role" "ecs_task_role" {
  name = "tf_ecs_execution_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ecs.amazonaws.com",
          "ecs-tasks.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name = "ecs_execution_policy"
  role = "${aws_iam_role.ecs_task_role.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::zz-test-ecs-write-bucket"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::zz-test-ecs-write-bucket/*"]
    }
  ]
}
EOF
}


# The Nginx Service task.
resource "aws_ecs_task_definition" "nginx-service-task" {
  family                = "service"
  container_definitions = "${file("${path.module}/files/nginx-task.json")}"
  task_role_arn         = "${aws_iam_role.ecs_task_role.arn}"

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [${join(", ", keys(local.subnets))}]"
  }
}

# The Nginx Service.
resource "aws_ecs_service" "ecs-service" {
  name            = "ecs-service"
  cluster         = "${aws_ecs_cluster.ecs_cluster.id}"
  task_definition = "${aws_ecs_task_definition.nginx-service-task.arn}"
  desired_count   = 3
  iam_role        = "${aws_iam_role.ecs-service-role.name}"
  depends_on      = ["aws_iam_role.ecs-service-role"]

  load_balancer {
    target_group_arn = "${aws_alb_target_group.ecs_nodes_tg.arn}"
    container_name   = "nginx-image"
    container_port   = 8080
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [${join(", ", keys(local.subnets))}]"
  }
}

