#!/bin/bash
# K3s Cluster Provisioning Script
# Author: Ayoub

MASTER_IP="192.168.1.24"

echo "🚀 Starting Cluster Setup..."

# 1. Kernel Tuning (cgroups)
# Note: Ran on all nodes via SSH
# echo "cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1" >> /boot/firmware/cmdline.txt

# 2. Master Installation
# ssh master "curl -sfL https://get.k3s.io | sh -s - --disable traefik"

# 3. Worker Joining
# NODE_TOKEN=$(ssh master "sudo cat /var/lib/rancher/k3s/server/node-token")
# ssh worker1 "curl -sfL https://get.k3s.io | K3S_URL=https://${MASTER_IP}:6443 K3S_TOKEN=${NODE_TOKEN} sh -"

echo "✅ This script serves as documentation of the commands used."
