# DevOps — EC2 Deployment Guide

This folder contains the **Terraform** and **Ansible** files to fully provision and configure an EC2 instance running **Minikube + Jenkins** for the Time Scheduler app.

---

## Architecture

```
Your Machine  ──(terraform apply)──►  AWS EC2 (t3.medium)
                                          │
              ──(ansible playbook)──►     ├── Docker
                                          ├── Minikube (inside Docker)
                                          ├── kubectl
                                          ├── Jenkins (port 8080)
                                          ├── Maven + Node.js
                                          └── minikube-tunnel (systemd) → port 80
```

---

## Prerequisites (on your local machine)

- `terraform` >= 1.5
- `ansible` >= 2.14
- AWS CLI configured (`aws configure`)
- An SSH key pair at `~/.ssh/id_rsa` + `~/.ssh/id_rsa.pub`

---

## Step 1 — Terraform (Provision EC2)

```bash
cd devops/terraform

# Initialize Terraform
terraform init

# Preview what will be created
terraform plan

# Create the EC2 instance
terraform apply
```

After `apply`, Terraform will:
- Create an EC2 `t3.medium` instance
- Attach an Elastic IP (stable across reboots)
- Open ports 22, 80, 443, 8080
- **Auto-generate** `devops/ansible/inventory.ini` with the correct IP

---

## Step 2 — Ansible (Configure EC2)

```bash
cd devops/ansible

# Wait ~60s after Terraform apply for EC2 to be SSH-ready, then:
ansible-playbook -i inventory.ini playbook.yml
```

Ansible will install and configure:
| Tool        | Purpose                          |
|-------------|----------------------------------|
| Docker      | Minikube driver + container runtime |
| Minikube    | Local Kubernetes cluster on EC2  |
| kubectl     | Talk to the Minikube cluster     |
| Jenkins     | CI/CD pipeline                   |
| Maven       | Backend build (Spring Boot)      |
| Node.js 20  | Frontend build (Vite/React)      |

It will also:
- Start Minikube and enable the **ingress addon**
- Copy kubeconfig to Jenkins home so `kubectl` works in pipelines
- Create a **systemd service** for `minikube tunnel` (exposes port 80 on the EC2 host)
- Print the **Jenkins initial admin password** at the end

---

## Step 3 — Jenkins Setup

1. Open `http://<EC2-PUBLIC-IP>:8080`
2. Paste the initial admin password printed by Ansible
3. Install suggested plugins
4. Add credentials:
   - **`dockerhub-creds`** — Docker Hub username + password
5. Create a Pipeline job pointing to this repo's `Jenkinsfile`

---

## Step 4 — First Deployment

Run the Jenkins pipeline. It will:
1. Build backend (Maven) and frontend (npm)
2. Build Docker images and push to Docker Hub
3. Deploy to the Minikube cluster via `kubectl set image`

Your app will be live at: `http://<EC2-PUBLIC-IP>`

---

## Customizing Variables

Edit `devops/terraform/variables.tf` to change:
- `instance_type` (default: `t3.medium`)
- `aws_region` (default: `us-east-1`)
- `ami_id` (update if using a different region)
- `allowed_ssh_cidr` (restrict to your IP for security)

---

## Teardown

```bash
cd devops/terraform
terraform destroy
```

## Do this once
```
Manage Jenkins → Configure System → SonarQube servers

Name: SonarQube (must match exactly)
URL: http://localhost:9000
Token: Generate one in SonarQube UI → My Account → Security
```