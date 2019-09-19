#!/bin/bash

gem build fluentd-plugin-workato-filter.gemspec
cp pkg/fluentd-plugin-workato-filter-0.0.2.gem ../docker-fluentd/
