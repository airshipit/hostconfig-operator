#!/bin/bash

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This downloads kind, puts it in a temp directory, and prints the directory
set -e

KIND_VERSION="v0.8.1"

echo "Installing Kind Version $KIND_VERSION"
: ${KIND_URL:="https://kind.sigs.k8s.io/dl/$KIND_VERSION/kind-$(uname)-amd64"}
TMP=$(mktemp -d)
KIND="${TMP}/kind"

wget -O ${KIND} ${KIND_URL}
chmod +x ${KIND}
sudo cp ${KIND} /usr/local/bin
