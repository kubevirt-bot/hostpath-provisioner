# Copyright 2016 The Kubernetes Authors.
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

.PHONY: cluster-up cluster-down cluster-sync cluster-clean

HPP_IMAGE?=hostpath-provisioner
TAG?=latest
DOCKER_REPO?=kubevirt

all: controller hostpath-provisioner

controller:
	CGO_ENABLED=0 go build -a -ldflags '-extldflags "-static"' controller

hostpath-provisioner: controller
	CGO_ENABLED=0 go build -a -ldflags '-extldflags "-static"' -o _out/hostpath-provisioner cmd/provisioner/hostpath-provisioner.go

image: hostpath-provisioner
	docker build -t $(DOCKER_REPO)/$(HPP_IMAGE):$(TAG) -f Dockerfile .

push: hostpath-provisioner image
	docker push $(DOCKER_REPO)/$(HPP_IMAGE):$(TAG)

clean:
	rm -rf _out

build: clean dep controller hostpath-provisioner

cluster-up:
	./cluster-up/up.sh

cluster-down: 
	./cluster-up/down.sh

cluster-sync: cluster-clean
	./cluster-sync/sync.sh

cluster-clean:
	./cluster-sync/clean.sh

test:
	go test -v ./cmd/... ./controller/...
	hack/run-lint-checks.sh

test-functional:
	go test -v ./tests/... -master="" -kubeconfig="../_ci-configs/k8s-1.15.1/.kubeconfig"
