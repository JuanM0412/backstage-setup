import {
  coreServices,
  createBackendModule,
} from '@backstage/backend-plugin-api';
import { ScmIntegrations } from '@backstage/integration';
import {
  scaffolderActionsExtensionPoint,
  createTemplateAction,
} from '@backstage/plugin-scaffolder-node';
import { Config } from '@backstage/config';
import { Octokit } from 'octokit';

const createGithubBranchesAction = (config: Config) =>
  createTemplateAction({
    id: 'github:branches:create',
    description: 'Creates branches from the repository default branch',
    schema: {
      input: z =>
        z.object({
          repoUrl: z.string(),
          branches: z.array(z.string().min(1)),
        }),
    },
    async handler(ctx) {
      const { host, owner, repo } = parseRepoUrl(ctx.input.repoUrl);
      const integration =
        ScmIntegrations.fromConfig(config).github.byHost(host);

      if (!integration?.config.token) {
        throw new Error(`No GitHub token configured for ${host}`);
      }

      const client = new Octokit({ auth: integration.config.token });
      const repository = await client.rest.repos.get({ owner, repo });
      const defaultBranch = repository.data.default_branch;
      const sourceRef = await client.rest.git.getRef({
        owner,
        repo,
        ref: `heads/${defaultBranch}`,
      });
      const sourceSha = sourceRef.data.object.sha;

      for (const branch of ctx.input.branches) {
        if (branch === defaultBranch) {
          continue;
        }

        try {
          await client.rest.git.getRef({
            owner,
            repo,
            ref: `heads/${branch}`,
          });
          ctx.logger.info(`Branch ${branch} already exists`);
        } catch (error) {
          if (!isNotFound(error)) {
            throw error;
          }

          await client.rest.git.createRef({
            owner,
            repo,
            ref: `refs/heads/${branch}`,
            sha: sourceSha,
          });
          ctx.logger.info(`Created branch ${branch}`);
        }
      }

      ctx.output('branches', ctx.input.branches);
    },
  });

const createGithubRepositoryAvailabilityAction = (config: Config) =>
  createTemplateAction({
    id: 'github:repo:validate-available',
    description:
      'Fails before publishing when a GitHub repository already exists',
    schema: {
      input: z =>
        z.object({
          repoUrl: z.string(),
        }),
    },
    async handler(ctx) {
      const { host, owner, repo } = parseRepoUrl(ctx.input.repoUrl);
      const integration =
        ScmIntegrations.fromConfig(config).github.byHost(host);

      if (!integration?.config.token) {
        throw new Error(`No GitHub token configured for ${host}`);
      }

      const client = new Octokit({ auth: integration.config.token });
      try {
        await client.rest.repos.get({ owner, repo });
      } catch (error) {
        if (isNotFound(error)) {
          ctx.logger.info(`GitHub repository ${owner}/${repo} is available`);
          return;
        }
        throw error;
      }

      throw new Error(
        `GitHub repository ${owner}/${repo} already exists; choose a different service name`,
      );
    },
  });

function parseRepoUrl(repoUrl: string): {
  host: string;
  owner: string;
  repo: string;
} {
  const parsed = new URL(`https://${repoUrl}`);
  const owner = parsed.searchParams.get('owner');
  const repo = parsed.searchParams.get('repo');

  if (!owner || !repo) {
    throw new Error(`Invalid GitHub repository URL: ${repoUrl}`);
  }

  return { host: parsed.hostname, owner, repo };
}

function isNotFound(error: unknown): boolean {
  return (
    typeof error === 'object' &&
    error !== null &&
    'status' in error &&
    error.status === 404
  );
}

const githubBranchesModule = createBackendModule({
  pluginId: 'scaffolder',
  moduleId: 'github-branches',
  register({ registerInit }) {
    registerInit({
      deps: {
        config: coreServices.rootConfig,
        scaffolderActions: scaffolderActionsExtensionPoint,
      },
      async init({ config, scaffolderActions }) {
        scaffolderActions.addActions(
          createGithubBranchesAction(config),
          createGithubRepositoryAvailabilityAction(config),
        );
      },
    });
  },
});

export default githubBranchesModule;
