#!/bin/sh -l

git_setup() {
  cat <<- EOF > $HOME/.netrc
    machine github.com
    login $GITHUB_ACTOR
    password $GITHUB_TOKEN
    machine api.github.com
    login $GITHUB_ACTOR
    password $GITHUB_TOKEN
EOF
  chmod 600 $HOME/.netrc

  git config --global user.email "$GITBOT_EMAIL"
  git config --global user.name "$GITHUB_ACTOR"
}

git_cmd() {
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    echo $@
  else
    eval $@
  fi
}

BRANCH_NEW="cherry-pick/auto-$GITHUB_SHA"

MESSAGE=$(git log -1 $GITHUB_SHA | grep "AUTO" | wc -l)

if [[ $MESSAGE -gt 0 ]]; then
  echo "Autocommit, NO ACTION"
  exit 0
fi

PR_TITLE=$(git log -1 --format="%s" $GITHUB_SHA)

git_setup
git_cmd git remote update
git_cmd git fetch --all
git_cmd git checkout -b "${BRANCH_NEW}" origin/develop
git_cmd git push -u origin "${BRANCH_NEW}"
git_cmd git checkout -b origin/develop
git_cmd git hub "https://github.com/${USER_GITHUB}/${PROJECT_NAME}/commit/${GITHUB_SHA}"
