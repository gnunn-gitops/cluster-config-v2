rm -rf ./tmp
mkdir tmp
cd tmp

oc image extract --dir=./tmp ${1}
