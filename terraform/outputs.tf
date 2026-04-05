output "alb_dns_name" {
    value = aws_lb.main.dns_name
    description = "The DNS name of the load balancer - your app URL"
}

output "ecr_repository_url" {
    value = aws_ecr_reposiotry.app.repository_url
    description = "ECR reposiotry URL for pushing Docker images"
}