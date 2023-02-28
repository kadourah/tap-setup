export EMAIL=********
export AZURE_SUBSCRIPTION_ID=******
export PRINCIPAL_NAME=********
export AZURE_DNS_ZONE_RESOURCE_GROUP="default"
export AZURE_DNS_ZONE="kadourah.com"


az ad sp create-for-rbac --name $PRINCIPAL_NAME --role Contributor --scopes /subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_DNS_ZONE_RESOURCE_GROUP
# Choose a name for the service principal that contacts azure DNS to present
# the challenge.
AZURE_CERT_MANAGER_NEW_SP_NAME=$PRINCIPAL_NAME
# This is the name of the resource group that you have your dns zone in.
AZURE_DNS_ZONE_RESOURCE_GROUP=$AZURE_DNS_ZONE_RESOURCE_GROUP
# The DNS zone name. It should be something like domain.com or sub.domain.com.
AZURE_DNS_ZONE=$AZURE_DNS_ZONE

DNS_SP=$(az ad sp create-for-rbac --name $AZURE_CERT_MANAGER_NEW_SP_NAME --output json)
AZURE_CERT_MANAGER_SP_APP_ID=$(echo $DNS_SP | jq -r '.appId')
AZURE_CERT_MANAGER_SP_PASSWORD=$(echo $DNS_SP | jq -r '.password')
AZURE_TENANT_ID=$(echo $DNS_SP | jq -r '.tenant')
AZURE_SUBSCRIPTION_ID=$(az account show --output json | jq -r '.id')

#Lower the Permissions of the service principal
az role assignment delete --assignee $AZURE_CERT_MANAGER_SP_APP_ID --role Contributor

#Give Access to DNS Zone
DNS_ID=$(az network dns zone show --name $AZURE_DNS_ZONE --resource-group $AZURE_DNS_ZONE_RESOURCE_GROUP --query "id" --output tsv)
az role assignment create --assignee $AZURE_CERT_MANAGER_SP_APP_ID --role "DNS Zone Contributor" --scope $DNS_ID

#Check Permissions
az role assignment list --all --assignee $AZURE_CERT_MANAGER_SP_APP_ID

# Create secret containing service principal password for facilitating the challenge to Azure DNS
kubectl create secret generic azuredns-config --from-literal=client-secret=$AZURE_CERT_MANAGER_SP_PASSWORD  --namespace cert-manager

cat <<EOF | kubectl create -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: $EMAIL
    privateKeySecretRef:
      name: letsencrypt-production
    solvers:
    - dns01:
        azureDNS:
          clientID: $AZURE_CERT_MANAGER_SP_APP_ID
          clientSecretSecretRef:
            name: azuredns-config
            key: client-secret
          subscriptionID: $AZURE_SUBSCRIPTION_ID
          tenantID: $AZURE_TENANT_ID
          resourceGroupName: $AZURE_DNS_ZONE_RESOURCE_GROUP
          hostedZoneName: $AZURE_DNS_ZONE
          # Azure Cloud Environment, default to AzurePublicCloud
          environment: AzurePublicCloud
EOF