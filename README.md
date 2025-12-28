# 🍓 Bare-Metal Kubernetes Cluster (RPi 5 + K3s)

A production-ready Kubernetes cluster running on bare-metal ARM64 hardware.
This project demonstrates **Infrastructure as Code (IaC)**, **Kernel Tuning**, and **GitOps** principles.

## 🏗️ Architecture Layout

The cluster follows a standard Control Plane / Data Plane architecture, managed remotely via a dedicated workstation.

```mermaid
graph TD
    subgraph "Management Zone"
        Laptop["ThinkPad T480s<br/>(Admin Station)"]
        style Laptop fill:#f9f,stroke:#333,stroke-width:2px
    end

    subgraph "Kubernetes Cluster (Private LAN)"
        subgraph "Control Plane"
            Master["k8s-master<br/>RPi 5 - 16GB"]
            APIServer["API Server :6443"]
            Master --- APIServer
            style Master fill:#bbf,stroke:#333,stroke-width:2px
        end

        subgraph "Data Plane (Workers)"
            W1["k8s-worker-1<br/>RPi 5 - 8GB"]
            W2["k8s-worker-2<br/>RPi 4 - 4GB"]
            
            Dashboard[Dashboard Pod]
            Apps[User Apps]
            
            W1 --- Dashboard
            W2 --- Apps
            style W1 fill:#bfb,stroke:#333,stroke-width:2px
            style W2 fill:#bfb,stroke:#333,stroke-width:2px
        end
    end

    %% Network Flows
    Laptop -->|SSH :22| Master
    Laptop ==>|"HTTPS :30000<br/>(NodePort Access)"| W1
    APIServer -.->|K3s Protocol| W1
    APIServer -.->|K3s Protocol| W2

    linkStyle default stroke-width:2px,fill:none;

⚙️ Hardware Bill of Materials (BOM)
Role	Hostname	Model	RAM	OS
Control Plane	k8s-master	Raspberry Pi 5	16GB	Debian Bookworm (Lite)
Worker	k8s-worker-1	Raspberry Pi 5	8GB	Debian Bookworm (Lite)
Worker	k8s-worker-2	Raspberry Pi 4B	4GB	Debian Bookworm (Lite)
Admin	ThinkPad-Lab	Lenovo T480s	16GB	Ubuntu Linux
🔧 Technical Deep Dive: Why we did this?
1. Kernel Hardening & Cgroups (The RPi 5 Issue)

The Problem: Raspberry Pi OS "Bookworm" (Debian 12) uses a recent Linux Kernel that creates a conflict with Container Runtimes (like containerd/K3s). By default, the memory cgroup controller is disabled.

The Symptom: Without fixing this, K3s fails to start, or Pods remain stuck in Pending state because the scheduler cannot read memory limits.

The Fix: We modified /boot/firmware/cmdline.txt to force-enable these controllers:
Plaintext

cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1

This allows the Kubernetes Kubelet to correctly track and limit resource usage per Pod.
2. Networking Strategy (NodePort vs Proxy)

Initially accessed via kubectl proxy (secure tunnel), we migrated to NodePort for usability.

    Service: kubernetes-dashboard

    Port: 30000 (Fixed port)

    Why? Allows direct access from any device on the LAN (https://192.168.1.x:30000) without maintaining an active SSH tunnel on the admin machine.

3. Security (RBAC)

Instead of using the default insecure setup, we implemented Role-Based Access Control:

    Created a dedicated ServiceAccount named admin-user.

    Bound it to the cluster-admin ClusterRole.

    Access is granted via long-lived Bearer Tokens.

🚀 Deployment Log
Step 1: Provisioning

Scripts located in /scripts automate the node setup.
Bash

# Example: Enabling cgroups across all nodes
for node in master worker1 worker2; do
  ssh $node "sudo sed -i 's/$/ cgroup.../' /boot/firmware/cmdline.txt && sudo reboot"
done

Step 2: Kubernetes Bootstrap

Used K3s (Lightweight Kubernetes) for its low footprint on ARM architecture.

    Master: curl -sfL https://get.k3s.io | sh -s - --disable traefik

    Workers: Joined via K3S_TOKEN retrieved from Master.

Step 3: Observability

Deployed Kubernetes Dashboard and Metrics Server to visualize CPU/RAM usage of the Raspberry Pi nodes.
📂 Repository Structure

    manifests/ : YAML files for Deployments, Services, and RBAC.

    scripts/ : Bash scripts used for initial setup and maintenance.

Project maintained by Ayoub.
