# Regenerating new image pull secrets for AKS

Blog reference: https://anupams.net/using-image-pull-secrets-with-azure-container-registry/

## Issues

Azure Pipelines might throw the following during push to Azure Container Registry as part of a Kubernetes/AKS pipeline run:

```
##[error]unauthorized: Invalid clientid or client secret.
```