#! /usr/bin/env bash

set -e -x -u

pushd calendar-assistant

  bundle install --without=optional
  bundle exec license_finder

popd
