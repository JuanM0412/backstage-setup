# ${{ values.name }}

${{ values.description }}

## API

The service exposes an in-memory REST API for `items`. The OpenAPI contract is available at [`docs/openapi.yaml`](docs/openapi.yaml).

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/api/v1/items` | List all items |
| `POST` | `/api/v1/items` | Create an item |
| `GET` | `/api/v1/items/{id}` | Get an item |
| `PUT` | `/api/v1/items/{id}` | Replace an item |
| `DELETE` | `/api/v1/items/{id}` | Delete an item |

An item requires a non-empty `name` and accepts an optional `description`. Data is stored in memory and is lost when the service restarts.

## CI configuration

The CI workflow supports an optional SonarCloud scan. To enable it, configure
the repository or organization secret `SONAR_TOKEN` and the repository variable
`SONAR_ENABLED` with the value `true`. The scan is skipped otherwise, so builds
do not fail when SonarCloud credentials are not available. The SonarCloud URL
is set explicitly to `https://sonarcloud.io`.

The scan uses the GitHub repository as the SonarCloud project key and
`backstage-backend` as the SonarCloud organization. If your SonarCloud
organization is different, update `sonar.organization` in the generated
workflow.

## Local development

### Node.js

```bash
npm install
npm start
```

### Python

```bash
python -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
python src/app.py
```