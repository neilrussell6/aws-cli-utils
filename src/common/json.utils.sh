tmp=$(mktemp)

function updateJSON() {
  target=$2
  if [[ $# -eq 3 ]]
    then target=$3
  fi
  jq --argjson d $1 -M '. * $d' $2 > "$tmp" && mv "$tmp" $target
}

function ssmToJSON() {
  echo "current"
  echo $1
  echo "new"
  echo $2
}
