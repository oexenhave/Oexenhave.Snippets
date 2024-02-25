$SubscriptionID = ''
$AksResourceGroup = ''
$AksClusterName = ''
$ImagePullSecretName = ''
$AcrServerUrl = ''
$ServicePricipalUserName = ''
$ServicePricipalPassword = ''

$SubscriptionID = Read-Host -Prompt "Enter Azure Subscription ID"
$AksResourceGroup = Read-Host -Prompt "Enter AKS Resource Group Name"
$AksClusterName = Read-Host -Prompt "Enter AKS Cluster Name"
$ImagePullSecretName = Read-Host -Prompt "Enter Image Pull Secret Name"
$AcrServerUrl = Read-Host -Prompt "Enter Azure Container Registry Url (e.g. MyOnwnacr01.azurecr.io)"
$ServicePricipalUserName = Read-Host -Prompt "Enter Service Principal Username"
$ServicePricipalPassword = Read-Host -Prompt "Enter Service Principal Password"

if ($null -eq $SubscriptionID -or $SubscriptionID.Length -eq 0) { Write-Error -Message "Missing subscription ID" }
if ($null -eq $AksResourceGroup -or $AksResourceGroup.Length -eq 0) { Write-Error -Message "Missing AKS Resource Group" }
if ($null -eq $AksClusterName -or $AksClusterName.Length -eq 0) { Write-Error -Message "Missing AKS Cluster Name" }
if ($null -eq $ImagePullSecretName -or $ImagePullSecretName.Length -eq 0) { Write-Error -Message "Missing Image Pull Secret Name" }
if ($null -eq $AcrServerUrl -or $AcrServerUrl.Length -eq 0) { Write-Error -Message "Missing Image Pull Secret Name" }
if ($null -eq $ServicePricipalUserName -or $ServicePricipalUserName.Length -eq 0) { Write-Error -Message "Missing Service Pricipal Username" }
if ($null -eq $ServicePricipalPassword -or $ServicePricipalPassword.Length -eq 0) { Write-Error -Message "Missing Service Pricipal Password" }

return -1

# Azure Login
# az login

# Switch to the Subscription where your AKS is located
# az account set --subscription $SubscriptionID

# Change Kubectl context to the cluster
# az aks get-credentials --resource-group $AksResourceGroup --name $AksClusterName

kubectl create secret docker-registry $ImagePullSecretName --namespace $ImagePullNamespace --docker-server=$AcrServerUrl --docker-username=$ServicePricipalUserName --docker-password=$ServicePricipalPassword