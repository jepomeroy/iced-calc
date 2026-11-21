#!/usr/bin/env bash
# Build a signed apt repository from the .deb files in <repo>/pool/main.
#
# Usage: scripts/build-apt-repo.sh <repo-dir> <gpg-key-id>
#
# Resulting layout (serve <repo-dir> over HTTPS):
#   iced-calc.gpg                       public signing key
#   pool/main/*.deb
#   dists/stable/{Release,Release.gpg,InRelease}
#   dists/stable/main/binary-<arch>/Packages{,.gz}
set -euo pipefail

repo=${1:?repo dir required}
keyid=${2:?gpg key id required}
suite=stable
component=main

cd "$repo"

archs=$(for f in pool/"$component"/*.deb; do dpkg-deb -f "$f" Architecture; done | sort -u | xargs)

for arch in $archs; do
  dir="dists/$suite/$component/binary-$arch"
  mkdir -p "$dir"
  apt-ftparchive --arch "$arch" packages "pool/$component" > "$dir/Packages"
  gzip -9kf "$dir/Packages"
done

apt-ftparchive \
  -o APT::FTPArchive::Release::Origin="iced-calc" \
  -o APT::FTPArchive::Release::Label="iced-calc" \
  -o APT::FTPArchive::Release::Suite="$suite" \
  -o APT::FTPArchive::Release::Codename="$suite" \
  -o APT::FTPArchive::Release::Components="$component" \
  -o APT::FTPArchive::Release::Architectures="$archs" \
  release "dists/$suite" > Release.tmp
# Written outside dists/ so the Release file doesn't hash itself.
mv Release.tmp "dists/$suite/Release"

gpg --batch --yes --local-user "$keyid" --clearsign -o "dists/$suite/InRelease" "dists/$suite/Release"
gpg --batch --yes --local-user "$keyid" --armor --detach-sign -o "dists/$suite/Release.gpg" "dists/$suite/Release"
gpg --batch --yes --export "$keyid" > iced-calc.gpg

# Simple landing page with install instructions.
cat > index.html <<'EOF'
<!doctype html>
<meta charset="utf-8">
<title>iced-calc apt repository</title>
<h1>iced-calc apt repository</h1>
<pre>
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://jepomeroy.github.io/iced-calc/iced-calc.gpg | sudo tee /etc/apt/keyrings/iced-calc.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/iced-calc.gpg] https://jepomeroy.github.io/iced-calc stable main" | sudo tee /etc/apt/sources.list.d/iced-calc.list
sudo apt update
sudo apt install iced-calc
</pre>
EOF
