resource "aws_ecs_cluster" "main" {
    name = "${var.app_name}-cluster"

    tags = {
        Name = "${var.app_name}-cluster"
    }
}

resource "aws_ecs_task_definition" "app" {
    family = "${var.app_name}-task"
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu = 256
    memory = 512
    execution_role_arn = aws_iam_role.ecs_task_execution.arn

    container_definitions = jsonencode([{
        name = var.app_name
        image = "${aws_ecr_repository.app.repository_url}:latest"
        portMappings = [
            {
                containerPort = var.container_port
                protocol = "tcp"
            }
        ]
        logConfiguration = {
            logDriver = "awslogs"
            options = {
                "awslogs-group" = "/ecs/${var.app_name}"
                "awslogs-region" = var.aws_region
                "awslogs-stream-prefix" = "ecs"
            }
        }
    }])
}

# Service
resource "aws_ecs_service" "app" {
    name = "${var.app_name}-service"
    cluster = aws_ecs_cluster.main.id
    task_definition = aws_ecs_task_definition.app.arn
    desired_count = 1
    launch_type = "FARGATE"

    network_configuration {
        subnets = [aws_subnet.public_a.id, aws_subnet.public_b.id]
        security_groups = [aws_security_group.ecs.id]
        assign_public_ip = true
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.app.arn
        container_name = var.app_name
        container_port = var.container_port
    }
}