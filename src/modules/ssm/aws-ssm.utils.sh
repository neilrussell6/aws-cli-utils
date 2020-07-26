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
  -j      --json      Output as JSON [flag]
EOF
}

function ssm_get() {
  local name="aws-bash-utils ssm get"
  local args=( )

  for x; do
    case "$x" in
      --help)   args+=( -h ) ;;
      --path)   args+=( -p ) ;;
      --json)   args+=( -j ) ;;
      *)        args+=( "$x" ) ;;
    esac
  done

  set -- "${args[@]}"

  local outputAsJSON=0

  unset OPTIND
  while getopts ":hjp:" x; do
    case "$x" in
      h)  ssm_get_usage "$name"; exit 0 ;;
      j)  outputAsJSON=1 ;;
      p)  local path="$OPTARG" ;;
    esac
  done

  if [[ -z "$path" ]]; then
    print "invalid arguments" LIGHTRED; echo ""
    ssm_get_usage "$name"
    exit 1
  fi

  if [[ "${outputAsJSON}" -eq "1" ]]; then
    aws ssm get-parameters-by-path --path $path --query 'Parameters[*].{Name:Name, Value:Value, Version:Version}' --recursive
  else
    aws ssm get-parameters-by-path --path $path --query 'Parameters[*].{Name:Name, Value:Value, Version:Version}' --output table --recursive
  fi
}

# --------------------------------
# put
# AWS_PROFILE=<PROFILE> aws-bash-utils ssm put -p /dev/foo/bar=baz
# AWS_PROFILE=<PROFILE> aws-bash-utils ssm put -p "/dev/hello/world=some value"
# AWS_PROFILE=<PROFILE> aws-bash-utils ssm put -p "/dev/hello/world=some url" -u
# --------------------------------

function ssm_put_usage() {
  local name=$1
  cat <<EOF
Usage: $name <[options]>
Options:
  -h      --help      Show help [flag]
  -p -pV  --path      Param path and value [string]
  -g -ng  --no-get    Do not retrieve params after update / create [flag]
  -u      --url       Do not retrieve URL value
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
      --url|-u)       args+=( -u ) ;;
      *)              args+=( "$x" ) ;;
    esac
  done

  set -- "${args[@]}"

  local get=1
  local isUrlValue=0

  unset OPTIND
  while getopts ":hugp:" x; do
    case "$x" in
      h)  ssm_put_usage "$name"; exit 0 ;;
      p)  local pathAndValue="$OPTARG" ;;
      u)  isUrlValue=1 ;;
      g)  get=0 ;;
    esac
  done

  if [[ -z "${pathAndValue}" ]]; then
    print "invalid arguments" LIGHTRED; echo ""
    ssm_put_usage "$name"
    exit 1
  fi

  local path=$(cut -d "=" -f 1 <<< $pathAndValue)
  local value=$(cut -d "=" -f 2 <<< $pathAndValue)

  print "${path} = ${value}"; echo ""

  echo $isUrlValue
  if [[ "${isUrlValue}" -eq "1" ]]; then
    aws ssm put-parameter --cli-input-json "{\"Type\": \"String\", \"Name\": \"${path}\", \"Value\": \"${value}\"}" --overwrite
  else
    aws ssm put-parameter --type String --name "${path}" --value "${value}" --overwrite
  fi

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

  local rootPath=$(cat $file | jq 'keys | .[0]' | tr -d '"')
  local currentJSON=$(ssm_get -p "/${rootPath}" -j)
  local newJSON=$(cat $file)

  echo $newJSON | jq -c 'paths(scalars) as $p | [($p | join("/")), getpath($p)]' | while read -r x; do
    local key=$(echo $x | jq .[0] | tr -d '"')
    local value=$(echo $x | jq .[1] | tr -d '"')
    local oldValue=$(echo "${currentJSON}" | jq --arg v "/${key}" -c '.[] | select( .Name == $v ) | .Value' | tr -d '"')
    if [[ "${value}" == "${oldValue}" ]]; then
      print "${key}" WHITE; print "NO CHANGE" GREY; echo ""
    else
      print "${key}  [CHANGED]" LIME; print "updating ..." GREY; echo ""
      ssm_put -p "/${key}=${value}" -nG -u
    fi
  done

  ssm_get -p "/${rootPath}"
}
