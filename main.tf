provider "aws" {
  profile = "apeunit"
  region  = "eu-central-1" # Setting my region to London. Use your own region here
}

locals {
  service_map = { for v in var.services_list : v.key => v }
}

resource "aws_ecr_repository" "kanvas_ecr_repos" {
  for_each = local.service_map
  name     = "${each.key}-ecr-repo"
}


resource "aws_ecs_cluster" "kanvas_ecs_cluster" {
  name = "kanvas-ecs-cluster" # Naming the cluster
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "kanvas_ecs_task" {
  for_each                 = local.service_map
  family                   = "${each.key}-task" # Naming our first task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "${each.key}-task",
      "image": "${aws_ecr_repository.kanvas_ecr_repos[each.key].repository_url}",
      "environment": [
        {"name": "SERVICE_ID", "value": "${each.key}"}
      ],
      "essential": true,
      "portMappings": [
        {
          "containerPort": ${each.value.port},
          "hostPort": ${each.value.port}
        }
      ],
      "memory": ${each.value.memory},
      "cpu": ${each.value.cpu}
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"]       # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"          # Using awsvpc as our network mode as this is required for Fargate
  memory                   = each.value.memory # Specifying the memory our container requires
  cpu                      = each.value.cpu    # Specifying the CPU our container requires
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}

resource "aws_ecs_service" "kanvas_ecs_service" {
  for_each        = local.service_map
  name            = "${each.key}-service"                                 # Naming our first service
  cluster         = aws_ecs_cluster.kanvas_ecs_cluster.id                 # Referencing our created Cluster
  task_definition = aws_ecs_task_definition.kanvas_ecs_task[each.key].arn # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 1
  force_new_deployment = true # Setting the number of containers to 3

  load_balancer {
    target_group_arn = aws_lb_target_group.kanvas_target_groups[each.key].arn # Referencing our target group
    container_name   = aws_ecs_task_definition.kanvas_ecs_task[each.key].family
    container_port   = each.value.port # Specifying the container port
  }

  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}", "${aws_default_subnet.default_subnet_c.id}"]
    assign_public_ip = true                                                # Providing our containers with public IPs
    security_groups  = ["${aws_security_group.service_security_group.id}"] # Setting the security group
  }
}


# Providing a reference to our default VPC
resource "aws_default_vpc" "default_vpc" {
}

# Providing a reference to our default subnets
resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "eu-central-1a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "eu-central-1b"
}

resource "aws_default_subnet" "default_subnet_c" {
  availability_zone = "eu-central-1c"
}

resource "aws_lb" "application_load_balancer" {
  name               = "kanvas-lb" # Naming our load balancer
  load_balancer_type = "application"
  subnets = [ # Referencing the default subnets
    "${aws_default_subnet.default_subnet_a.id}",
    "${aws_default_subnet.default_subnet_b.id}",
    "${aws_default_subnet.default_subnet_c.id}"
  ]
  # Referencing the security group
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}

# Creating a security group for the load balancer:
resource "aws_security_group" "load_balancer_security_group" {
  ingress {
    from_port   = 80 # Allowing traffic in from port 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
  }

  egress {
    from_port   = 0             # Allowing any incoming port
    to_port     = 0             # Allowing any outgoing port
    protocol    = "-1"          # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}


resource "aws_lb_target_group" "kanvas_target_groups" {
  for_each    = local.service_map
  name        = "${each.key}-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_default_vpc.default_vpc.id # Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path    = "/"
  }
}

resource "aws_lb_listener" "kanvas_lb_listeners" {
  for_each          = local.service_map
  load_balancer_arn = aws_lb.application_load_balancer.arn # Referencing our load balancer
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No routes defined"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_rule" "kanvas_lb_listener_rules" {
  for_each     = local.service_map
  listener_arn = aws_lb_listener.kanvas_lb_listeners[each.key].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kanvas_target_groups[each.key].arn
  }
  condition {
    path_pattern {
      values = ["/${each.key}*"]
    }
  }
}

resource "aws_security_group" "service_security_group" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  }

  egress {
    from_port   = 0             # Allowing any incoming port
    to_port     = 0             # Allowing any outgoing port
    protocol    = "-1"          # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}