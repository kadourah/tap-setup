$Env:AKS_RESOURCE_GROUP="tap-full-rg"
$Env:AKS_CLUSTER_NAME="tap-full"
$Env:AKS_CLUSTER_LOCATION="eastus2"
$Env:AKS_CLUSTER_VERSION="1.24.6"

az group create -l $env:AKS_CLUSTER_LOCATION -n $env:AKS_RESOURCE_GROUP

az aks create --resource-group $env:AKS_RESOURCE_GROUP --name $env:AKS_CLUSTER_NAME --node-count 5 --generate-ssh-keys --load-balancer-sku standard --node-vm-size Standard_D4_v3 --enable-addons monitoring --kubernetes-version $env:AKS_CLUSTER_VERSION

az aks get-credentials --resource-group $env:AKS_RESOURCE_GROUP --name $env:AKS_CLUSTER_NAME