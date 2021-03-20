#! /usr/bin/env bash

set -e -x -u

ruby -v

source "$(dirname "$0")/code-climate.sh"

code-climate-setup

bundle config set --local without 'optional'
bundle install --local || bundle install
bundle exec rake

code-climate-shipit
