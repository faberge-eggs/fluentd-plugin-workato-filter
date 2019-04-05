FROM ruby:2.5
MAINTAINER sh.vadim@gmail.com
ARG path=/project

RUN apt-get update -q && apt-get -y upgrade
# RUN apt-get install -y build-essential libaio1 libc6-dev libssl1.0-dev unzip cmake
RUN mkdir $path

RUN gem install bundler

RUN gem install --no-document fluentd -v "~> 1.2.6"
WORKDIR /tmp
COPY Gemfile /tmp
COPY fluentd-plugin-workato-filter.gemspec /tmp
COPY Gemfile.lock /tmp
RUN bundle install

WORKDIR $path

COPY . $path
