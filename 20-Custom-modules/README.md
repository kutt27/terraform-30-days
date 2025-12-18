# Day 20: EKS Cluster (Real-time Project 1)

Pending tasks:
1. Deploy applications using kubectl
2. Configure IRSA for application pods
3. Set up ingress controller (AWS LB Controller)
4. Configure monitoring (Prometheus/Grafana)
5. Implement GitOps (ArgoCD/FluxCD)

#### Directory Structure Updates

```text
code/
├── modules/
│   └── kubernetes-addons/ # Handles Helm deployments
└── k8s-manifests/        # Sample application manifests
```

#### Usage

1.  **Terraform Plan**: Review the plan to see the new Helm releases.
    ```bash
    terraform plan
    ```

2.  **Deployment**: Apply the changes (requires a working AWS environment).
    ```bash
    terraform apply
    ```

3.  **ArgoCD Access**: Once deployed, get the initial password:
    ```bash
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    ```