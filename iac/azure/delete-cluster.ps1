$Env:AKS_RESOURCE_GROUP="tap-full-rg"
$Env:AKS_CLUSTER_NAME="tap-full"

az aks delete --resource-group $Env:AKS_RESOURCE_GROUP --name $Env:AKS_CLUSTER_NAME --yes