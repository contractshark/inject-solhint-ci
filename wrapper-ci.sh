#!/bin/bash

cd "$GITHUB_WORKSPACE" || exit

export SHARKCI_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit 1

if [ ! -f "$(npm bin)/solhint-ci" ]; then
  npm install
fi

if [ -n "${INPUT_PACKAGES}" ]; then
  npm install "${INPUT_PACKAGES}"
fi

"$(npm bin)"/solhint-ci --version

if [ "${INPUT_REPORTER}" == 'github-pr-review' ]; then
  # Use jq and github-pr-review reporter to format result to include link to rule page.
  "$(npm bin)"/solhint-ci "${INPUT_SOLHINT_INPUT:-'**/*.sol'}" --config="${INPUT_SOLHINT_CONFIG}" --ignore-pattern="${INPUT_SOLHINT_IGNORE}" -f json \
    | jq -r '.[] | {source: .source, warnings:.warnings[]} | "\(.source):\(.warnings.line):\(.warnings.column):\(.warnings.severity): \(.warnings.text) [\(.warnings.rule)](protofire.github.io/solhint/docs/rules/\(.warnings.rule))"' \
    | sharkci -efm="%f:%l:%c:%t%*[^:]: %m" -name="${INPUT_NAME:-solhint-ci}" -reporter=github-pr-review -level="${INPUT_LEVEL}" -filter-mode="${INPUT_FILTER_MODE}" -fail-on-error="${INPUT_FAIL_ON_ERROR}"
else
  "$(npm bin)"/solhint-ci "${INPUT_SOLHINT_INPUT:-'**/*.sol'}" --config="${INPUT_SOLHINT_CONFIG}" --ignore-pattern="${INPUT_SOLHINT_IGNORE}" \
    | sharkci -f="solhint-ci" -name="${INPUT_NAME:-solhint-ci}" -reporter="${INPUT_REPORTER:-github-pr-check}" -level="${INPUT_LEVEL}" -filter-mode="${INPUT_FILTER_MODE}" -fail-on-error="${INPUT_FAIL_ON_ERROR}"
fi
