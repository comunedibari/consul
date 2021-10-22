#!/usr/bin/env bash

set -x

PID_FILE="$RAILS_ROOT/tmp/pids/server.pid"

if [[ -f "$PID_FILE" ]]; then
    kill -9 $(cat "$PID_FILE")
    rm -rf $PID_FILE
else
    rake db:setup env=${RAILS_ENV} RAILS_ENV=${RAILS_ENV}
    rake db:migrate env=${RAILS_ENV} RAILS_ENV=${RAILS_ENV}
    rake db:seed init="development"
    rake db:seed update="2019-09-04" && rake db:seed update="2019-10-18" && rake db:seed update="2019-11-18" && rake db:seed update="2020-01-17" && rake db:seed update="2020-04-10" && rake db:seed update="2020-04-20" && rake db:seed update="2020-12-03" && rake db:seed update="2021-04-21"
    if [[ "${PRECOMPILE_ASSETS}" = true ]]; then
        rake assets:precompile env=${RAILS_ENV} RAILS_ENV=${RAILS_ENV}
    fi
fi

bundle exec rails server -b 0.0.0.0
