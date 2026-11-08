# backstage-setup

Prueba técnica para Platform Engineer.

## Quick start

```bash
yarn install
yarn start
```

Open `http://localhost:3000`, select **Create**, and choose the
**Create a microservice (v1)** template. The form validates the service name,
selects an existing Backstage group, and asks for the API name, API path,
language, and deployment target.

Generated services include a catalog component, an OpenAPI API entity,
unit tests, a health endpoint, Docker configuration, Terraform, and GitHub
Actions. New Relic is optional and is enabled with
`NEW_RELIC_LICENSE_KEY` and `NEW_RELIC_APP_NAME`.

See [docs/verification.md](docs/verification.md) for reproducible local
checks and the credentialed scenarios required for an end-to-end demonstration.
The technical document is available as
[Markdown](docs/technical-design.md), including the use of IA and Organic
Driven Development. The live demonstration sequence is described in
[docs/demo-script.md](docs/demo-script.md).

## Template versioning

The microservice scaffolder is currently published as `v1` under
[`templates/microservice/v1/`](templates/microservice/v1/). Generated
components record both the template name and version in catalog annotations.

Future breaking changes must be introduced as a new directory and catalog
location, such as `templates/microservice/v2/`. Existing `v1` services remain
supported while new services use `v2`; a migration must be explicit, reviewed,
and tested rather than changing files in place. A version can be deprecated
by removing it from the creation flow only after existing services have a
documented migration path.
