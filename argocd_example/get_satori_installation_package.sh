#!/bin/bash -e

read -p "$(echo Are you ready to run the script? Type \'yes\' to approve:) " ANSWER
if [ "$ANSWER" != "yes" ]; then
   echo "exiting..."
   exit
fi

tmp_dir=$(mktemp -d)
echo "The temp dir is: $tmp_dir"
echo "Th git repo path is: $REPO_PATH"

# Obtain the authentication bearer
export satori_bearer=$(curl -s -X POST -H 'Content-Type: application/json'  https://app.satoricyber.info/api/authentication/token -d '{ "serviceAccountId": "'$SATORI_SERVICE_ID'", "serviceAccountKey": "'$SATORI_SERVICE_KEY'"}' | jq -r .token)

# Get the recomended latest package version
export satori_latest_version=$(curl -s -H "Accept: application/json" -H "Authorization: Bearer ${satori_bearer}" -X GET https://app.satoricyber.info/api/v1/data-access-controllers/package/releases | jq -r '.records[] | select(.type=="RECOMMENDED") | .version ')
echo "The latest DAC version is: $satori_latest_version"
# Download the package
curl -s -H "Authorization: Bearer ${satori_bearer}" -X GET "https://app.satoricyber.info/api/v1/data-access-controllers/${DAC_ID}/package/download?version=${satori_latest_version}" -o "${tmp_dir}/${satori_latest_version}.tar"

#Extract the tar
mkdir -p "${tmp_dir}/${satori_latest_version}-extracted" && tar -xvf "${tmp_dir}/${satori_latest_version}.tar" -C "${tmp_dir}/${satori_latest_version}-extracted/" --strip-components 1

# Upload the bootstrap access key to the kubernetes secret
cd "${tmp_dir}/${satori_latest_version}-extracted/"
kubectl create namespace satori-runtime --save-config --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic dac-secrets-sa -n satori-runtime --save-config --dry-run=client --from-file="./dac-secrets-sa.json" -o yaml | kubectl apply -f -

# Delete the sensitive bootstrap access key from the helm chart
rm -f ./dac-secrets-sa.json
rm -f ./satori-runtime/dac-secrets-sa.json

# copy value files into the helm package
cp ./version-values.yaml ./customer-override.yaml ./customer-values.yaml ./satori-runtime/

# delete old package and copy the updates helm package to the local git repo
rm -fr  "$REPO_PATH/satori_package" && mkdir -p "$REPO_PATH/satori_package"
cp -r ./satori-runtime/ "$REPO_PATH/satori_package"

# cleanup tmp folder
rm -fr "$tmp_dir"

#push the updated repo to master
push the git to the current branch
git add . 
git commit -m "Upgrade the satori DAC to version $satori_latest_version"
git push origin