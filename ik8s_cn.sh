#!/bin/bash
### 在生产环境请务必修改端口号、IP地址簇等信息、做好防火墙

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

sudo yum install -y kubelet-1.21.1 kubeadm-1.21.1 kubectl-1.21.1 --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

# 国内拉取镜像打 TAG
docker pull registry.aliyuncs.com/google_containers/kube-apiserver:v1.21.1
docker pull registry.aliyuncs.com/google_containers/kube-controller-manager:v1.21.1
docker pull registry.aliyuncs.com/google_containers/kube-scheduler:v1.21.1
docker pull registry.aliyuncs.com/google_containers/kube-proxy:v1.21.1
docker pull registry.aliyuncs.com/google_containers/pause:3.4.1
docker pull registry.aliyuncs.com/google_containers/etcd:3.4.13-0
docker pull registry.aliyuncs.com/google_containers/coredns:1.8.0
docker pull leftsky/k8s-images:ingress-nginx-controller_v0.46.0


docker tag registry.aliyuncs.com/google_containers/kube-apiserver:v1.21.1 k8s.gcr.io/kube-apiserver:v1.21.1
docker tag registry.aliyuncs.com/google_containers/kube-controller-manager:v1.21.1 k8s.gcr.io/kube-controller-manager:v1.21.1
docker tag registry.aliyuncs.com/google_containers/kube-scheduler:v1.21.1 k8s.gcr.io/kube-scheduler:v1.21.1
docker tag registry.aliyuncs.com/google_containers/kube-proxy:v1.21.1 k8s.gcr.io/kube-proxy:v1.21.1
docker tag registry.aliyuncs.com/google_containers/pause:3.4.1 k8s.gcr.io/pause:3.4.1
docker tag registry.aliyuncs.com/google_containers/etcd:3.4.13-0 k8s.gcr.io/etcd:3.4.13-0
docker tag registry.aliyuncs.com/google_containers/coredns:1.8.0 k8s.gcr.io/coredns/coredns:v1.8.0
docker tag leftsky/k8s-images:ingress-nginx-controller_v0.46.0 k8s.gcr.io/ingress-nginx/controller:v0.46.0


docker rmi registry.aliyuncs.com/google_containers/kube-apiserver:v1.21.1
docker rmi registry.aliyuncs.com/google_containers/kube-controller-manager:v1.21.1
docker rmi registry.aliyuncs.com/google_containers/kube-scheduler:v1.21.1
docker rmi registry.aliyuncs.com/google_containers/kube-proxy:v1.21.1
docker rmi registry.aliyuncs.com/google_containers/pause:3.4.1
docker rmi registry.aliyuncs.com/google_containers/etcd:3.4.13-0
docker rmi registry.aliyuncs.com/google_containers/coredns:1.8.0
docker rmi leftsky/k8s-images:ingress-nginx-controller_v0.46.0


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

