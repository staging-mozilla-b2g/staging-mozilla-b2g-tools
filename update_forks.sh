#!/bin/bash

set -xe

PROD_ORG=mozilla-b2g
STAGE_ORG=staging-mozilla-b2g
REPO_BASE_PATH=.repo_cache

log () {
    echo $(date) "$@" >> update_forks.log
}

fix_remotes () {
    repo="$1" ; shift
    # Let's be lazy instead of inspecting for their existance first
    (cd "$repo" &&
        git remote add production "https://github.com/$PROD_ORG/$name" | true )
    (cd "$repo" &&
        git remote add staging "git@github.com:$STAGE_ORG/$name" | true )
}

update_repository () {
    repo="$1" ; shift
    name=$(basename $repo)

    if [ ! -d "$repo" ] ; then
        mkdir "$repo"
        (cd "$repo" && git init)
    fi

    fix_remotes "$repo"

    (cd "$repo" && git fetch production)

    if [ $? -ne 0 ] ; then
        log "ERROR: failed to fetch production for $name"
    fi

    for branch in $(git ls-remote "$repo" |
        grep refs/remotes/production |
        cut -f2 |
        sed "s,refs/remotes/production/,,")
    do
        (cd "$repo" && git push staging "refs/remotes/production/$branch:$branch" )
        if [ $? -ne 0 ] ; then
            log "ERROR: failed to push $branch to staging for $name"
        fi
    done
    log "INFO: finished updating $name"
}

mkdir -p "$REPO_BASE_PATH"
for repository in $(cat repos_to_update) ; do
    if [ "x$repository" != "x" ] ; then
        update_repository $REPO_BASE_PATH/$repository
    fi
done
