Param(
  [switch]$Watch
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-KindCluster {
  param(
    [string]$Name,
    [string]$ConfigPath
  )
  $clusters = (& kind get clusters) 2>$null
  if (-not ($clusters -match "^$Name$")) {
    Write-Host "Creating kind cluster '$Name'..." -ForegroundColor Cyan
    kind create cluster --name $Name --config $ConfigPath | Write-Host
  } else {
    Write-Host "Kind cluster '$Name' already exists." -ForegroundColor Green
  }
}

function Ensure-PrometheusStack {
  Write-Host "Installing/Upgrading kube-prometheus-stack..." -ForegroundColor Cyan
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>$null | Out-Null
  helm repo update | Write-Host
  helm upgrade --install prometheus prometheus-community/kube-prometheus-stack `
    --namespace monitoring --create-namespace `
    -f "$PSScriptRoot/../infra/helm/prometheus-values.yaml" `
    --wait --timeout 10m | Write-Host
}

function Start-PortForward {
  Write-Host "Starting port-forward on 8081 -> service/devops-microshop:80" -ForegroundColor Cyan
  $pf = Start-Process -PassThru -NoNewWindow pwsh -ArgumentList "-NoLogo","-NoProfile","-Command","kubectl port-forward service/devops-microshop 8081:80" 
  return $pf
}

$kindName = "dev-cluster"
$kindConfig = "$PSScriptRoot/../infra/kind-config.yaml"

Ensure-KindCluster -Name $kindName -ConfigPath $kindConfig

kubectl config use-context "kind-$kindName" | Write-Host

Ensure-PrometheusStack

Write-Host "Building and deploying with Skaffold..." -ForegroundColor Cyan

# Choose skaffold mode
if ($Watch) {
  # Interactive dev loop with auto port-forward
  skaffold dev -f "$PSScriptRoot/../infra/skaffold.yaml"
} else {
  # One-shot deploy then manual port-forward
  skaffold run -f "$PSScriptRoot/../infra/skaffold.yaml"
  $pfProc = Start-PortForward
  Write-Host "App ready at http://localhost:8081 (health: /health, metrics: /metrics)" -ForegroundColor Green
  Write-Host "Press Ctrl+C to stop port-forward."
  Wait-Process -Id $pfProc.Id
}


