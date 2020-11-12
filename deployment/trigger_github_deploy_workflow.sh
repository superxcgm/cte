#! /bin/sh

if [ -z "${1}" ]; then
  echo "usage: trigger_github_deploy_workflow.sh 'username:personal_access_token'"
  exit 0
fi

curl \
  -u "${1}" \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/thoughtworks-hpc/cte/actions/workflows/publish_and_deploy_image.yml/dispatches \
  -d '{"ref": "test-perf",
  "inputs": {"DEBUG_FLAG": "1", "NUM_OF_REQUEST": "800000", "SKIP_PUBLISH_DOCKER_IMAGE": "true"}
  }'
