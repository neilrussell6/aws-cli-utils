#!/usr/bin/env bash

# --------------------------------
# get
# AWS_PROFILE=<PROFILE> aws-bash-utils ssm get -p /project/dev/user
# --------------------------------

function ssm_get_usage() {
  local name=$1
  cat <<EOF
Usage: $name <[options]>
Options:
  -h      --help      Show help [flag]
  -p      --path      Param path [string]
EOF
}

function ssm_get() {
  local name="aws-bash-utils ssm get"
  local args=( )

  for x; do
    case "$x" in
      --help)   args+=( -h ) ;;
      --path)   args+=( -p ) ;;
      *)        args+=( "$x" ) ;;
    esac
  done

  set -- "${args[@]}"

  unset OPTIND
  while getopts ":hp:" x; do
    case "$x" in
      h)  ssm_get_usage "$name"; exit 0 ;;
      p)  local path="$OPTARG" ;;
    esac
  done

  if [[ -z "$path" ]]; then
    print "invalid arguments" LIGHTRED; echo ""
    ssm_get_usage "$name"
    exit 1
  fi

  aws ssm get-parameters-by-path --path $path --query 'Parameters[*].{Name:Name, Value:Value, Version:Version}' --output table --recursive
}

# --------------------------------
# put
# AWS_PROFILE=<PROFILE> aws-bash-utils ssm put -p /dev/foo/bar=baz
# AWS_PROFILE=<PROFILE> aws-bash-utils ssm put -p "/dev/hello/world=some value"
# --------------------------------

function ssm_put_usage() {
  local name=$1
  cat <<EOF
Usage: $name <[options]>
Options:
  -h      --help      Show help [flag]
  -p -pV  --path      Param path and value [string]
  -g -ng  --no-get    Do not retrieve params after update / create [flag]
EOF
}

function ssm_put() {
  local name="aws-bash-utils ssm put"
  local args=( )

  for x; do
    case "$x" in
      --help)         args+=( -h ) ;;
      --path|-pV)     args+=( -p ) ;;
      --no-get|-nG)   args+=( -g ) ;;
      *)              args+=( "$x" ) ;;
    esac
  done

  set -- "${args[@]}"

  local get=1

  unset OPTIND
  while getopts ":hp:g" x; do
    case "$x" in
      h)  ssm_put_usage "$name"; exit 0 ;;
      p)  local pathAndValue="$OPTARG" ;;
      g)  get=0 ;;
    esac
  done

  if [[ -z "$pathAndValue" ]]; then
    print "invalid arguments" LIGHTRED; echo ""
    ssm_put_usage "$name"
    exit 1
  fi

  local path=$(cut -d "=" -f 1 <<< $pathAndValue)
  local value=$(cut -d "=" -f 2 <<< $pathAndValue)

  print "${path} = ${value}"; echo ""

  aws ssm put-parameter --type String --name "${path}" --value "${value}" --overwrite

  local rootPath=$(cut -d "/" -f 2 <<< $path)
  if [[ "$get" -eq "1" ]]; then
    ssm_get -p "/${rootPath}"
  fi
}

# --------------------------------
# put
# AWS_PROFILE=<PROFILE> aws-bash-utils ssm putjson -f <file>.json
# --------------------------------

function ssm_putjson_usage() {
  local name=$1
  cat <<EOF
Usage: $name <[options]>
Options:
  -h      --help      Show help [flag]
  -f      --file      JSON file to use as source for updating / adding params [string]
EOF
}

function ssm_putjson() {
  local name="aws-bash-utils ssm putjson"
  local args=( )

  for x; do
    case "$x" in
      --help)   args+=( -h ) ;;
      --file)   args+=( -f ) ;;
      *)        args+=( "$x" ) ;;
    esac
  done

  set -- "${args[@]}"

  unset OPTIND
  while getopts ":hf:" x; do
    case "$x" in
      h)  ssm_putjson_usage "$name"; exit 0 ;;
      f)  local file="$OPTARG" ;;
    esac
  done

  if [[ -z "$file" ]]; then
    print "invalid arguments" LIGHTRED; echo ""
    ssm_putjson_usage "$name"
    exit 1
  fi

  # TODO: make sure jq is available
  cat $file | jq -c 'paths(scalars) as $p | [($p | join("/")), getpath($p)] | join("=")' | tr -d '"' | while read -r x; do
    ssm_put -p "/${x}" -nG
  done

  local rootPath=$(cat $file | jq 'keys | .[0]' | tr -d '"')
  ssm_get -p "/${rootPath}"
}
