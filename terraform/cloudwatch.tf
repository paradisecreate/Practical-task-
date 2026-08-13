resource "aws_cloudwatch_metric_alarm" "jenkins_cpu_high" {
  alarm_name        = "team2-jenkins-high-cpu"
  alarm_description = "Jenkins EC2 CPU usage is above 80 percent"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  statistic = "Average"

  # Check average CPU every 5 minutes.
  period = 300

  # Alarm after 2 consecutive periods (10 minutes total).
  evaluation_periods = 2

  # CPU usage threshold: 80%.
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    InstanceId = aws_instance.devops_server.id
  }

  treat_missing_data = "missing"

  tags = {
    Project   = "PracticalTask"
    Component = "Jenkins"
    ManagedBy = "Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "jenkins_status_check_failed" {
  alarm_name        = "team2-jenkins-status-check-failed"
  alarm_description = "Jenkins EC2 failed an AWS status check"

  namespace   = "AWS/EC2"
  metric_name = "StatusCheckFailed"

  statistic = "Maximum"

  # Check EC2 status every 60 seconds.
  period = 60

  # Require 2 failed checks before entering ALARM state.
  evaluation_periods = 2

  # StatusCheckFailed = 1 means AWS detected an EC2 health problem.
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    InstanceId = aws_instance.devops_server.id
  }

  treat_missing_data = "missing"

  tags = {
    Project   = "PracticalTask"
    Component = "Jenkins"
    ManagedBy = "Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "jenkins_memory_high" {
  alarm_name        = "team2-jenkins-high-memory"
  alarm_description = "Jenkins EC2 memory usage is above 85 percent"

  namespace   = "Team2/EC2"
  metric_name = "mem_used_percent"

  statistic = "Average"

  # CloudWatch Agent publishes memory metrics every 60 seconds.
  period = 60

  # Alarm after 3 consecutive high-memory periods (3 minutes).
  evaluation_periods = 3

  # Memory usage threshold: 85%.
  threshold           = 85
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    InstanceId = aws_instance.devops_server.id
  }

  treat_missing_data = "missing"

  tags = {
    Project   = "PracticalTask"
    Component = "Jenkins"
    ManagedBy = "Terraform"
  }
}

resource "aws_cloudwatch_dashboard" "team2" {
  dashboard_name = "Team2-DevOps-Capstone"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "text"

        # Dashboard uses a 24-column grid.
        x      = 0
        y      = 0
        width  = 24
        height = 2

        properties = {
          markdown = "# Team 2 DevOps Capstone Monitoring\nJenkins EC2 infrastructure monitoring"
        }
      },

      {
        type = "metric"

        # Left half of the 24-column dashboard.
        x      = 0
        y      = 2
        width  = 12
        height = 6

        properties = {
          title  = "Jenkins EC2 CPU Usage"
          region = "eu-west-1"
          view   = "timeSeries"

          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "InstanceId",
              aws_instance.devops_server.id
            ]
          ]

          # Display 5-minute CPU averages.
          stat   = "Average"
          period = 300

          # CPU percentage range.
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },

      {
        type = "metric"

        # Right half of the dashboard.
        x      = 12
        y      = 2
        width  = 12
        height = 6

        properties = {
          title  = "Jenkins EC2 Memory Usage"
          region = "eu-west-1"
          view   = "timeSeries"

          metrics = [
            [
              "Team2/EC2",
              "mem_used_percent",
              "InstanceId",
              aws_instance.devops_server.id
            ]
          ]

          # Display 1-minute memory averages.
          stat   = "Average"
          period = 60

          # Memory percentage range.
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },

      {
        type = "metric"

        x      = 0
        y      = 8
        width  = 12
        height = 6

        properties = {
          title  = "Jenkins EC2 Disk Usage"
          region = "eu-west-1"
          view   = "timeSeries"

          metrics = [
            [
              {
                # Find disk metrics for the current Jenkins EC2 dynamically.
                expression = "SEARCH('{Team2/EC2,InstanceId,device,fstype,path} MetricName=\"disk_used_percent\" InstanceId=\"${aws_instance.devops_server.id}\"', 'Average', 60)"
                label      = "Root filesystem usage"
                id         = "disk1"
              }
            ]
          ]

          # Disk percentage range.
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },

      {
        type = "metric"

        x      = 12
        y      = 8
        width  = 12
        height = 6

        properties = {
          title  = "EC2 Status Checks"
          region = "eu-west-1"
          view   = "timeSeries"

          metrics = [
            [
              "AWS/EC2",
              "StatusCheckFailed",
              "InstanceId",
              aws_instance.devops_server.id
            ]
          ]

          # Status checks are evaluated every 60 seconds.
          stat   = "Maximum"
          period = 60
        }
      },

      {
        type = "metric"

        x      = 0
        y      = 14
        width  = 12
        height = 6

        properties = {
          title  = "Jenkins Pipeline Results"
          region = "eu-west-1"
          view   = "timeSeries"

          metrics = [
            [
              {
                # Count successful Jenkins builds in 1-minute periods.
                expression = "SEARCH('{Team2/Jenkins,BuildNumber} MetricName=\"PipelineSuccess\"', 'Sum', 60)"
                label      = "Successful pipelines"
                id         = "success1"
              }
            ],
            [
              {
                # Count failed Jenkins builds in 1-minute periods.
                expression = "SEARCH('{Team2/Jenkins,BuildNumber} MetricName=\"PipelineFailure\"', 'Sum', 60)"
                label      = "Failed pipelines"
                id         = "failure1"
              }
            ]
          ]
        }
      }
    ]
  })
}