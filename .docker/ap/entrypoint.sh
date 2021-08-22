#!/usr/bin/env bash
set -Eeo pipefail

function bootstrap(){
    if [ -f ./Gemfile ]; then
        bundle install
        bin/rails db:create db:migrate
    fi
}

function print_container_info(){
    echo

    cat << EOS
container info.
    $(. /etc/os-release && echo ${PRETTY_NAME})
    ruby    $(ruby --version)
    gem     $(gem --version)
    bundle  $(bundle --version)
    git     $(git version)
    node    $(node --version)
    npm     $(npm --version)
    yarn    $(yarn --version)
    rails   $(bundle exec rails --version)
    sqlite3 $(sqlite3 --version)
    mysql   $(mysql --version)
    psql    $(psql --version)
    sqlcmd  $(sqlcmd -? | head -n 2 | tail -n 1)

    user    $(id)
    workdir $(pwd)
            $(ls -lad $(pwd))
    date    $(date)

EOS

    for K in 'LANG' 'TZ' \
            'HTTP_PROXY' 'HTTPS_PROXY' 'FTP_PROXY' 'NO_PROXY' \
            'http_proxy' 'https_proxy' 'ftp_proxy' 'no_proxy'
    do
        echo "    ${K}=$(eval echo '$'${K})"
    done

    echo
}

(bootstrap)
(print_container_info)

exec "$@"