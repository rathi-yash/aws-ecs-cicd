resource "aws_security_group" "alb" {
    name = "${var.app_name}-alb-sg"
    description = "Security group for load balancer"
    vpc_id = aws_vpc.main.id

    # Allow HTTP from anywhere
    ingress{
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow all outbound
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.app_name}-alb-sg"
    }
}

resource "aws_security_group" "ecs" {
    name = "${var.app_name}-ecs-sg"
    description = "Security group for ECS tasks"
    vpc_id = aws_vpn.main.id

    # Only Allow traffic from ALB on port 5000
    ingress {
        from_port = 5000
        to_port = 5000
        protocol = "tcp"
        security_groups = [aws_security_group.alb.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.app_name}-ecs-sg"
    }
}