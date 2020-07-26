function cform_usage() {
  local name=$1
  cat <<EOF
Usage: $name <[options]>
Options:
  -h --help       Show help [flag]
  list-resources  List resources for stack
EOF
}

function cform_main() {
  local name="aws-bash-utils cform"
  local target=$1

  if [[ $# -eq 1 ]]; then
    case "$1" in
      --help|-h)  cform_usage "$name"; exit 0 ;;
    esac
  fi

  shift

  case "$target" in
    list-resources) cform_list_resources $@ ;;
    *)              print "invalid arguments" LIGHTRED; echo ""
                    cform_usage "$name"
                    exit 1
                    ;;
  esac
}
