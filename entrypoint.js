const shim = require('github-action-in-circleci-shim');
shim("check-master");

const {Toolkit} = require('actions-toolkit');

Toolkit.run(async tools => {
  let paths = tools.arguments.path || [ '.*' ];

  if (!Array.isArray(paths)) {
    paths = [ tools.arguments.path ];
  }

  const baseRef = tools.arguments.baseRef || 'refs/heads/master';
  tools.log("paths:" + paths.join(' '));
  tools.log("ref:" + tools.context.ref);
  tools.log("event:" + tools.context.event);

  let PRs = [];
  let extractPR = (pr) => {
    return {
      head: {
        ref: pr.head.ref,
        sha: pr.head.sha,
      }
    };
  };

  if (tools.context.event === 'push' && tools.context.ref === baseRef) {
    tools.log(`New commit to ${baseRef}`);
    const pulls = await tools.github.pulls.list({
      ...tools.context.repo,
    });
    PRs = pulls.data.map(pr => extractPR(pr));
  } else if (tools.context.event === 'push' && tools.context.ref !== baseRef) {
    PRs.push({
      head: {
        ref: tools.context.ref,
        sha: tools.context.sha,
      }
    });
    tools.log(`PR ${PRs[0].head.ref} changed`);
  } else {
    return;
  }

  for (i = 0; i < PRs.length; i++) {
    const prRef = 'origin/' + PRs[i].head.ref;
    const sha = PRs[i].head.sha;

    let createStatus = async (state) => {
      return tools.github.repos.createStatus({
        ...tools.context.repo,
        description: (state == "success") ? "No conflict detected." : "Conflict detected.",
        sha: sha,
        state: state,
        context: tools.context.action,
      });
    };

    try {
      await tools.runInWorkspace(`${__dirname}/entrypoint.sh`, [baseRef, prRef, ...paths]);
      tools.log.success(prRef);
      await createStatus("success");
    } catch (error) {
      tools.log.error(prRef);
      tools.log.error(error.stdout);
      await createStatus("failure");
    }
  }
}, {
  event: ['push', 'pull_request.opened', 'pull_request.synchronize'],
  secrets: ['GITHUB_TOKEN']
});
