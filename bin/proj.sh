#!/usr/bin/env bash

BASE_DIR="$HOME/.projects"
DB_FILE="$BASE_DIR/projects"

shopt -s expand_aliases
# shellcheck disable=2139
alias ls-proj="cat $DB_FILE"

function search-project {
    grep -wP "^$1" "$DB_FILE"
}

function activate-node {
    local NAME="$1"
    local BASE="$2"
    local TYPE="$3"

    if nvm use 2> /dev/null || n use 2> /dev/null; then
        return 0
    fi

    if [[ "$(type -t n)" == 'file' ]]; then
        local VERSION_FILE="$BASE/.nvmrc"
        if [[ ! -f "$VERSION_FILE" ]]; then
            echo >&2 "No node version specified in $BASE"
            return 3
        fi
        < "$VERSION_FILE" xargs n 2> /dev/null
    fi
}

function activate-ruby {
    local NAME="$1"
    local BASE="$2"
    local TYPE="$3"

    rvm use 2> /dev/null
}

function activate-python {
    local NAME="$1"
    local BASE="$2"
    local TYPE="$3"

    local OLD_PWD="$OLDPWD"
    if workon "$NAME" 2> /dev/null; then
        OLDPWD="$OLD_PWD"
        return 0
    fi

    # shellcheck disable=SC2091
    source "$(find . -path '*/bin/python' -exec dirname '{}' \; | head -n 1)\
/activate" 2> /dev/null
}

function proj {
    local PROJECT="$1"

    local LINE
    LINE=$(search-project "$PROJECT")
    if [[ "$?" -ne 0 ]]; then
        echo >&2 "Project $PROJECT not found!"
        return 2
    fi

    read NAME BASE TYPE <<<"$LINE"

    if ! cd "$BASE" &> /dev/null; then
        echo >&2 "Project base directory $BASE doesn't exist!"
        return 2
    fi

    activate-node "$NAME" "$BASE" "$TYPE"
    activate-ruby "$NAME" "$BASE" "$TYPE"
    activate-python "$NAME" "$BASE" "$TYPE"
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
    search-project "$PROJECT" &> /dev/null \
        && sed -i "s|^$PROJECT.+$|$DB_ENTRY|" "$DB_FILE" \
        || echo -e "$DB_ENTRY" >> "$DB_FILE"
}

function del-proj {
    local PROJECT="$1"

    sed -i "/^$PROJECT/d" "$DB_FILE"
}

function new-proj {
    local BASE
    BASE="$(readlink -f "$2")"

    mkdir -p "$BASE"
    add-proj "$@"
}
