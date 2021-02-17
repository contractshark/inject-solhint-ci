#!/bin/bash
# @file Configuration logic
# @summary GitHub Actions Entrypoint for Solhint-CI
# @version 1.0.0+alpha
# @license Apache-2.0


cd "$GITHUB_WORKSPACE" || exit

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit 1

# running `npm bin` gives us the absolute path of the node_modules/.bin directory
# the /solhint therefore checks for solhint under the node_modules/.bin directory
# running the command successfully means it is installed
# @note we use solhint-ci as this is our seperate published npm pkg with seperate namespace
# as to avoid namespace pollution issues
if [ ! -f "$(npm bin)/solhint-ci" ]; then
  npm install
fi

if [ -n "${INPUT_PACKAGES}" ]; then
  npm install "${INPUT_PACKAGES}"
fi

"$(npm bin)"/solhint-ci --version


# INPUT_SOLHINT_INPUT = directory in which to execute, e.g. 
# contracts/**/*.sol

# INPUT_SOLHINT_CONFIG = the `solhint.json` cfg file

# @dev current JQ line doesn't [parse]
if [ "${INPUT_REPORTER}" == 'github-pr-review' ]; then
  # Use jq and github-pr-review reporter to format result to include link to rule page.
  "$(npm bin)"/solhint-ci "${INPUT_SOLHINT_INPUT:-'**/*.sol'}" --config="${INPUT_SOLHINT_CONFIG}" --ignore-pattern="${INPUT_SOLHINT_IGNORE}" -f tap \
  #  | jq -r '.[] | {source: .source, warnings:.warnings[]} | "\(.source):\(.warnings.line):\(.warnings.column):\(.warnings.severity): \(.warnings.text) [\(.warnings.rule)](https://protofire.github.io/solhint/docs/rules/(.warnings.rule))"' \
    | reviewdog -efm="%f:%l:%c:%t%*[^:]: %m" -name="${INPUT_NAME:-solhint}" -reporter=github-pr-review -level="${INPUT_LEVEL}" -filter-mode="${INPUT_FILTER_MODE}" -fail-on-error="${INPUT_FAIL_ON_ERROR}"
else
  "$(npm bin)"/solhint-ci "${INPUT_SOLHINT_INPUT:-'**/*.sol'}" --config="${INPUT_SOLHINT_CONFIG}" --ignore-pattern="${INPUT_SOLHINT_IGNORE}" --formatter=tap \
    | reviewdog -f="solhint" -name="${INPUT_NAME:-solhint}" -reporter="${INPUT_REPORTER:-github-pr-check}" -level="${INPUT_LEVEL}" -filter-mode="${INPUT_FILTER_MODE}" -fail-on-error="${INPUT_FAIL_ON_ERROR}"
fi
