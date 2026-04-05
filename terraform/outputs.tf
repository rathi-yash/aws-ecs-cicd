output "alb_dns_name" {
    value = aws_lb.alb.dns_name
    description = "The DNS name of the load balancer - your app URL"
}

output "ecr_repository_url" {
    value = aws_ecr_repository.app.repository_url
    description = "ECR repository URL for pushing Docker images"
}