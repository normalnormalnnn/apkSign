#!/bin/sh
apkFileName="origin.apk"
configFileName="idFile"

dateWithTime=`date "+%Y%m%d-%H%M%S"`
outputFolderName="output${dateWithTime}"
channelFilePath="assets/res/channel.json"
keystoreFile="fileName.jks"
keystoreFilePassword="password"
tempFilePath="../${outputFolderName}/tmp.apk"

mkdir "${outputFolderName}"

unzip "${apkFileName}" -d "tmp"
cd tmp
rm -rf META-INF

# read idFile line by line, need a empty line at end to read all line.
while IFS= read -r line
do
	# split line string to array use splitor ','.
	# first is fileName, second is channelID
	IFS=',' read -r -a lineToken <<< "$line"

	fileName=$(echo "${lineToken[0]}" | tr -d '[:space:][:blank:]')
	channelID=$(echo "${lineToken[1]}" | tr -d '[:space:][:blank:]')

	echo "fileName = \"${fileName}\", channelID = \"${channelID}\""

	# set channel ID and delete redunt file.
	sed -i -e -E "s/\"id\":.+/\"id\":${channelID},/g" "${channelFilePath}"
	rm -rf "${channelFilePath}-e"

	# compress files and align.
	zip -qr "$tempFilePath" *
	apkFileName="${fileName}.apk"	
	filePath="../${outputFolderName}/${apkFileName}"
	zipalign -f 4 "$tempFilePath" "$filePath"
	rm -rf "$tempFilePath"

	# resign.
	apksigner sign --ks "../${keystoreFile}" --ks-pass "pass:${keystoreFilePassword}" "$filePath"
	apksigner verify -v "$filePath"
done < "../${configFileName}"

cd ../
rm -rf tmp
