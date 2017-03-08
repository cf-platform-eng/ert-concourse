#!/usr/bin/env bash

# From https://github.com/fsaintjacques/semver-tool

set -o errexit -o nounset -o pipefail

SEMVER_REGEX="^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(\-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$"

PROG=semver
PROG_VERSION=2.0.0

VERSION_FILE=${VERSION_FILE:-.version}
DEFAULT_VERSION=0.1.0

USAGE="\
Usage:
  $PROG bump (major|minor|patch|prerel <prerel>|build <build>) <version>
  $PROG compare <version> <other_version>
  $PROG --help
  $PROG --version

Arguments:
  <version>  A version must match the following regex pattern:
             \"${SEMVER_REGEX}\".
             In english, the version must match X.Y.Z(-PRERELEASE)(+BUILD)
             where X, Y and Z are positive integers, PRERELEASE is an optionnal
             string composed of alphanumeric characters and hyphens and
             BUILD is also an optional string composed of alphanumeric
             characters and hyphens.

  <other_version>  See <version> definition.

  <prerel>  String that must be composed of alphanumeric characters and hyphens.

  <build>   String that must be composed of alphanumeric characters and hyphens.

Options:
  -v, --version          Print the version of this tool.
  -h, --help             Print this help message.

Commands:
  bump     Bump <version> by one of major, minor, patch, prerel, build
           or a forced potentialy conflicting version. The bumped version is
           shown to stdout.

  compare  Compare <version> with <other_version>, output to stdout the
           following values: -1 if <other_version> is newer, 0 if equal, 1 if
           older."


function warning {
  echo -e "$1" >&2
}

function error {
  echo -e "$1" >&2
  exit 1
}

function usage-help {
  error "$USAGE"
}

function usage-version {
  echo -e "${PROG}: $PROG_VERSION"
  exit 0
}

function validate-version {
  local version=$1
  if [[ "$version" =~ $SEMVER_REGEX ]]; then
    # if a second argument is passed, store the result in var named by $2
    if [ "$#" -eq "2" ]; then
      local major=${BASH_REMATCH[1]}
      local minor=${BASH_REMATCH[2]}
      local patch=${BASH_REMATCH[3]}
      local prere=${BASH_REMATCH[4]}
      local build=${BASH_REMATCH[5]}
      eval "$2=(\"$major\" \"$minor\" \"$patch\" \"$prere\" \"$build\")"
    else
      echo "$version"
    fi
  else
    error "version $version does not match the semver scheme 'X.Y.Z(-PRERELEASE)(+BUILD)'. See help for more information."
  fi
}

function compare-version {
  validate-version "$1" V
  validate-version "$2" V_

  # MAJOR, MINOR and PATCH should compare numericaly
  for i in 0 1 2; do
    local diff=$((${V[$i]} - ${V_[$i]}))
    if [[ $diff -lt 0 ]]; then
      echo -1; return 0
    elif [[ $diff -gt 0 ]]; then
      echo 1; return 0
    fi
  done

  # PREREL should compare with the ASCII order.
  if [[ -z "${V[3]}" ]] && [[ -n "${V_[3]}" ]]; then
    echo -1; return 0;
  elif [[ -n "${V[3]}" ]] && [[ -z "${V_[3]}" ]]; then
    echo 1; return 0;
  elif [[ -n "${V[3]}" ]] && [[ -n "${V_[3]}" ]]; then
    if [[ "${V[3]}" > "${V_[3]}" ]]; then
      echo 1; return 0;
    elif [[ "${V[3]}" < "${V_[3]}" ]]; then
      echo -1; return 0;
    fi
  fi

  echo 0
}

function command-bump {
  local new; local version; local sub_version; local command;

  case $# in
    2) case $1 in
        major|minor|patch) command=$1; version=$2;;
        *) usage-help;;
       esac ;;
    3) case $1 in
        prerel|build) command=$1; sub_version=$2 version=$3 ;;
        *) usage-help;;
       esac ;;
    *) usage-help;;
  esac

  validate-version $version split
  local major=${split[0]}
  local minor=${split[1]}
  local patch=${split[2]}
  local prere=${split[3]}
  local build=${split[4]}

  case "$command" in
    major) new="$(($major + 1)).0.0";;
    minor) new="${major}.$(($minor + 1)).0";;
    patch) new="${major}.${minor}.$(($patch + 1))";;
    prerel) new=$(validate-version "${major}.${minor}.${patch}-${sub_version}");;
    build) new=$(validate-version "${major}.${minor}.${patch}${prere}+${sub_version}");;
    *) usage-help ;;
  esac

  echo $new
  exit 0
}

function command-compare {
  local v; local v_;

  case $# in
    2) v=$(validate-version "$1"); v_=$(validate-version "$2") ;;
    *) usage-help ;;
  esac

  echo $(compare-version "$v" "$v_")
  exit 0
}

case $# in
  0) cli-print ;;
esac

case $1 in
  --help|-h) echo -e "$USAGE"; exit 0;;
  --version|-v) usage-version ;;
  bump) shift; command-bump $@;;
  compare) shift; command-compare $@;;
  *) echo "Unknown arguments: $@"; usage-help;;
esac
