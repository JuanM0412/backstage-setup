# Backstage Kubernetes deployment

The manifests in this directory deploy two Backstage replicas behind an
AWS Application Load Balancer.

The GitHub deployment workflow creates the `backstage-database` Secret from
the `BACKSTAGE_DATABASE_URL` GitHub secret. Never commit a populated Secret
manifest. `secret.example.yaml` is documentation only.

The workflow replaces the `__APP_BASE_URL__` and `__BACKEND_BASE_URL__`
placeholders in `configmap.yaml` from the `APP_BASE_URL` and
`BACKEND_BASE_URL` variables in the `backstage-production` GitHub environment.
These URLs are public configuration, not secrets.

The AWS Load Balancer Controller must be installed in the EKS cluster before
applying the ingress. After deployment, obtain the public ALB hostname with:

```bash
kubectl -n backstage get ingress backstage
```

Set both GitHub environment variables to the final HTTPS URL when a domain or
TLS certificate is available. For an initial HTTP deployment, use the ALB URL
instead, for example `http://backstage-123.us-east-2.elb.amazonaws.com`.
