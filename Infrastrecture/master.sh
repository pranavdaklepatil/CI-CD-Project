sudo kubeadm init --pod-network-cidr=10.244.0.0/16
# get the command ans execute it on worker nodes to join the cluster
# example: kubeadm join

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config 

kubectl apply -f https://docs.projectcalico.org/v3.20/manifests/calico.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.49.0/deploy/static/provider/baremetal/deploy.yaml

