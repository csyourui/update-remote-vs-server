#!/bin/bash

echo_bl() {
    echo "\033[34m$1\034[0m"
}

echo_gr() {
    echo "\033[32m$1\033[0m"
}

# get Host from ssh 
CONFIG_FILE="${HOME}/.ssh/config"

if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "SSH config file not found at ${CONFIG_FILE}"
    exit 1
fi

hosts=()
while IFS= read -r line; do
    if [[ "${line}" =~ ^Host ]]; then
        host=$(echo "${line}" | awk '{print $2}')
        hosts+=("${host}")
    fi
done < "${CONFIG_FILE}"

if [[ ${#hosts[@]} -eq 0 ]]; then
    echo "No hosts found in ${CONFIG_FILE}"
    exit 1
fi

echo_bl "Select a host to upload vscode-server-linux into:"
for i in "${!hosts[@]}"; do
    echo_gr "$((i+1)). ${hosts[$i]}"
done

read -p "Enter the number of the host: " host_number
selected_host="${hosts[$((host_number-1))]}"

if [[ -z "${selected_host}" ]]; then
    echo "Invalid selection"
    exit 1
fi

# get current version
commit_id=$(echo "$(code -v)" | sed -n '2p')
server_url="https://update.code.visualstudio.com/commit:${commit_id}/server-linux-x64/stable"

echo_gr "Host :${selected_host}"
echo_gr "Version: ${commit_id}"

echo_gr "Download: ${server_url}...."
mkdir temp
wget -O ./temp/vscode-server-linux-x64.tar.gz ${server_url}

# upload to the server
echo_gr "Upload to: ${selected_host}...."
scp ./temp/vscode-server-linux-x64.tar.gz ${selected_host}:~/.vscode-server/bin/

# login to the server
echo_gr "Login to: ${selected_host}...."
ssh ${selected_host} << reallssh
cd ~/.vscode-server/bin
mkdir ${commit_id}
tar -xzf ./vscode-server-linux-x64.tar.gz --strip-components 1 -C ./${commit_id}
rm -f ./${commit_id}/vscode-server-linux-x64.tar.gz
rm -f ./vscode-server-linux-x64.tar.gz
exit
reallssh

# delete tempfile
echo_gr "Delete temp file."
rm -rf temp
