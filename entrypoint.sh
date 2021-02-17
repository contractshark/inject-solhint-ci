#!/bin/bash


cd "$GITHUB_WORKSPACE" || exit

export SHARKCI_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit 1

# running `npm bin` gives us the absolute path of the node_modules/.bin directory
# the /solhint therefore checks for solhint under the node_modules/.bin directory
# running the command successfully means it is installed
if [ ! -f "$(npm bin)/solhint" ]; then
  npm install
fi

if [ -n "${INPUT_PACKAGES}" ]; then
  npm install "${INPUT_PACKAGES}"
fi

"$(npm bin)"/solhint --version

if [ "${INPUT_REPORTER}" == 'github-pr-review' ]; then
  # Use jq and github-pr-review reporter to format result to include link to rule page.
  "$(npm bin)"/solhint "${INPUT_SOLHINT_INPUT:-'**/*.sol'}" --config="${INPUT_SOLHINT_CONFIG}" --ignore-pattern="${INPUT_SOLHINT_IGNORE}" -f json \
    | jq -r '.[] | {source: .source, warnings:.warnings[]} | "\(.source):\(.warnings.line):\(.warnings.column):\(.warnings.severity): \(.warnings.text) [\(.warnings.rule)](https://protofire.github.io/solhint/docs/rules/(.warnings.rule))"' \
    | sharkci -efm="%f:%l:%c:%t%*[^:]: %m" -name="${INPUT_NAME:-solhint}" -reporter=github-pr-review -level="${INPUT_LEVEL}" -filter-mode="${INPUT_FILTER_MODE}" -fail-on-error="${INPUT_FAIL_ON_ERROR}"
else
  "$(npm bin)"/solhint "${INPUT_SOLHINT_INPUT:-'**/*.sol'}" --config="${INPUT_SOLHINT_CONFIG}" --ignore-pattern="${INPUT_SOLHINT_IGNORE}" \
    | sharkci -f="solhint" -name="${INPUT_NAME:-solhint}" -reporter="${INPUT_REPORTER:-github-pr-check}" -level="${INPUT_LEVEL}" -filter-mode="${INPUT_FILTER_MODE}" -fail-on-error="${INPUT_FAIL_ON_ERROR}"
fi
