const {Toolkit} = require('actions-toolkit');

// TODO: check if status already exists and update

Toolkit.run(async tools => {
  const path = tools.arguments.path || '.*';
  const baseRef = tools.arguments.baseRef || 'refs/heads/master';
  tools.log("path:" + path);
  tools.log("ref:" + tools.context.ref);
  tools.log("event:" + tools.context.event);

  let PRs = [];
  let extractPR = (pr) => {
    return {
      base: {
        ref: pr.base.ref,
      },
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
  } else if (tools.context.event === 'pull_request' &&
             (tools.context.payload.action === 'opened' ||
              tools.context.payload.action === 'synchronize')) {
    PRs.push(extractPR(tools.context.payload.pull_request));
    tools.log(`PR ${PRs[0].head.ref} changed`);
  } else {
    return;
  }

  for (i = 0; i < PRs.length; i++) {
    const base_ref = 'origin/'+PRs[i].base.ref;
    const pr_ref = 'origin/'+PRs[i].head.ref;
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
      const result = await tools.runInWorkspace('/entrypoint.sh', [base_ref, pr_ref, path]);
      tools.log.success(pr_ref);
      await createStatus("success");
    } catch (error) {
      tools.log.error(pr_ref);
      tools.log.error(error.stdout);
      await createStatus("failure");
    }
  }
}, {
  event: ['push', 'pull_request.opened', 'pull_request.synchronize'],
  secrets: ['GITHUB_TOKEN']
});
