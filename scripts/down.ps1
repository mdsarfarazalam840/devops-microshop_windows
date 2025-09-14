Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$kindName = "dev-cluster"
${root} = Resolve-Path "$PSScriptRoot/.."
${skaffoldFile} = Join-Path ${root} "infra/skaffold.yaml"

Write-Host "Stopping port-forwards (if any)..." -ForegroundColor Cyan
# Best-effort kill common kubectl port-forward processes
Get-Process kubectl -ErrorAction SilentlyContinue | Where-Object { $_.Path -like '*kubectl*' } | Stop-Process -Force -ErrorAction SilentlyContinue

try {
  kubectl config use-context "kind-$kindName" | Out-Null
} catch {}

if (Test-Path ${skaffoldFile}) {
  Write-Host "Deleting application resources via Skaffold..." -ForegroundColor Cyan
  try { skaffold delete -f ${skaffoldFile} | Write-Host } catch { Write-Host $_ -ForegroundColor Yellow }
}

Write-Host "Uninstalling monitoring stack (if present)..." -ForegroundColor Cyan
try {
  $rel = (& helm list -n monitoring -q | Select-String -SimpleMatch "prometheus").ToString()
  if ($rel) {
    helm uninstall prometheus -n monitoring --wait | Write-Host
  }
} catch { Write-Host $_ -ForegroundColor Yellow }

Write-Host "Uninstalling ArgoCD (if present)..." -ForegroundColor Cyan
try {
  $ns = (& kubectl get ns argocd -o name) 2>$null
  if ($ns) {
    kubectl delete ns argocd --wait=false | Write-Host
  }
} catch { Write-Host $_ -ForegroundColor Yellow }

try {
  $ns = (& kubectl get ns monitoring -o name) 2>$null
  if ($ns) {
    kubectl delete ns monitoring --wait=false | Write-Host
  }
} catch { Write-Host $_ -ForegroundColor Yellow }

Write-Host "Deleting kind cluster '$kindName'..." -ForegroundColor Cyan
kind delete cluster --name $kindName | Write-Host


# Clean up local kind registry container if present
try {
  $registryExists = (& docker ps -a --format "{{.Names}}" | Where-Object { $_ -eq 'kind-registry' })
  if ($registryExists) {
    Write-Host "Removing local registry container 'kind-registry'..." -ForegroundColor Cyan
    docker rm -f kind-registry | Write-Host
  } else {
    Write-Host "No 'kind-registry' container found." -ForegroundColor Green
  }
} catch { Write-Host $_ -ForegroundColor Yellow }


