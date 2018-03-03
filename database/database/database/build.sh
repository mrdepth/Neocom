out=${TEMP_DIR}

if [[ $ACTION = "clean" ]]; then
	find "$out" -name "*.sqlite" -type f -delete
	exit
fi

html=`curl https://developers.eveonline.com/resource/resources`
sde=`[[ "$html" =~ (http[^\"]*data\/sde\/tranquility\/[^\"]*zip) ]] && echo ${BASH_REMATCH[1]}`
icons=`[[ "$html" =~ (http[^\"]*data\/([^\"]*)_Icons.zip) ]] && echo ${BASH_REMATCH[1]}`
version=`[[ "$html" =~ (http[^\"]*data\/([^\"]*)_Icons.zip) ]] && echo ${BASH_REMATCH[2]}`
types=`[[ "$html" =~ (http[^\"]*data\/([^\"]*)_Types.zip) ]] && echo ${BASH_REMATCH[1]}`

if [[ -z $sde ]]; then
	echo "error: sde not found"
fi

if [[ -z $icons ]]; then
	echo "error: icons not found"
fi

if [[ -z $types ]]; then
	echo "error: types not found"
fi

if [[ -z $version ]]; then
	echo "error: version not found"
fi

cd $out
if [ ! -d "${version}" ]; then
	sdename=$(basename "${sde}")
	if [ ! -f "${sdename}" ]; then
		curl $sde -o "${sdename}"
	fi

	iconsname=$(basename "${icons}")
	if [ ! -f "${iconsname}" ]; then
		curl $icons -o "${iconsname}"
	fi

	typesname=$(basename "${types}")
	if [ ! -f "${typesname}" ]; then
		curl $types -o "${typesname}"
	fi

	unzip -n "${sdename}" -d "${version}"
	unzip -n "${iconsname}" -d "${version}"
	unzip -n "${typesname}" -d "${version}"

	cd $version
	python "${SRCROOT}/database/dump.py"

	find ./sde -name "*.yaml" -exec bash -c 'echo $1; ${TARGET_BUILD_DIR}/yaml2json $1 > "${1%.yaml}".json' - {} \;
	find ./sde -name "*.staticdata" -exec bash -c 'echo $1; ${TARGET_BUILD_DIR}/yaml2json $1 > "${1%.staticdata}".json' - {} \;

	cd ..
fi


if [ ! -f "${out}/${version}/NCDatabase.sqlite" ]; then
	cd $version
	${TARGET_BUILD_DIR}/sde-tool -o "${out}/${version}/NCDatabase.sqlite" -i "${out}/${version}"
	sqlite3 "${out}/${version}/NCDatabase.sqlite" "vacuum"
	yes | cp "${out}/${version}/NCDatabase.sqlite" "${PROJECT_DIR}/../../Neocom/NCDatabase.sqlite"
	echo "extension NCDatabase { static let version = \"$version\" }" > "${PROJECT_DIR}/../../Neocom/NCDatabaseVersion.swift"
fi
