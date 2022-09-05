
mkdir _tmp && cd _tmp
kcp_path=$(pwd) && echo $kcp_path
hw=darwin
version=0.8.0
wget "https://github.com/kcp-dev/kcp/releases/download/v${version}/kcp_${version}_${hw}_amd64.tar.gz"
wget "https://github.com/kcp-dev/kcp/releases/download/v${version}/kubectl-kcp-plugin_${version}_${hw}_amd64.tar.gz"
tar -vxf kcp_${version}_${hw}_amd64.tar.gz
tar -vxf kubectl-kcp-plugin_${version}_${hw}_amd64.tar.gz
cp bin/kubectl-* /usr/local/bin

rm -rf .kcp
./bin/kcp start