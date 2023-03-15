#!/usr/bin/bash
ALL=0
if [[ $# -gt 0 ]]; then
  ALL=1
fi

if [[ ! -z ${GITHUB_TOKEN} ]]; then
  echo "checking limits for GITHUB_TOKEN"
else
  echo "checking limits for unauthorized requests"
fi

echo "now..: $(date)"

if [[ ! -z ${GITHUB_TOKEN} ]]; then
  echo "reset: $(date -d @$(curl --silent -L   -H "Accept: application/vnd.github+json"   -H "Authorization: Bearer ${GITHUB_TOKEN}"  -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/rate_limit | jq --jsonargs .rate.reset))"
  echo "left : $(curl --silent -L   -H "Accept: application/vnd.github+json"   -H "Authorization: Bearer ${GITHUB_TOKEN}"  -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/rate_limit | jq --jsonargs .rate.remaining)"
  [[ "${ALL}" -eq "1" ]] && echo "all  : $(curl --silent -L   -H "Accept: application/vnd.github+json"   -H "Authorization: Bearer ${GITHUB_TOKEN}"  -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/rate_limit | jq)"
else
  echo "reset: $(date -d @$(curl --silent -L   -H "Accept: application/vnd.github+json"   -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/rate_limit | jq --jsonargs .rate.reset))"
  echo "left : $(curl --silent -L   -H "Accept: application/vnd.github+json"   -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/rate_limit | jq --jsonargs .rate.remaining)"
  [[ "${ALL}" -eq "1" ]] && echo "all  : $(curl --silent -L   -H "Accept: application/vnd.github+json"   -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/rate_limit | jq)"
fi
