#!/usr/bin/env bash

# This script implements the whole proj machinery. It needs to be sourced, and
# all the commands are just functions

shopt -s expand_aliases

##############################################################
#
#               Configuration parameters
#
##############################################################

# The following parameters can be overridden by environment variables anytime.

# This is the directory where the database file is kept, together with this
# very script.
PROJ_BASE="${PROJ_BASE:-$HOME/.projects}"

# This is the database file, containing the mapping project name -> directory.
PROJ_DB_FILE="${PROJ_DB_FILE:-$PROJ_BASE/projects}"

##############################################################
#
#                   Utility functions
#
##############################################################

# The functions named _activate-* attempt to activate a certain
# language-specific environment. They are assumed to be run in the directory
# where the attempt should be made, and suppress standard error of the used
# commands: in fact possible errors are just a signal that the language
# doesn't need to be set up for the project, rather than real errors.

# This function activates the correct version of node. It supports the
# following version managers:
#     - nvm
#     - my own n fork
#     - n
function _activate-node {
    # Trying nvm first, then my fork of n. If successful, we are done here.
    # NOTE: The if statement is necessary, since grouping the || spawns a
    #       subshell. Therefore, nvm and n would change the environment of
    #       such shell rather than the current one.
    if nvm use 2> /dev/null || n use 2> /dev/null; then
        return 0
    fi

    # Trying basic n.
    # NOTE: Since the version needs to be passed explicitly, a file containing
    #       it should be present. It this is not the case, the attempt
    #       shouldn't be made, in order to avoid a bash error message about
    #       missing input file for input redirection.
    local VERSION_FILE=./.nvmrc
    [[ -f "$VERSION_FILE" ]] && < "$VERSION_FILE" xargs n 2> /dev/null
}

# This function activates the correct version of ruby. It supports the
# following version managers:
#     - rvm
function _activate-ruby {
    # Trying rvm
    rvm use 2> /dev/null
}

# This function activates the correct python virtual environment. It supports
# the following managers:
#   - virtualenvwrapper
#   - venv/virtualenv
#
# Arguments:
#   - $1: The virtualenvwrapper name of the virtual environment.
function _activate-python {
    local NAME="$1"

    # Trying virtualenvwrapper.
    # NOTE: If successful, `workon` might change the current working directory.
    #       While this is assumed to be correct, the directory where `workon`
    #       was executed would needlessly pollute the $OLDPWD variable, that is
    #       hence saved before the command and restored in case of success.
    local OLD_PWD="$OLDPWD"
    if workon "$NAME" 2> /dev/null; then
        OLDPWD="$OLD_PWD"
        return 0
    fi

    # Trying venv/virtualenv. The virtual environment root directory is
    # assumed to be located in the current directory subtree. It is detected
    # as the first directory containing an executable `bin/python` file. The
    # `activate` script in the same `bin` directory is then sourced.
    # shellcheck disable=SC2091
    source "$(find . -type f -executable -path '*/bin/python' \
        -exec dirname '{}' \; | head -n 1)/activate" 2> /dev/null
}

# This function implements autocompletion over project names. No other words
# are added after the first. It is meant to be passed directly to the complete
# built-in via the -F option. Hence, the arguments are the one passed by
# complete itself.
#
# Arguments:
#   - $1: The name of the command whose arguments are being completed.
#   - $2: The word being completed.
#   - $3: The word preceding the word being completed.
function _proj-complete {
    local CMD="$1"
    local CURR_WORD="$2"
    local PREV_WORD="$3"

    # Not first word being completed, no need to add anything
    [[ "$PREV_WORD" != "$CMD" ]] && return 0

    # List of all project names
    local PROJECTS
    PROJECTS=$(cut -d$'\t' -f 1 "$PROJ_DB_FILE")

    # using compgen to filter the project based on the current word
    mapfile -t COMPREPLY < <(compgen -W "${PROJECTS[*]}" "$CURR_WORD")
}

# This function implements autocompletion over project names if it is the first
# word being completed, and over directories if it is the second one. No words
# will be added after the second. It is meant to be passed directly to the
# complete built-in via the -F option. Hence, the arguments are the one passed
# by complete itself.
#
# Arguments:
#   - $1: The name of the command whose arguments are being completed.
#   - $2: The word being completed.
#   - $3: The word preceding the word being completed.
function _add-complete {
    local CMD="$1"
    local CURR_WORD="$2"
    local PREV_WORD="$3"

    # The previous word is the command, this is the first completed word.
    if [[ "$PREV_WORD" == "$CMD" ]]; then
        _proj-complete "$@"

    # The previous word is neither the command nor a directory, completing
    # over directory names.
    elif [[ ! -d "$PREV_WORD" ]]; then
        mapfile -t COMPREPLY < <(compgen -d "$CURR_WORD")
    fi
}

# This function searches a project in the database file, returning the whole
# line on standard output.
#
# Arguments:
#   - $1: The name of the project being searched.
function _search-project {
    grep -wP "^$1" "$PROJ_DB_FILE"
}

##############################################################
#
#                       Commands
#
##############################################################

# The following functions are meant as the shell commands to manage projects.

# This function adds/modifies a project to/in the mapping. The base directory
# of the project is cd-ed into by the function.
#
# Arguments:
#   - $1: The project to be added/modified.
#   - $2: The base directory of the project, either relative or absolute path.
function add-proj {
    local PROJECT="$1"
    local BASE
    BASE="$(readlink -f "$2")"

    # If a parent directory in a path doesn't exist, readlink prints nothing
    if [[ -z "$BASE" ]]; then
        echo >&2 "A parent of project base directory $2 doesn't exist!"
        return 2
    fi
    if ! cd "$BASE" &> /dev/null; then
        echo >&2 "Project base directory $BASE doesn't exist!"
        return 3
    fi

    local DB_ENTRY="$PROJECT\t$BASE"

    # Editing with sed if the project exists, else appending the new entry.
    _search-project "$PROJECT" &> /dev/null \
        && sed -Ei "s|^$PROJECT.+$|$DB_ENTRY|" "$PROJ_DB_FILE" \
        || echo -e "$DB_ENTRY" >> "$PROJ_DB_FILE"
}

# This function deletes a project from the mapping. Supports autocompletion.
#
# Argument:
#   - $1: The name of the project to be deleted.
function del-proj {
    local PROJECT="$1"

    # If the project does nto exist, it is simply not deleted.
    sed -i "/^$PROJECT/d" "$PROJ_DB_FILE"
}

# This alias displays the current mapping. Given the database file format,
# displaying the files is enough.
# shellcheck disable=2139
alias ls-proj="cat $PROJ_DB_FILE"

# This function behaves like add-proj, with the addition of creating the
# project base directory if it does not exist.
#
# Arguments:
#   - $1: The project to be added/modified.
#   - $2: The base directory of the project, either relative or absolute path.
function new-proj {
    local BASE="$2"

    # Creating base directory if it doesn't exist.
    mkdir -p "$BASE"

    # Executing the same actions as add-proj
    add-proj "$@"
}

# This function activatea a project. This means that it cd-s into the
# directory the project is mapped to, if any, and proceeds to attept the
# language-specific setups. It supports autocompletion.
#
# Arguments:
#   - $1: The name of the project to be activated.
function proj {
    local PROJECT="$1"

    # The project database entry is saved in a variable to ease the use of
    # the read built-it via herestrings.
    local DB_ENTRY
    DB_ENTRY=$(_search-project "$PROJECT")
    if [[ "$?" -ne 0 ]]; then
        echo >&2 "Project $PROJECT not found!"
        return 2
    fi

    read NAME BASE <<<"$DB_ENTRY"

    if ! cd "$BASE" &> /dev/null; then
        echo >&2 "Project base directory $BASE doesn't exist!"
        return 2
    fi

    # Attempting to setup all the language-specific environments. Both the
    # project name and the base directory are passed even when not necessary,
    # for future use.
    _activate-node "$NAME" "$BASE"
    _activate-ruby "$NAME" "$BASE"
    _activate-python "$NAME" "$BASE"
}

##############################################################
#
#                           Setup
#
##############################################################

# Creating base directory and database files if they don't exist.
mkdir -p "$PROJ_BASE"
touch "$PROJ_DB_FILE"

# Setting autocompletion on project names only.
complete -F _proj-complete del-proj proj

# Setting autocompletion for project names first and then directories.
complete -F _add-complete add-proj
