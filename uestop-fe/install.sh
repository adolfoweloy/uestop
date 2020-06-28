#!/bin/bash
set -ue

## getting the parameter(s)
PROJECT_NAME=$1
CURRENT_DIR=$(pwd)

## clone the repo to be used as the react template project
REPO="git@github.com:adolfoweloy/react-template-project.git"
git clone ${REPO} ${PROJECT_NAME}

## changes package name
cd ${PROJECT_NAME}
cat package.json | sed s/react\-experiments/${PROJECT_NAME}/g > ${CURRENT_DIR}/${PROJECT_NAME}/newpackage.json
mv "${CURRENT_DIR}/${PROJECT_NAME}/newpackage.json" "${CURRENT_DIR}/${PROJECT_NAME}/package.json"

## disconnect from git and initializes a new repo
rm -rf "${CURRENT_DIR}/${PROJECT_NAME}/.git"
git init && git add . && git commit -m "Initial commit"