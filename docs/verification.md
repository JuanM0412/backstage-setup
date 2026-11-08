# Verification guide

This repository separates checks that run locally from checks that require AWS
or GitHub credentials.

## Local checks

Run the Backstage type check and Terraform validation from the repository root:

```bash
yarn tsc
terraform fmt -check -recursive infra/aws
terraform -chdir=infra/aws init -backend=false -input=false
terraform -chdir=infra/aws validate
```

For a generated Node.js service:

```bash
npm install
npm test
curl http://localhost:8080/health
```

For a generated Python service:

```bash
python -m pip install -r requirements.txt
pytest
curl http://localhost:8080/health
```

The generated CI workflow repeats the service tests, dependency audits,
Terraform validation, filesystem secret/misconfiguration scanning, and (for
Kubernetes services) image scanning.

The generated CD workflow listens for the completion of `Build Validation` on
`main`. It deploys only when CI concludes successfully; a failed or cancelled
CI run cannot trigger deployment. Manual `workflow_dispatch` remains available
for an explicitly requested deployment.

For Kubernetes services, CD connects to the existing EKS cluster and applies
the generated `k8s/` manifests with `kubectl`. Terraform is intentionally not
used for those service resources, so Deployment, Service, and Ingress each
have one owner. Terraform remains part of the Lambda path and the repository's
separate AWS infrastructure provisioning.

## Scaffolder scenarios

Run these scenarios from the Backstage Scaffolder UI and retain the task
details as evidence:

1. **Valid request:** create a service with an existing group such as `wenia`,
   an API name/path, Node.js or Python, and Kubernetes or Lambda deployment.
   Confirm the repository, component, and API links in the task output.
2. **Invalid request:** submit an uppercase or otherwise invalid service name,
   an invalid API path, or a description shorter than ten characters. The form
   must reject the request before any repository is created.
3. **Duplicate request:** repeat a valid service name. The
   `github:repo:validate-available` step must fail before `publish:github`;
   the task must not be reported as successful.
4. **Generation failure:** temporarily use an invalid GitHub token in an
   isolated environment. The task must fail and show the failing step rather
   than register a successful catalog entity.

## Credentialed checks

The following require GitHub and/or AWS accounts and are not represented by
static validation:

- Publishing a repository and registering it in the Backstage catalog.
- Applying Lambda Terraform or Kubernetes manifests.
- Running the generated CD workflow.
- Verifying API Gateway, EKS, or New Relic telemetry.

Terraform `fmt` and `validate` prove configuration validity only; they are not
evidence of an AWS deployment.

The case study asks for a second Ansible playbook execution. This solution does
not use Ansible; its deployment automation is Terraform for Lambda and
GitHub Actions plus kubectl for Kubernetes.
That difference should be stated explicitly during the evaluation instead of
presenting Terraform validation as Ansible evidence.
