#!/usr/bin/env bash

function usage() {
  local name=$1
  cat <<EOF
Usage: $name <[options]>
Options:
  -h --help     Show help [flag]
  ssm           Param Store utils
  cform         Cloudformation utils
EOF
}

function main() {
  local name="aws-bash-utils"
  local target=$1

  if [[ $# -eq 1 ]]; then
    case "$1" in
      --help|-h)  usage "$name"; exit 0 ;;
    esac
  fi

  shift

  case "$target" in
    ssm)    ssm_main $@ ;;
    cform)  cform_main $@ ;;
    *)      print "invalid arguments" LIGHTRED; echo ""
            usage "$name"
            exit 1
            ;;
  esac
}

main $@
