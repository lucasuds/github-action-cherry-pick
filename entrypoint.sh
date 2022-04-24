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
  git config --global --add safe.directory /github/workspace
}

git_cmd() {
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    echo $@
  else
    eval $@
  fi
}

BRANCH_NEW="cherry-pick/$GITHUB_SHA"

MESSAGE=$(git log -1 $GITHUB_SHA | grep "AUTO" | wc -l)

if [[ $MESSAGE -gt 0 ]]; then
  echo "Autocommit, NO ACTION"
  exit 0
fi

PR_TITLE=$(git log -1 --format="%s" $GITHUB_SHA)

echo "Configurando o git"
git_setup
echo "Atualizando o git na origin"
git_cmd git remote update
echo "Fetching todas branchs"
git_cmd git fetch --all
echo "Troca para develop"
git_cmd git checkout -b develop
git_cmd git pull
echo "Realizando o cherry-pick"
git_cmd hub cherry-pick "${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/commit/${GITHUB_SHA}"
echo "Criando a branch do cherry-pick"
git_cmd git checkout -b ${BRANCH_NEW}
echo "Atualizando todas as branchs"
git_cmd git push --all
