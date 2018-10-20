#! /usr/bin/env bash

set -e -x -u

pushd calendar-assistant

  bundle install
  bundle exec rake spec

popd
