#! /usr/bin/env bash

set -e -x -u

source "$(dirname "$0")/../../shared/code-climate.sh"

pushd calendar-assistant

  code-climate-setup

  bundle install --without=optional
  bundle exec rake

  code-climate-shipit

popd
