#!/bin/bash

# 自动安装docker
yum install -y wget && wget -O idocker.sh https://raw.githubusercontent.com/leftsky/ik8s/master/idocker.sh && sh idocker.sh

systemctl stop firewalld
systemctl disable firewalld

sed -i 's/enforcing/disabled/' /etc/selinux/config
sed -ri 's/.*swap.*/#&/' /etc/fstab

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
cat >/etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system

cat >/etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

kubeadm init --pod-network-cidr 10.244.0.0/16

sudo sed -i '$aexport KUBECONFIG=/etc/kubernetes/admin.conf' ~/.bashrc
source ~/.bashrc
export KUBECONFIG=/etc/kubernetes/admin.conf

kubectl apply -f https://raw.githubusercontent.com/leftsky/ik8s/master/kube-flannel.yml

kubectl taint nodes --all node-role.kubernetes.io/master-
# 安装 kubernetes dashboard
kubectl apply -f https://raw.githubusercontent.com/leftsky/ik8s/master/recommended.yaml
# 安装 kubernetes dashboard auth
kubectl apply -f https://raw.githubusercontent.com/leftsky/ik8s/master/k8sdashboard-auth.yaml

kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')

