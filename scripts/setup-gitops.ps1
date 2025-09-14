param(
  [Parameter(Mandatory=$true)]
  [string]$GitRepoUrl
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "Setting up GitOps for repository: $GitRepoUrl" -ForegroundColor Cyan

# Update the ArgoCD Application manifest with the actual Git repository URL
$argocdAppFile = "$PSScriptRoot/../infra/argocd-app-microshop-git.yml"
$content = Get-Content $argocdAppFile -Raw
$content = $content -replace 'https://github.com/mdsarfarazalam840/devops-microshop_windows.git', $GitRepoUrl
Set-Content $argocdAppFile $content

Write-Host "Updated ArgoCD Application manifest with repository: $GitRepoUrl" -ForegroundColor Green

# Apply the ArgoCD Application
Write-Host "Creating ArgoCD Application..." -ForegroundColor Cyan
kubectl apply -f $argocdAppFile

Write-Host "GitOps setup complete!" -ForegroundColor Green
Write-Host "Your microshop will now be managed by ArgoCD from: $GitRepoUrl" -ForegroundColor Green
