az group create --name tap-full-group --location eastus
az aks create --resource-group tap-full-group --name tap-full --node-count 5 --generate-ssh-keys --load-balancer-sku standard --node-vm-size Standard_D4_v3 --enable-addons monitoring --kubernetes-version 1.25.6
az aks get-credentials --resource-group tap-full-group --name tap-full