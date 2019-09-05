#!/usr/bin/env bash

# --------------------------------
# get
# AWS_PROFILE=<PROFILE> aws-bash-utils cform list-resources -s my-stack
# --------------------------------

function cform_list_resources_usage() {
  local name=$1
  cat <<EOF
Usage: $name <[options]>
Options:
  -h      --help      Show help [flag]
  -s      --stack     Stack name [string]
EOF
}

function cform_list_resources() {
  local name="aws-bash-utils cform list-resources"
  local args=( )

  for x; do
    case "$x" in
      --help)   args+=( -h ) ;;
      --stack)  args+=( -s ) ;;
      *)        args+=( "$x" ) ;;
    esac
  done

  set -- "${args[@]}"

  unset OPTIND
  while getopts ":hs:" x; do
    case "$x" in
      h)  cform_list_resources_usage "$name"; exit 0 ;;
      s)  local stack="$OPTARG" ;;
    esac
  done

  if [[ -z "$stack" ]]; then
    print "invalid arguments" LIGHTRED; echo ""
    cform_list_resources_usage "$name"
    exit 1
  fi

  # TODO: make sure jq is available
  aws cloudformation list-stack-resources --stack-name $stack --query 'StackResourceSummaries[*].{id:LogicalResourceId, type:ResourceType}' --output table
  echo ""
  local count=$(aws cloudformation list-stack-resources --stack-name $stack --query 'StackResourceSummaries[*].LogicalResourceId' | jq '. | length')
  print "resources:" LIGHTBLUE; echo $count; echo ""
}
