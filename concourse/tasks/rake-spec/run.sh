#! /usr/bin/env bash

set -e -x -u

pushd calendar-assistant

  bundle install --without=development
  bundle exec rake spec

popd
