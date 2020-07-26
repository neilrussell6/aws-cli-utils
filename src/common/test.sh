. "print.consts.sh"
. "print.utils.sh"

arr=( "AAA" "BBB" "C CC" )
printList -l "${arr[@]}"

str="AAA;BBB;C CC"
printList -l "$str" -s ";"
