# eps-workflow-dependabot

Workflows to help manage Dependabot PRs in GitHub repositories.

## Usage

### Combine Dependabot PRs

This workflow can be called to combine multiple open Dependabot PRs into a single PR.

#### Inputs

- `branchPrefix`: Branch prefix to find combinable PRs based on. Default: `dependabot`
- `mustBeGreen`: Only combine PRs that are green (status is success). Default: `true`
- `combineBranchName`: Name of the branch to combine PRs into. Default: `combine-dependabot-PRs`
- `ignoreLabel`: Exclude PRs with this label. Default: `nocombine`

#### Example

```yaml
name: Combine Dependabot PRs

on:
  workflow_dispatch:
    inputs:
      branchPrefix:
      mustBeGreen:
      combineBranchName:
      ignoreLabel:

jobs:
    combine-dependabot-prs:
        uses: eps-workflow-dependabot/.github/workflows/combine-dependabot-prs.yml@v1.0.0
        with:
            branchPrefix: ${{ github.event.inputs.branchPrefix }}
            mustBeGreen: ${{ github.event.inputs.mustBeGreen }}
            combineBranchName: ${{ github.event.inputs.combineBranchName }}
            ignoreLabel: ${{ github.event.inputs.ignoreLabel }}
```

### Dependabot Auto-Approve and Merge

This workflow can be called to automatically approve and merge Dependabot PRs as part of the pull request workflow.

#### Requirements

Ensure that the `AUTOMERGE_APP_ID` and `AUTOMERGE_PEM` secrets are set, a `requires-manual-qa` PR label is created, and the repo is added to the `eps-autoapprove-dependabot` GitHub App.

#### Example

```yaml
name: Pull Request

on:
  pull_request:
    branches: [main]

jobs:
    dependabot-auto-approve-and-merge:
        uses: eps-workflow-dependabot/.github/workflows/dependabot-auto-approve-and-merge.yml@v1.0.0
```
