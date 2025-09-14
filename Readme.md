## DevOps Microshop

A minimal microservice with end-to-end local Kubernetes automation (Kind + Helm + Skaffold), observability (Prometheus Operator + ServiceMonitor), and simple deployment scripts.

### Project Structure
```text
devops-microshop/
  app/
    app.js
    Dockerfile
    package.json
    package-lock.json
  ci-cd/
    github-actions.yml
    Jenkinsfile
  gitops/
    kustomization.yaml
  infra/
    argocd-app.yml
    kind-config.yaml
    skaffold.yaml
    helm/
      grafana-values.yaml
      prometheus-values.yaml
  k8s/
    deployment.yaml
    ingress.yaml
    service.yaml
    servicemonitor.yaml
  scripts/
    up.ps1
    down.ps1
    deploy.sh (placeholder)
    kind-up.sh (placeholder)
    kind-down.sh (placeholder)
  Makefile (placeholder)
  Readme.md
```

### Prerequisites
- Docker Desktop (or Docker Engine) running
- PowerShell 7+ (`pwsh`)
- Kind (`kind`), Kubectl (`kubectl`), Helm (`helm`), Skaffold (`skaffold`)

Verify versions:
```powershell
kind version
kubectl version --client
helm version
skaffold version
pwsh -v
```

### Run Locally (One Command)

Creates the Kind cluster, installs Prometheus Operator, builds and deploys the app with Skaffold, and port-forwards the service.

```powershell
pwsh .\scripts\up.ps1
```

Endpoints:
- App: `http://localhost:8081/`
- Health: `http://localhost:8081/health`
- Metrics: `http://localhost:8081/metrics`

Notes:
- Port-forward uses 8081 to avoid conflicts with Jenkins (8080).
- Ingress is created but an ingress controller is not installed by default in Kind. Use port-forward for local access.

### Live Dev Mode (Auto Rebuild + Redeploy)
```powershell
pwsh .\scripts\up.ps1 -Watch
```
Runs `skaffold dev` with auto-rebuild and auto port-forward.

### Tear Down Everything

Deletes app resources, Prometheus stack, the `monitoring` namespace, the Kind cluster, and removes a local Docker registry container named `kind-registry` if present.

```powershell
pwsh .\scripts\down.ps1
```

### What Gets Deployed
- Kubernetes resources in `k8s/`:
  - `Deployment` for the Node.js service (`app/app.js` exposed on container port 3000)
  - `Service` on port 80 targeting 3000
  - `Ingress` (class annotation shown; controller not installed by default)
  - `ServiceMonitor` for Prometheus scraping `/metrics`
- Prometheus Operator via `kube-prometheus-stack` Helm chart
- Image is built by Skaffold and loaded into Kind

### Observability
- Metrics exposed at `/metrics` (Prometheus client in `app/app.js`)
- `ServiceMonitor` selects the service via `app: devops-microshop`
- Grafana is installed with the stack; to access locally:
  ```powershell
  kubectl -n monitoring port-forward deploy/prometheus-grafana 3000:3000
  # then visit http://localhost:3000
  ```

### GitOps with ArgoCD

ArgoCD is automatically installed with the automation scripts. Access ArgoCD UI:

```powershell
# Get admin password
$password = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"; [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($password))

# Port-forward ArgoCD server
kubectl port-forward service/argocd-server -n argocd 8082:443
```

Then visit: `https://localhost:8082` (username: `admin`, password: from above command)

#### ArgoCD Applications

The automation script automatically creates an ArgoCD Application for your microshop. To set up GitOps with your Git repository:

```powershell
# Set up GitOps with your Git repository
pwsh .\scripts\setup-gitops.ps1 -GitRepoUrl "https://github.com/mdsarfarazalam840/devops-microshop_windows.git"
```

This will:
1. Update the ArgoCD Application manifest with your Git repository URL
2. Create the ArgoCD Application to manage your microshop
3. ArgoCD will sync your microshop manifests from the Git repository

**Prerequisites for GitOps:**
1. Push your code to a Git repository
2. Ensure the `k8s/` directory is in your repository root
3. Run the setup script with your actual repository URL

**Manual setup (alternative):**
```powershell
# Update the repository URL in the manifest
# Edit infra/argocd-app-microshop-git.yml and replace YOUR_USERNAME with your actual username
kubectl apply -f infra/argocd-app-microshop-git.yml
```

### Common Commands
```powershell
# Re-apply k8s manifests
kubectl apply -f k8s/

# View app logs
kubectl logs -l app=devops-microshop -f

# Check resources
kubectl get all
kubectl get servicemonitor
```

### Contributing

1. Fork and clone the repository
2. Create a feature branch
   ```bash
   git checkout -b feat/<short-description>
   ```
3. Make changes following the code style guidelines:
   - Keep configuration minimal and readable
   - Prefer explicit naming over abbreviations
   - For Kubernetes manifests, keep health checks and ports consistent with the app
4. Validate locally
   ```powershell
   pwsh .\scripts\up.ps1
   # hit endpoints, verify resources
   pwsh .\scripts\down.ps1
   ```
5. Commit with conventional messages
   ```bash
   git commit -m "feat: add <thing>"
   git commit -m "fix: correct <issue>"
   git commit -m "docs: update README"
   ```
6. Push and open a Pull Request with a concise description and testing notes

### CI/CD
- `ci-cd/Jenkinsfile`: reference for Jenkins pipeline
- `ci-cd/github-actions.yml`: example GitHub Actions workflow

### Troubleshooting
- ServiceMonitor CRD missing:
  - Ensure Prometheus Operator (kube-prometheus-stack) is installed. The `up.ps1` script handles this automatically.
- Port 8080 is busy:
  - Jenkins may be using it; this project uses 8081 for local access.
- Ingress not reachable:
  - Install an ingress controller (e.g., `ingress-nginx`) or continue using port-forward.

### License
MIT


