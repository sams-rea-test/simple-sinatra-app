# Acknowledging that that base image choices are likely to be dependent on organisational policy/preferences and how
# high of a priority reducing image sizes is. For simplicity's sake, I'm pulling in the official `ruby:2.4` image
# (based on Debian). This could be replaced with `2.4-alpine` if cutting down on image sizes was important
# (Alpine dist reduces base image size from 271MB to 28MB).
# There isn't an official rhel base image release for ruby, but this could be built up if necessary - Centos do provide
# a ruby 2.2 release as `centos/ruby-22-centos7:latest` though.
FROM ruby:2.4

# Allow the install directory to be customised at build time, but default to /app because it's sane.
ARG APP_BASE_PATH=/app
# Runtime environment is a flag we'd change for dev purposes, but probably almost always run as 'production' outside
# of a developer's machine
ENV RACK_ENV=production

WORKDIR ${APP_BASE_PATH}

# Copy in the Gemfile early, so that iterations upon the rest of the "app" contents don't cause us to unnecessarily
# rebuild our dependencies.
COPY Gemfile ${APP_BASE_PATH}/
# Note: `set -xe` makes the build logs verbose as to what commands are being run, although this one is a simple one-liner,
# as a practice I still do it to maintain consistency & to reduce vcs noise if the commands grow later.
# (Same goes with ending run commands in `true`.)
RUN set -xe && \
    bundle install && \
    true

# Copy in the remainder of the application. If we had other tasks that needed to run before copying in other source
# e.g. a node/front-end tooling install, we would do that before this as well.
COPY config.ru helloworld.rb ${APP_BASE_PATH}/

# Default boot command is to run the app server via rackup and to set the bind address and port. Seems simple enough?
CMD bundle exec rackup --port 80 --host 0.0.0.0