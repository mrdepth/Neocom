find ./input/sde/ -name "*.yaml" -exec bash -c 'echo $1; ./yaml2json $1 > "${1%.yaml}".json' - {} \;
find ./input/sde/ -name "*.staticdata" -exec bash -c 'echo $1; ./yaml2json $1 > "${1%.staticdata}".json' - {} \;

