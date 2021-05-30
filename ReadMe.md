# leftsky k8s 集群笔记

## 一键脚本
### 自动安装 kubernetes （国内）
    yum install -y wget && wget -O ik8s_cn.sh https://raw.githubusercontent.com/leftsky/ik8s/master/ik8s_cn.sh && sh ik8s_cn.sh
### 自动安装 kubernetes
    yum install -y wget && wget -O ik8s.sh https://raw.githubusercontent.com/leftsky/ik8s/master/ik8s.sh && sh ik8s.sh
### 一键安装docker
    yum install -y wget && wget -O idocker.sh https://raw.githubusercontent.com/leftsky/ik8s/master/idocker.sh && sh idocker.sh

### 关闭防火墙
    systemctl stop firewalld
    systemctl disable firewalld
### 关闭selinux # 永久
    sed -i 's/enforcing/disabled/' /etc/selinux/config
### 关闭swap # 永久
    sed -ri 's/.*swap.*/#&/' /etc/fstab
### 将桥接的IPv4流量传递到iptables的链
    cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
    br_netfilter
    EOF
    cat >/etc/sysctl.d/k8s.conf <<EOF
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    EOF
### 生效
    sysctl --system

### 添加阿里云YUM软件源
    cat >/etc/yum.repos.d/kubernetes.repo <<EOF
    [kubernetes]
    name=Kubernetes
    baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
    enabled=1
    gpgcheck=0
    repo_gpgcheck=0
    gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
    EOF

### 使用Kubeadm 安装套件
    sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
    sudo systemctl enable --now kubelet

### 使用kubeadm初始化服务器集群
    ## 可以提前使用 kubeadm config images pull
    kubeadm init --pod-network-cidr 10.244.0.0/16

### 使用kubectl
    ## 非ROOT用户使用kubectl
    # mkdir -p $HOME/.kube
    # sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    # sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ### root用户使用kubectl 加入 ~/.bashrc 可以登录即生效
    export KUBECONFIG=/etc/kubernetes/admin.conf

### 安装 flannel
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

### master 作为node
    kubectl taint nodes --all node-role.kubernetes.io/master-

### 修改 kubernetes dashboard 暴露的端口号
    kubectl edit service kubernetes-dashboard -n kubernetes-dashboard

### 安装 ingress-nginx
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.46.0/deploy/static/provider/baremetal/deploy.yaml

### 获得 kubernetes dashboard token
    kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')

### 修改 nodeport 端口范围
    vim /etc/kubernetes/manifests/kube-apiserver.yaml
    - --service-node-port-range=1-65535

### 创建私仓密钥
    kubectl create secret docker-registry alireg --docker-server=xxx.com --docker-username=xx --docker-password=xx
