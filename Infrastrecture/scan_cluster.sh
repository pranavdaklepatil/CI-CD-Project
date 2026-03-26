#Run it on the master node to scan the cluster and get the nodes information
wget https://github.com/Shopify/kubeaudit/releases/download/v0.22.1/kubeaudit_0.22.1_linux_amd64.tar.gz
tar -xvzf kubeaudit_0.22.1_linux_amd64.tar.gz
sudo mv kubeaudit /usr/local/bin/
kubeaudit all
