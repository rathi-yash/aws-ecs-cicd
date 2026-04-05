# AWS ECS CI/CD Pipeline

Automated deployment of a containerized Flask app on AWS ECS Fargate using Terraform and GitHub Actions.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                      CI / CD                        │
│                                                     │
│   Push to GitHub (main)                             │
│          │                                          │
│          ▼                                          │
│   GitHub Actions (workflow triggers)                │
│          │                                          │
│          ▼                                          │
│   Build Docker image                                │
│          │                                          │
│          ▼                                          │
│   Push to ECR  ◄── tagged with commit SHA           │
│          │                                          │
└──────────┼──────────────────────────────────────────┘
           │
┌──────────┼──────────────────────────────────────────┐
│          │   AWS — VPC (10.0.0.0/16)                │
│          │   us-east-1a + us-east-1b                │
│          ▼                                          │
│   ┌─────────────────┐      ┌──────────────────┐     │
│   │  ALB            │      │  IAM Role        │     │
│   │  port 80        │      │  ECS execution   │     │ 
│   └────────┬────────┘      └──────────────────┘     │
│            │                                        │
│            ▼                                        │
│   ┌─────────────────┐      ┌──────────────────┐     │
│   │  ECS Fargate    │◄─────│  ECR             │     │
│   │  0.25vCPU/512MB │pulls │  Docker image    │     │
│   └────────┬────────┘      └──────────────────┘     │
│            │                                        │
│            ▼                                        │
│   ┌─────────────────┐                               │
│   │  Security groups│                               │
│   │  ALB:0.0.0.0/0  │                               │
│   │  ECS: ALB only  │                               │
│   └────────┬────────┘                               │
│            │                                        │
│            ▼                                        │
│   ┌─────────────────┐                               │
│   │  CloudWatch     │                               │
│   │  Logs (7 days)  │                               │
│   └─────────────────┘                               │
└─────────────────────────────────────────────────────┘
```

All infrastructure is provisioned as code using Terraform.

## AWS Services Used

- **VPC** — isolated network with public subnets across 2 availability zones
- **ECS Fargate** — serverless container execution (no EC2 management)
- **ECR** — private Docker image registry
- **ALB** — public-facing load balancer with health checks
- **IAM** — least-privilege execution role for ECS tasks
- **CloudWatch** — container log storage and monitoring
- **Security Groups** — firewall rules isolating ALB and ECS traffic

## CI/CD Flow

On every push to `main`:
1. GitHub Actions builds a Docker image from `app/`
2. Image is tagged with the commit SHA and pushed to ECR
3. ECS service is force-redeployed with the new image
4. App is live at the ALB DNS URL within ~2 minutes

## Project Structure

```
aws-ecs-cicd/
├── app/
│   ├── app.py          # Flask application
│   └── Dockerfile      # Container definition
├── terraform/
│   ├── main.tf         # Provider config
│   ├── variables.tf    # Input variables
│   ├── outputs.tf      # ALB URL, ECR URL
│   ├── vpc.tf          # VPC, subnets, IGW, route tables
│   ├── ecr.tf          # ECR repository
│   ├── iam.tf          # ECS task execution role
│   ├── security_groups.tf  # ALB and ECS security groups
│   ├── alb.tf          # Load balancer, target group, listener
│   ├── ecs.tf          # Cluster, task definition, service
│   └── cloudwatch.tf   # Log group
└── .github/
    └── workflows/
        └── deploy.yml  # CI/CD pipeline
```

## Setup

### Prerequisites
- AWS CLI configured (`aws configure`)
- Terraform v1.0+
- Docker
- GitHub repository with Actions enabled

### GitHub Secrets Required
| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |

### Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Terraform will output the ALB URL and ECR repository URL after apply.

### First Image Push

Before GitHub Actions can deploy, push an initial image manually:

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ecr-url>
docker build -t flask-app ./app
docker tag flask-app:latest <ecr-url>/flask-app:latest
docker push <ecr-url>/flask-app:latest
```

After this, all future deployments are handled automatically via GitHub Actions.

### Destroy Infrastructure

```bash
cd terraform
terraform destroy
```

## Key Design Decisions

**Fargate over EC2** — no server management, pay only for container runtime, scales automatically.

**Public subnets across 2 AZs** — high availability, traffic continues if one availability zone has issues.

**ALB in front of ECS** — users never hit ECS directly, health checks automatically route away from unhealthy containers.

**Commit SHA as image tag** — every deployment is traceable back to a specific commit, makes rollbacks straightforward.

**Security groups layered** — ALB accepts traffic from the internet on port 80, ECS only accepts traffic from the ALB on port 5000. ECS is never directly exposed.