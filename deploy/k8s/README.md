# Backstage Kubernetes deployment

The manifests in this directory deploy two Backstage replicas behind an
AWS Application Load Balancer.

The GitHub deployment workflow creates the `backstage-database` Secret from
the `BACKSTAGE_DATABASE_URL` GitHub secret. Never commit a populated Secret
manifest. `secret.example.yaml` is documentation only.

The workflow replaces the `__APP_BASE_URL__` and `__BACKEND_BASE_URL__`
placeholders in `configmap.yaml` from the `APP_BASE_URL` and
`BACKEND_BASE_URL` variables in the `backstage-production` GitHub environment.
These URLs are public configuration, not secrets. During the first deployment,
when the ALB hostname does not exist yet, the workflow temporarily uses
`http://localhost` and emits a warning.

The AWS Load Balancer Controller must be installed in the EKS cluster before
applying the ingress. After deployment, obtain the public ALB hostname with:

```bash
kubectl -n backstage get ingress backstage
```

After the first deployment, obtain the ALB hostname:

```bash
kubectl -n backstage get ingress backstage
```

Set both GitHub environment variables to the ALB URL, for example
`http://backstage-123.us-east-2.elb.amazonaws.com`, and run the deployment
again. When a domain and TLS certificate are available, replace both values
with the final HTTPS URL.
