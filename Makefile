# Copyright 2021 IBM Corporation
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

IMG_NAME ?= kserve/rest-proxy

# collect args from `make run` so that they don't run twice
ifeq (run,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  ifneq ("$(wildcard /.dockerenv)","")
    $(error Inside docker container, run 'make $(RUN_ARGS)')
  endif
endif

.PHONY: all
## Alias for `build`
all: build

.PHONY: build
## Build runtime docker image
build:
	docker build -t ${IMG_NAME}:latest --target runtime .

.PHONY: build.develop
## Build develop docker image
build.develop:
	docker build -t ${IMG_NAME}-develop:latest --target develop .

.PHONY: develop
## Build develop docker image and run an interactive shell in the develop envionment
develop: build.develop
	./scripts/develop.sh

.PHONY: run
## Build develop docker image and run a make command in the develop envionment (e.g. `make run fmt` will execute `make fmt` within the docker container)
run: build.develop
	./scripts/develop.sh make $(RUN_ARGS)

.PHONY: fmt
## Run formatting
fmt:
	./scripts/fmt.sh

.PHONY: test
## Run tests
test:
	go test -coverprofile cover.out `go list ./...`

.PHONY: help
## Print Makefile documentation
help:
	@perl -0 -nle 'printf("%-25s - %s\n", "$$2", "$$1") while m/^##\s*([^\r\n]+)\n^([\w-]+):[^=]/gm' $(MAKEFILE_LIST) | sort
.DEFAULT_GOAL := help

# Override targets if they are included in RUN_ARGs so it doesn't run them twice
# otherwise 'make run fmt' would be equivalent to calling './scripts/develop.sh make fmt'
# followed by 'make fmt'
$(eval $(RUN_ARGS):;@:)
