#!/bin/bash

set -e

__root_path=$(cd $(dirname $0); pwd -P)
devops_prj_path="$__root_path/devops"
source $devops_prj_path/base.sh

gitlab_image=gitlab/gitlab-ce
gitlab_container=gitlab

build() {
   run_cmd "docker pull $gitlab_image"
}

run() {
    local app_data_path='/opt/data/gitlab'
    args="--restart always"
    args="$args -p 22:22"
    args="$args -p 11180:80"

    # mount config
    args="$args -v $__root_path/config/sshd:/etc/pam.d/sshd"
    args="$args -v $__root_path/config/gitlab.rb:/etc/gitlab/gitlab.rb"

    args="$args -v $app_data_path/config:/etc/gitlab"
    args="$args -v $app_data_path/logs:/var/log/gitlab"
    args="$args -v $app_data_path/data:/var/opt/gitlab"
    run_cmd "docker run -d $args --name $gitlab_container $gitlab_image"
}

to_gitlab() {
    local args=""
    run_cmd "docker exec $docker_run_fg_mode $args $gitlab_container bash"
}

stop() {
    stop_container $gitlab_container
}

backup() {
    cmd='gitlab-rake gitlab:backup:create'
    run_cmd "docker exec $docker_run_fg_mode $args $gitlab_container $cmd"
}

restart() {
    stop
    run
}

help() {
	cat <<-EOF
    Usage: mamanger.sh [options]

    Valid options are:

        run
        to_gitlab
        stop
        restart
        backup
        -h                      show this help message and exit
EOF
	exit $1
}

ALL_COMMANDS="run stop restart"
ALL_COMMANDS="$ALL_COMMANDS backup to_gitlab"
list_contains ALL_COMMANDS "$action" || action=help
$action "$@"
