#!/bin/bash
# Script for watching git status of repositories
# Parameters:
# $1 - local recheck delay in seconds, default is 15s
# $2 - remote recheck delay in seconds, default is 300s
# $3 - search folder root, default is home folder of current user

ungit --no-b >/dev/null 2>&1 &  # run ungit in background
ungit_base='http://localhost:8448/#/repository?path='

echo "Searching for git repositories. This may take a while ..."

# run if user hits control-c
control_c() {
    remote_timeout=0
    echo "SIGINT received, remote refs update will be enforced."
    ungit --no-b >/dev/null 2>&1 &  # run ungit in background
    find_folders
}

find_folders() {
    folders=$(find "$froot" -type d -name ".git" | sort) 2>/dev/null
    
    for fold in $folders
    do
        rname="$(echo "$fold" | sed 's/.*\/\([^/]*\)\/.git/\1/')"
        rnamemax=$((${#rname} > $rnamemax ? ${#rname} : $rnamemax))
    done
}

# trap keyboard interrupt (control-c)
trap control_c SIGINT

ldelay=${1:-15}
rdelay=${2:-300}
froot=${3:-~}
rnamemax=0
remote_timeout=0
subs_cnt=1
re_sub='^.*/\.\./.*$'

ungit -h >/dev/null 2>&1
ungit_present=$?

find_folders

if [[ -z "$folders" ]]; then
    echo "No repositories found under '$froot'."
    exit 1
fi

# $1 repo path
# $2 padding
repo_info() {
    local rfold="$1"
    local padnum="${2-0}"
    local pad="$(printf "%$(echo "$padnum * 2" | bc)""s")"
    local reponame="$(echo "$rfold" | sed 's/.*\/\([^/]*\)\/.git/\1/')"
    local repofold="$(echo "$rfold" | sed 's/.git//')"    
    local spaces="$(printf "%$(echo "${#reponame} - $rnamemax - ($subs_cnt * 2) + ($padnum * 2)" | bc)""s")"
    local spaces_max="$(printf "%$(echo "($padnum + 1) * 2" | bc)""s")"
    local ustr

    if [[ "$ungit_present" -eq 0 ]]; then
        ustr="\n$spaces_max\e[0;34m$ungit_base$repofold\e[0m"
    else
        ustr="(cd $repofold)"
    fi
    
    if [[ ! -d "$repofold" || "$repofold" =~ $re_sub ]]; then
        return
    fi
    
    cd "$repofold"
        
    if [[ "$remote_timeout" -lt $(date +%s) ]]; then
        echo -e -n "$pad$reponame:$spaces updating remote refs ...\r"
        git remote update >/dev/null 2>&1
    fi
    status="$(git status)"
    
    if [[ "$status" =~ 'Your branch is behind' ]]; then
        echo -e "$pad$reponame: $spaces\e[0;31mpull needed\e[0m                 $ustr"
    elif [[ "$status" =~ 'Changes not staged for commit' || "$status" =~ 'Changes to be committed' ]]; then
        echo -e "$pad$reponame: $spaces\e[0;31mcommit needed\e[0m               $ustr"
    elif [[ "$status" =~ 'Your branch is ahead' ]]; then
        echo -e "$pad$reponame: $spaces\e[0;31mpush needed\e[0m                 $ustr"
    elif [[ "$status" =~ 'Untracked files' ]]; then
        echo -e "$pad$reponame: $spaces\e[0;31madd needed\e[0m                  $ustr"
    elif [[ "$status" =~ 'nothing to commit' ]]; then
        echo -e "$pad$reponame: $spaces\e[0;32mOK\e[0m                          "
    else
        echo -e "$pad$reponame: $spaces\e[0;31mstate unknown\e[0m               $ustr"
    fi
    
    for submod in $(git submodule | awk '{ print $2 }'); do
        repo_info "$repofold$submod/.git" "$(expr "$padnum" + 1)"
    done
}

while true
do
    sleep 1
    clear
    
    for fold in $folders
    do        
        repo_info "$fold"
    done
    
    if [[ "$remote_timeout" -lt $(date +%s) ]]; then
        remote_timeout=$(echo "$(date +%s) + $rdelay" | bc)
    fi
    
    sleep "$ldelay"
done
