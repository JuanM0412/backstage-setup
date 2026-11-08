# Documento técnico — capacidad de autoservicio

## 1. Objetivo y alcance

La solución ofrece un camino de autoservicio para crear un microservicio
estandarizado desde Backstage. El desarrollador selecciona nombre, equipo
propietario, nombre y ruta de API, lenguaje (Node.js o Python) y destino
(AWS Lambda o Kubernetes). El resultado es un repositorio funcional,
registrado en el catálogo, con pruebas, contrato OpenAPI, Docker y CI/CD.

El alcance de esta entrega incluye:

- Backstage local y un diseño de despliegue en AWS/EKS.
- Plantilla `microservice-v1`.
- Servicios de ejemplo con CRUD de `items`, cinco operaciones REST y `/health`.
- Lambda empaquetada como ZIP con Terraform y API Gateway.
- Kubernetes desplegado mediante manifiestos y `kubectl`.
- Terraform para la infraestructura compartida de Backstage.

La solución no pretende ser todavía una plataforma multi-tenant completa:
usa guest auth, almacenamiento en memoria para el ejemplo, un único contrato
CRUD parametrizable y credenciales AWS estáticas en los workflows.

## 2. Arquitectura de la plataforma

```text
Desarrollador
    │
    ▼
Backstage frontend ──► Backstage backend
                            │
             ┌──────────────┼────────────────┐
             ▼              ▼                ▼
        Catalog        Scaffolder         TechDocs
             │              │
             │              ├─ valida formulario y Group
             │              ├─ valida repo GitHub disponible
             │              ├─ genera código, API, Docker y workflows
             │              ├─ crea repo/ramas/protecciones
             │              └─ registra Component y API
             ▼
      PostgreSQL (catálogo, tareas y plugins)

AWS
 ┌────────────────────────────────────────────────────────────┐
 │ VPC: subredes públicas/privadas, NAT y security groups    │
 │  EKS privado + managed node group                         │
 │    └─ ALB → Service → Backstage (2 réplicas)              │
 │  RDS PostgreSQL privado                                   │
 │  ECR                                                       │
 └────────────────────────────────────────────────────────────┘
```

La infraestructura base se define en [`infra/aws/`](../infra/aws/) con los
módulos VPC, EKS y RDS, además de un repositorio ECR. EKS usa subredes
privadas y RDS no es público; el security group de RDS solo permite PostgreSQL
desde los nodos EKS. El Ingress requiere AWS Load Balancer Controller y crea
un ALB internet-facing.

Backstage se ejecuta en el namespace `backstage` con dos réplicas. El
Deployment expone el puerto 7007, usa probes TCP de startup/readiness/liveness,
solicita 250m CPU y 512Mi, y limita a 1 CPU y 1Gi. Los manifiestos están en
[`deploy/k8s/`](../deploy/k8s/).

## 3. Despliegue de Backstage

### 3.1 Provisionamiento de infraestructura

El workflow [`infrastructure-aws.yml`](../.github/workflows/infrastructure-aws.yml)
ejecuta:

1. Checkout.
2. Autenticación AWS.
3. `terraform init` usando backend S3, cifrado y la clave
   `backstage/terraform.tfstate`.
4. `terraform fmt -check` y `terraform validate`.
5. `terraform plan` solo en un `workflow_dispatch` con `apply=false`.
6. `terraform apply -auto-approve` en un push de cambios bajo `infra/aws/` o
   en dispatch con `apply=true`.

El primer bootstrap requiere crear el bucket S3 de estado y credenciales IAM
fuera de Terraform. El módulo RDS genera la contraseña en Secrets Manager;
`BACKSTAGE_DATABASE_URL` se construye con esos datos y se guarda como secreto
de GitHub. Este diseño es reproducible, pero el `apply` automático y el uso de
access keys son riesgos de producción: deben sustituirse por aprobación
manual, plan revisado y GitHub OIDC con `role-to-assume`.

### 3.2 Construcción y despliegue de Backstage

El workflow [`deploy-kubernetes.yml`](../.github/workflows/deploy-kubernetes.yml)
se ejecuta ante cambios en `master` (excepto cambios exclusivos en
`infra/aws/`) o manualmente. El pipeline:

1. Configura credenciales AWS y login en ECR.
2. Instala dependencias con `yarn install --immutable`.
3. Ejecuta `yarn tsc` y `yarn build:all`.
4. Construye `packages/backend/Dockerfile` y publica la imagen etiquetada con
   `GITHUB_SHA`.
5. Ejecuta `aws eks update-kubeconfig`.
6. Valida que existan `BACKSTAGE_DATABASE_URL` y
   `BACKSTAGE_GITHUB_TOKEN`, valida el formato de la URI PostgreSQL y exige la
   base `/backstage`.
7. Aplica namespace, ConfigMap, Secrets, Deployment, Service e Ingress.
8. Espera `rollout status` durante cinco minutos.

La imagen carga `app-config.yaml` y `app-config.production.yaml`. En
producción, `POSTGRESQL_ADDON_URI` y `GITHUB_TOKEN` provienen de Secrets;
`APP_BASE_URL` y `BACKEND_BASE_URL` son variables públicas del environment
`backstage-production`. El template `v1` y los grupos se copian dentro de la
imagen mediante el Dockerfile del backend.

El bootstrap actual es HTTP-only, el Ingress no configura TLS y se permite
guest auth fuera de desarrollo. Antes de exposición pública se requiere ACM,
HTTPS, redirección segura, proveedor de identidad real, rotación de secretos,
política de mínimo privilegio y pruebas de recuperación. El pipeline tampoco
ejecuta un smoke test HTTP posterior ni implementa rollback automático; la
reversión operativa consiste en volver a aplicar una imagen SHA anterior.

## 4. Autoservicio y servicio generado

La plantilla [`templates/microservice/v1/`](../templates/microservice/v1/)
registra un `Template` en el catálogo. `EntityPicker` limita el owner a
entidades `Group` de [`templates/org.yaml`](../templates/org.yaml). Antes de
publicar, `github:repo:validate-available` consulta GitHub y falla
explícitamente si el repositorio existe. El scaffolder crea `main`,
`develop` y `release`, aplica protección de ramas y registra el catálogo
usando el `catalog-info.yaml` generado.

Cada repositorio contiene:

- código Node.js o Python y pruebas unitarias;
- cinco operaciones REST sobre `/api/v1/<apiPath>`;
- OpenAPI y entidad `API`;
- Dockerfile de servicio y Dockerfile de desarrollo para Lambda;
- Terraform solo para Lambda/API Gateway, no para recursos de aplicación
  Kubernetes;
- CI con pruebas, auditoría de dependencias, Trivy y validación Terraform
  cuando aplica;
- CD activado por `workflow_run` después de `Build Validation` exitoso.

Para Kubernetes, CD publica la imagen en GHCR y ejecuta
`aws eks update-kubeconfig` más `kubectl apply`. Deployment, Service e Ingress
tienen una única fuente de verdad: los manifiestos `k8s/`. Para Lambda,
Terraform administra función, permisos, recursos API Gateway y deployment.

## 5. Seguridad, observabilidad y operación

CI ejecuta `npm audit` o `pip-audit`, escanea filesystem e imágenes con Trivy
y no permite continuar ante vulnerabilidades High/Critical, secretos o
misconfiguraciones detectadas. Los tokens no se versionan. No obstante,
GitHub usa actualmente IAM access keys; OIDC es la mejora prioritaria.

Los servicios exponen `/health` para readiness y health checks. Node.js y
Python incluyen integración opcional con New Relic: sin variables el servicio
funciona localmente; con `NEW_RELIC_LICENSE_KEY` y `NEW_RELIC_APP_NAME` se
activa el agente. La telemetría requiere una cuenta New Relic, una
license/ingest key y secretos inyectados por el runtime. Lambda requeriría
además la Layer/extensión oficial; no se presenta como validada en esta
entrega. Falta completar dashboards, alertas, logs estructurados y métricas
de negocio.

Ansible no se usa como mecanismo de despliegue: EKS administra los nodos,
Terraform administra la infraestructura compartida y `kubectl` administra la
aplicación. Introducir Ansible para aplicar los mismos manifiestos duplicaría
responsabilidades. Podría usarse posteriormente para hosts no gestionados,
bootstrap de runners o verificaciones idempotentes.

## 6. Verificación, límites y evolución

Verificaciones locales:

```bash
yarn tsc
terraform fmt -check -recursive infra/aws
terraform -chdir=infra/aws init -backend=false -input=false
terraform -chdir=infra/aws validate
```

La guía [`verification.md`](verification.md) define evidencia para creación
válida, solicitud inválida, duplicado, fallo de generación, pruebas API y
separación entre validación estática y despliegues con credenciales. Terraform
`validate` demuestra sintaxis/configuración, no un despliegue AWS. La
publicación GitHub, rollout EKS/API Gateway y recepción New Relic requieren
cuentas externas. La exigencia de segunda ejecución de Ansible se documenta
como no aplicable a esta arquitectura.

La plantilla está versionada como `microservice-v1`; los cambios incompatibles
se publicarán como `v2` coexistente. Los servicios existentes conservan su
versión, y cualquier migración requiere compatibilidad, pruebas, plan de
adopción y fecha de retiro. Límites actuales: CRUD fijo de `items`, memoria
volátil, guest auth, HTTP de bootstrap, ausencia de rollback automático y
ausencia de validación de múltiples APIs arbitrarias.

Las métricas de éxito serán tiempo hasta repositorio utilizable, porcentaje de
scaffolds exitosos, causas de fallo, tiempo de recuperación, primer intento
exitoso de CI, tiempo merge-to-deploy, adopción por versión, tickets manuales,
disponibilidad, errores y latencia. La IA apoyó revisión y detección de
inconsistencias; cada cambio se contrastó con el código, logs de GitHub
Actions y verificaciones locales.
