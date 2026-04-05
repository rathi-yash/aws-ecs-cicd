#IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution" {
    name = "${var.app_name}-ecs-execution-role"

    #Trust policy - only ECS tasks can assume this role
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ecs-tasks.amazonaws.com"
                }
            }
        ]
    })

    tags = {
        Name = "${var.app_name}-ecs-execution-role"
    }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_policy_attachment" "ecs_task_execution" {
    name = "${var.app_name}-ecs-execution-policy"
    roles = [aws_iam_role.ecs_task_execution.name]
    policy_arn = "arn:aws:iam::aws:policy/AmazonECSTaskExecutionRolePolicy"
}