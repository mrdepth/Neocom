find ./input/sde/ -name "*.yaml" -exec bash -c 'echo $1; cat $1 | python ./yaml2json.py > "${1%.yaml}".json' - {} \;
find ./input/sde/ -name "*.staticdata" -exec bash -c 'echo $1; cat $1 | python ./yaml2json.py > "${1%.staticdata}".json' - {} \;

