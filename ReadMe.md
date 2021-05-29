# leftsky k8s 集群笔记

### 一键脚本
#### 安装docker
    yum install -y wget && wget -O idocker.sh https://oss.leftsky.top/k8s/idocker.sh && sh idocker.sh
### 自动安装 kubernetes
    yum install -y wget && wget -O ik8s.sh https://oss.leftsky.top/k8s/ik8s.sh && sh ik8s.sh
### 自动安装 kubernetes （国内）
    yum install -y wget && wget -O ik8s_cn.sh https://oss.leftsky.top/k8s/ik8s_cn.sh && sh ik8s_cn.sh

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

### kubernetes dashboard
    安装：
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
    外网访问
    kubectl proxy --address='0.0.0.0' --port=8888 --accept-hosts='^*$'
    访问：
    http://domain:8888/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

### 创建私仓密钥
    kubectl create secret docker-registry alireg --docker-server=registry.cn-hongkong.aliyuncs.com --docker-username=leftskyzuoxiao --docker-password=xx
