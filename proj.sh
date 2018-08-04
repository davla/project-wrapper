#!/usr/bin/env bash

PROJ_BASE="${PROJ_BASE:-$HOME/.projects}"
PROJ_DB_FILE="${PROJ_DB_FILE:-$PROJ_BASE/projects}"

shopt -s expand_aliases
# shellcheck disable=2139
alias ls-proj="cat $PROJ_DB_FILE"

function _activate-node {
    if nvm use 2> /dev/null || n use 2> /dev/null; then
        return 0
    fi

    if [[ "$(type -t n)" == 'file' ]]; then
        local VERSION_FILE=./.nvmrc
        if [[ ! -f "$VERSION_FILE" ]]; then
            echo >&2 "No node version specified in $BASE"
            return 3
        fi
        < "$VERSION_FILE" xargs n 2> /dev/null
    fi
}

function _activate-ruby {
    rvm use 2> /dev/null
}

function _activate-python {
    local NAME="$1"

    local OLD_PWD="$OLDPWD"
    if workon "$NAME" 2> /dev/null; then
        OLDPWD="$OLD_PWD"
        return 0
    fi

    # shellcheck disable=SC2091
    source "$(find . -path '*/bin/python' -exec dirname '{}' \; | head -n 1)\
/activate" 2> /dev/null
}

function _proj-complete {
    local CURR_WORD="$2"

    local PROJECTS
    PROJECTS=$(cut -d$'\t' -f 1 "$PROJ_DB_FILE")

    COMPREPLY=($(compgen -W "${PROJECTS[*]}" "$CURR_WORD"))
}

function _search-project {
    grep -wP "^$1" "$PROJ_DB_FILE"
}

function proj {
    local PROJECT="$1"

    local LINE
    LINE=$(_search-project "$PROJECT")
    if [[ "$?" -ne 0 ]]; then
        echo >&2 "Project $PROJECT not found!"
        return 2
    fi

    read NAME BASE <<<"$LINE"

    if ! cd "$BASE" &> /dev/null; then
        echo >&2 "Project base directory $BASE doesn't exist!"
        return 2
    fi

    _activate-node "$NAME" "$BASE"
    _activate-ruby "$NAME" "$BASE"
    _activate-python "$NAME" "$BASE"
}

function add-proj {
    local PROJECT="$1"
    local BASE
    BASE="$(readlink -f "$2")"

    if ! cd "$BASE" &> /dev/null; then
        echo >&2 "Project base directory $BASE doesn't exist!"
        return 2
    fi

    local DB_ENTRY="$PROJECT\t$BASE"
    _search-project "$PROJECT" &> /dev/null \
        && sed -i "s|^$PROJECT.+$|$DB_ENTRY|" "$PROJ_DB_FILE" \
        || echo -e "$DB_ENTRY" >> "$PROJ_DB_FILE"
}

function del-proj {
    local PROJECT="$1"

    sed -i "/^$PROJECT/d" "$PROJ_DB_FILE"
}

function new-proj {
    local BASE
    BASE="$(readlink -f "$2")"

    mkdir -p "$BASE"
    add-proj "$@"
}


complete -F _proj-complete proj del-proj
