# Backstage Kubernetes deployment

The manifests in this directory deploy two Backstage replicas behind an
AWS Application Load Balancer.

The GitHub deployment workflow creates the `backstage-database` Secret from
the `BACKSTAGE_DATABASE_URL` GitHub secret. Never commit a populated Secret
manifest. `secret.example.yaml` is documentation only.

The AWS Load Balancer Controller must be installed in the EKS cluster before
applying the ingress. After deployment, obtain the public ALB hostname with:

```bash
kubectl -n backstage get ingress backstage
```

Set `APP_BASE_URL` and `BACKEND_BASE_URL` in
`deploy/k8s/configmap.yaml` to the final HTTPS URL when a domain or TLS
certificate is available.
