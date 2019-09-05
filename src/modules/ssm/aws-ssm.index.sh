#!/usr/bin/env bash

function ssm_usage() {
  local name=$1
  cat <<EOF
Usage: $name <[options]>
Options:
  -h --help     Show help [flag]
  get           Get params by path
  put           Update or Create a single param by path
  putjson       Update or Create multiple params by providing a JSON file
EOF
}

function ssm_main() {
  local name="aws-bash-utils ssm"
  local target=$1

  if [[ $# -eq 1 ]]; then
    case "$1" in
      --help|-h)  ssm_usage "$name"; exit 0 ;;
    esac
  fi

  shift

  case "$target" in
    get)      ssm_get $@ ;;
    put)      ssm_put $@ ;;
    putjson)  ssm_putjson $@ ;;
    *)        print "invalid arguments" LIGHTRED; echo ""
              ssm_usage "$name"
              exit 1
              ;;
  esac
}
