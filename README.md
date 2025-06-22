# Hello Serverless WebServer
AWS Serverless architecture deployed with Terraform.

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
Code is placed in this location: (https://github.com/proarhant/HelloServerlessWebServer/blob/main/architecture/ArchitectureMermaidDiagram.mmd)

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
