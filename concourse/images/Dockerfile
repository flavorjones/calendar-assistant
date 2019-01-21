FROM ruby:latest
LABEL maintainer=mike.dalessio@gmail.com

COPY Gemfile                           calendar-assistant/
COPY Gemfile.lock                      calendar-assistant/
COPY calendar-assistant.gemspec        calendar-assistant/
COPY lib/calendar_assistant/version.rb calendar-assistant/lib/calendar_assistant/

RUN cd calendar-assistant && bundle install
