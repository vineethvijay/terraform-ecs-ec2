# A CloudWatch alarm that monitors memory utilization of containers for scaling up

resource "aws_cloudwatch_metric_alarm" "appserver_memory_high" {
  alarm_name = "appserver-memory-utilization-above-80"
  alarm_description = "This alarm monitors appserver memory utilization for scaling up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name = "MemoryUtilization"
  namespace = "AWS/ECS"
  evaluation_periods = "1"
  period = "120"
  statistic = "Average"
  threshold = "80"
  alarm_actions = ["${aws_appautoscaling_policy.app_scale_up.arn}"]

  dimensions {
    ClusterName = "${aws_ecs_cluster.ecs_cluster.name}"
    ServiceName = "${aws_ecs_service.ecs-service.name}"
  }
}

# A CloudWatch alarm that monitors memory utilization of containers for scaling down
resource "aws_cloudwatch_metric_alarm" "appserver_memory_low" {
  alarm_name = "appserver-memory-utilization-below-5"
  alarm_description = "This alarm monitors appserver memory utilization for scaling down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = "1"
  metric_name = "MemoryUtilization"
  namespace = "AWS/ECS"
  period = "60"
  statistic = "Average"
  threshold = "5"
  alarm_actions = ["${aws_appautoscaling_policy.app_scale_down.arn}"]

  dimensions {
    ClusterName = "${aws_ecs_cluster.ecs_cluster.name}"
    ServiceName = "${aws_ecs_service.ecs-service.name}"
  }
}

resource "aws_appautoscaling_target" "target" {
  resource_id = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs-service.name}"
  role_arn = "${aws_iam_role.ecs-service-role.arn}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
  min_capacity = "${var.app_min_capacity}"
  max_capacity = "${var.app_max_capacity}"
}


resource "aws_appautoscaling_policy" "app_scale_up" {
  name = "appserver-scale-up"
  resource_id = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = ["aws_appautoscaling_target.target"]
}

resource "aws_appautoscaling_policy" "app_scale_down" {
  name = "appserver-scale-down"
  resource_id = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
  depends_on = ["aws_appautoscaling_target.target"]
}