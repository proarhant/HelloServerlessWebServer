# Hello Serverless WebServer
AWS Serverless architecture deployed with Terraform.
## URL
http://app-lb-493631137.ap-southeast-2.elb.amazonaws.com/hello

```
module.ecs_fargate.aws_cloudwatch_metric_alarm.cpu_low[0]: Creation complete after 0s [id=project-ecs-cluster-cpu-low]

Apply complete! Resources: 49 added, 0 changed, 0 destroyed.

Outputs:

alb_dnsname = "app-lb-493631137.ap-southeast-2.elb.amazonaws.com"
ecs_cluster_name = "project-ecs-cluster"
❯ curl -i  -w  '\n' http://app-lb-493631137.ap-southeast-2.elb.amazonaws.com/hello
HTTP/1.1 200 OK
Date: Sun, 22 Jun 2025 22:53:19 GMT
Content-Type: text/plain
Transfer-Encoding: chunked
Connection: keep-alive

OK
❯ curl -i  -w  '\n' http://app-lb-493631137.ap-southeast-2.elb.amazonaws.com/helloNOTfound
HTTP/1.1 404 Not Found
Server: awselb/2.0
Date: Sun, 22 Jun 2025 22:53:34 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 185
Connection: keep-alive

The endpoint you are attempting to access is either unavailable or does not exist.

Please verify the URL and try again, or contact your account manager if you believe this is an error.
```
<img width="1321" alt="image" src="https://github.com/user-attachments/assets/67240cab-5f7e-44ce-bbe6-0f4508e2c41f" />

## Design Decisions

In making architectural decisions, I considered the following hint provided in the brief document:

> “Lambda, Elastic Beanstalk and Kubernetes are quick to set up, but may not show off as much skill as other techniques”

With this in mind, I explored the trade-offs between using **API Gateway** and an **Application Load Balancer (ALB)** for a serverless, container-based API architecture. I also evaluated a combination of **ECS**, **API Gateway**, and **ALB** as part of the design options.

Ultimately, for our use case, my goal was to deliver a solution that strikes a balance between **technical credibility**, **cost efficiency**, and **avoiding unnecessary complexity**.

For our use case, I believe that an **Application Load Balancer (ALB)** integrated with **AWS WAF** and backed by **ECS Fargate** is a strong candidate for hosting a web API capable of serving one million users per month.

In a production-grade environment, additional AWS services such as **AWS Certificate Manager**, **CloudFront**, **Secrets Manager**, **SNS**, **Cognito**, **RDS or DynamoDB**, and **EBS/EFS** should be considered to ensure the API is **secure**, **scalable**, and **highly performant**.

## References

- **Field Notes: Serverless Container-based APIs with Amazon ECS and Amazon API Gateway**  
  https://aws.amazon.com/blogs/architecture/field-notes-serverless-container-based-apis-with-amazon-ecs-and-amazon-api-gateway/

- **Theoretical Cost Optimization by Amazon ECS Launch Type: Fargate vs EC2**  
  https://aws.amazon.com/de/blogs/containers/theoretical-cost-optimization-by-amazon-ecs-launch-type-fargate-vs-ec2/

## Assumptions
Since SSL implementation was **not mandatory** for this scenario, I did not purchase a custom domain in order to keep costs low.  
I also **time-boxed the completion** of this project to focus on delivering a functional and maintainable solution within a defined time frame.

I followed best practices throughout the implementation, including writing **modular Terraform code** for the ECS Fargate component, integrating **security with AWS WAF**, using **least privilege IAM roles**, enabling **monitoring via CloudWatch**, and designing a **scalable architecture**.

For this demo deployment, I intentionally did **not use a remote Terraform state backend** to simplify testing and allow others to deploy easily. The local environment only requires **Terraform**, **Docker**, and **Git** to get started. The command `terraform apply` will build and push the docker image to the ECR.

# AWS Architecture Description

## Components

### Global
- 🌐 **Internet** → 🛡️ **AWS WAF** (Web ACL with geo-blocking & rate limiting rules)

### Networking
- 🏢 **VPC** (172.17.0.0/16)
  - **Public Subnets** (2 AZs):
    - 🚪 Internet Gateway
    - ⚡ NAT Gateways (2)
  - **Private Subnets** (2 AZs):
    - 🔒 Route Tables

### Load Balancing
- **Application Load Balancer** (HTTP:80)
  - 🎯 Target Group (port 8080)
  - 🔐 Security Group (Allow 80 from 0.0.0.0/0)
  - 🎚️ Listener Rules:
    - `/hello` → Target Group
    -  Default → Notification message

### Container Services
- 📦 **ECR Repository** (Lifecycle Policy: retain last 2 images)
- 🚢 **ECS Fargate**:
  - 🏗️ Task Definition (256 CPU / 512MB)
  - ⚙️ Service (2-4 tasks):
    - 🖥️ Task 1 (AZ1, CPU: 78%)
    - 🖥️ Task 2 (AZ2, CPU: 82%)
    - 🆕 Task 3* (scaled instance)

### Monitoring & Scaling
- 📊 **CloudWatch**:
  - ⚠️ Alarm: HighCPU (>80% for 3m) → Scale Out (+1 task)
  - ⚠️ Alarm: LowCPU (<20% for 5m) → Scale In (-1 task)
- ↔️ **Auto Scaling** (CPU-based)

## Data Flow
1. User → Internet → WAF → ALB → Target Group → ECS Tasks
2. Tasks monitor CPU → CloudWatch → Auto Scaling adjusts count


# AWS Monthly Cost Estimate (Sydney - ap-southeast-2)
## Handling 1 Million Requests

### Total Cost: **$126.81 USD**

## Service Breakdown

| Service                | Configuration                          | Cost/Month (USD) | Notes |
|------------------------|----------------------------------------|------------|-------|
| **ECS Fargate**        | 2 tasks (0.25vCPU/0.5GB) always-on    | $20.08     | [$0.01375/hr per task](https://aws.amazon.com/fargate/pricing/) |
| **Application LB**     | 1 ALB + 1 LCU                         | $17.23     | $16.43 base + $0.80 requests |
| **NAT Gateway**        | 2 NATs (1 per AZ)                     | $65.70     | [$0.045/hr per NAT](https://aws.amazon.com/vpc/pricing/) |
| **WAF**                | Web ACL + 2 rules                     | $7.60      | $5 ACL + $2 rules + $0.60 requests |
| **ECR Storage**      | 100MB (3 container images)            | $0.01              |
| **ECR Storage**        | 100MB (3 images)                      | $0.01      | Free tier covers 500MB |
| **CloudWatch**         | 5GB logs + 2 alarms                   | $1.50      | [$0.30/GB logs](https://aws.amazon.com/cloudwatch/pricing/) + $0.60 alarms |
| **Data Transfer**      | 1GB NAT + 1GB ALB                     | $0.12      | [$0.09/GB NAT](https://aws.amazon.com/vpc/pricing/) + [$0.023/GB ALB](https://aws.amazon.com/elasticloadbalancing/pricing/) |

## Architecture Diagram  (generated using Mermaid Code)
Code is placed in this location: 
(https://github.com/proarhant/HelloServerlessWebServer/blob/main/architecture/ArchitectureMermaidDiagram.mmd?short_path=44945db)

```mermaid
graph TD
    classDef module fill:#e9f5ec,stroke:#1a9850,stroke-width:2px
    classDef aws fill:#dfeaf5,stroke:#2171b5,stroke-width:2px
    classDef alarm fill:#fff2cc,stroke:#f1c232,stroke-width:2px
    classDef scale fill:#d5e8d4,stroke:#82b366,stroke-width:2px

    subgraph AWS["AWS Cloud"]
        subgraph Net["Networking"]
            VPC["VPC<br/>172.17.0.0/16"]
            IG["Internet Gateway"]
            Public["Public Subnets<br/>(2 AZs)"]
            Private["Private Subnets<br/>(2 AZs)"]
            NAT["NAT Gateways<br/>(2 AZs)"]
            RT["Route Tables"]
        end

        subgraph ALB["Load Balancing"]
            LB["Application Load Balancer"]
            TG["Target Group<br/>port 8080"]
            SG_LB["Security Group<br/>Allow 80 from Internet"]
            L_Rule["Listener Rule<br/>GET /hello → Target Group"]
            NoMatch["Default Rule<br/>All Other Requests → Alert Message"]
        end

        subgraph ECR["Container Registry"]
            Repo["ECR Repository"]
            LC["Lifecycle Policy<br/>(2 days retention)"]
        end

        subgraph modECS["ECS Fargate Module"]
            class modECS module
            Cluster["ECS Cluster"]
            TaskDef["Task Definition<br/>256 CPU / 512 MB"]
            Service["ECS Service<br/>2-4 replicas"]
            Task1["Task Replica 1<br/>CPU: 78%"]
            Task2["Task Replica 2<br/>CPU: 82%"]
            Task3("Task Replica 3*"):::scale
            
            ASG["Auto Scaling<br/>CPU-based"]
            SG_ECS["Security Group<br/>Allow 8080 from ALB"]
            
            subgraph CW["CloudWatch"]
                HighCPU("HighCPU Alarm<br/>>75% for 10m"):::alarm
                LowCPU("LowCPU Alarm<br/><10% for 15m"):::alarm
            end
            
            %% Metric Flow
            Task1 -->|CPU| HighCPU
            Task2 -->|CPU| HighCPU
            Task1 -->|CPU| LowCPU
            
            %% Scaling Triggers
            HighCPU -->|Trigger| ASG
            LowCPU -->|Trigger| ASG
            ASG -->|Scale Out| Service
            ASG -->|Scale In| Service
            Service --> Task3
        end
        
        Internet((Internet))
        WAF["AWS WAF<br/>Web ACL"]
        App["Node.js App<br/>on port 8080"]
        
        Internet -->|"HTTP<br/>Port 80"| WAF
        WAF --> LB
        LB -->|GET /hello| TG
        LB -->|Other requests| NoMatch
        TG --> Service
        Service --> Task1
        Service --> Task2
        Task1 --> App
        Task2 --> App
        Task3 --> App
        TaskDef --> Task1
        TaskDef --> Task2
        TaskDef --> Task3
        ECR --> TaskDef
        IG --> Public
        Public --> NAT
        NAT --> Private
        Private --> SG_ECS
        Public --> LB
    end

    class VPC,IG,Public,Private,NAT,RT aws
    class LB,TG,SG_LB,L_Rule,NoMatch,WAF aws
    class Repo,LC aws
    class Cluster,TaskDef,Service,Task1,Task2,ASG,SG_ECS,CW aws
    
    %% Legend
    subgraph Legend[" "]
        direction TB
        awsbox[AWS Resource]:::aws
        modbox[Module]:::module
        alarmbox[Alarm]:::alarm
        scalebox[Scaled Task]:::scale
    end

