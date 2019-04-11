# check-master-action
GitHub Action to check whether there are any conflicting changes on master based on a path regex.

# Summary
Let's say you have a monorepo with many distinct projects (e.g. terraform configs) in seperate directories. You enable `Require branches to be up to date before merging` because you don't want terrafom to get in a bad state. If this repository has a lot of activity people will have a hard time merging because they have to merge master constantly triggering the CI.

## Example
https://github.com/codesuki/check-master-action-sample

https://github.com/codesuki/check-master-action-sample/pulls

# What the action does

## On push to master
For each PR it checks the changed paths, whether they were changed on master or not.
This uses a path regex to specify which path should be considered.

Given a repository that stores terraform config in subfolders like below.
```
repo/terraform/service-a/dev
repo/terraform/service-a/prd
repo/terraform/service-b/dev
repo/terraform/service-b/prd
...
```

Example 1: Block on any change in sub-project
```
--path "terraform/([A-Za-z0-9]*)/"
```

Example 2: Block on any change in environment
```
--path "terraform/([A-Za-z0-9]+/[A-Za-z0-9]+/)"
```

# Configuration
You can configure which branch is your `master` with `--baseRef` and you can specify the path regex that will be used with `--path`.

Defaults:
`--path ".*"`
`--baseRef "refs/heads/master"`

Sample `.workflow`
```
action "check master" {
  uses    = "docker://codesuki/check-master-action:latest"
  args    = [
      "--path",
      "terraform/([A-Za-z0-9]*)/",
      "--baseRef",
      "refs/heads/master"
  ]
  secrets = ["GITHUB_TOKEN"]
}

workflow "Master Change" {
  on       = "push"
  resolves = ["check master"]
}

workflow "New PR" {
  on       = "pull_request"
  resolves = ["check master"]
}
```

# Limitations
From the [GitHub Actions docs](https://developer.github.com/actions/managing-workflows/workflow-configuration-options/)

```
You can execute up to 1000 API requests in an hour across all actions within a repository.
```

So if you have a repository so big this will be a problem you could convert the action to a GitHub App / Bot.
