resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-app-lt-${var.environment}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  
  vpc_security_group_ids = [var.app_security_group_id]

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 20
      volume_type = "gp3"
      encrypted   = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-app-instance-${var.environment}"
      Tier = "app"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name_prefix         = "${var.project_name}-app-asg-${var.environment}-"
  vpc_zone_identifier = var.private_subnet_ids
  
  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size

 # Mixed instances policy with spot
  mixed_instances_policy {
    instances_distribution {
      # Always have 2 on-demand instances minimum
      on_demand_base_capacity = var.on_demand_base_capacity
      
      # Beyond base, 20% on-demand, 80% spot
      on_demand_percentage_above_base_capacity = var.on_demand_percentage
      
      # Use capacity-optimized for best availability
      spot_allocation_strategy = "capacity-optimized"
      
      # Try multiple instance pools
      spot_instance_pools = var.spot_instance_pools
    }

 launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.app.id
        version            = "$Latest"
      }

      # Multiple instance type options for spot diversity
      dynamic "override" {
        for_each = var.instance_types
        content {
          instance_type = override.value
        }
      }
    }
  }
 health_check_type         = "ELB"
  health_check_grace_period = 300
  
  target_group_arns = [var.app_target_group_arn]

  # Protect new instances from scale-in for 5 minutes
  protect_from_scale_in = true

  # Instance refresh for zero-downtime deployments
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app-instance-${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "app"
    propagate_at_launch = true
  }

  tag {
    key                 = "Spot"
    value               = "mixed"
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      desired_capacity
    ]
  }
}

# Target Tracking Scaling Policy
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${var.project_name}-cpu-tracking-${var.environment}"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.app.name
  
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    
    target_value = var.cpu_target_value  
    
  
  }
}