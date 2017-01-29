#!/bin/bash -xe
#
# Modified by James Munnelly <james@munnelly.eu>
#
# Copyright 2016 The Kubernetes Authors All rights reserved.
#
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

# Setup Helm
HELM_URL=https://storage.googleapis.com/kubernetes-helm
HELM_TARBALL=helm-canary-linux-amd64.tar.gz
HELM_REPO_BUCKET=k8s-co-helm
STABLE_REPO_URL=https://storage.googleapis.com/"$HELM_REPO_BUCKET"/

# Grab helm
wget -q ${HELM_URL}/${HELM_TARBALL}
tar xzfv ${HELM_TARBALL}
PATH=`pwd`/linux-amd64/:$PATH

helm init --client-only

gcloud auth activate-service-account --key-file svc-acct.json

helm repo add k8s-stable "$STABLE_REPO_URL"

# Create the stable repository
STABLE_REPO_DIR=stable-repo
mkdir -p ${STABLE_REPO_DIR}
cd ${STABLE_REPO_DIR}
gsutil cp gs://"$HELM_REPO_BUCKET"/index.yaml .
  for dir in `ls ../stable`;do
    helm dep update ../stable/$dir
    helm package ../stable/$dir
  done
  helm repo index --url ${STABLE_REPO_URL} --merge ./index.yaml .
  gsutil -h Cache-Control:"Cache-Control:private, max-age=0, no-transform" -m rsync ./ gs://"$HELM_REPO_BUCKET"/
cd ..
ls -l ${STABLE_REPO_DIR}
