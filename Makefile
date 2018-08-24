REPO=malice-plugins/zoner
ORG=malice
NAME=zoner
CATEGORY=av
VERSION=$(shell cat VERSION)

ZONE_KEY?=$(shell cat zoner.key)
MALWARE=tests/malware

all: build size tag test_all

.PHONY: build
build:
	docker build --build-arg ZONE_KEY=${ZONE_KEY} -t $(ORG)/$(NAME):$(VERSION) .

.PHONY: size
size:
	sed -i.bu 's/docker%20image-.*-blue/docker%20image-$(shell docker images --format "{{.Size}}" $(ORG)/$(NAME):$(VERSION)| cut -d' ' -f1)-blue/' README.md

.PHONY: tag
tag:
	docker tag $(ORG)/$(NAME):$(VERSION) $(ORG)/$(NAME):latest

.PHONY: tags
tags:
	docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" $(ORG)/$(NAME)

.PHONY: ssh
ssh:
	@docker run --init -it --rm --entrypoint=bash $(ORG)/$(NAME):$(VERSION)
	# @docker run --init -it --rm -v $(PWD):/malware --entrypoint=bash $(ORG)/$(NAME):$(VERSION)

.PHONY: tar
tar:
	docker save $(ORG)/$(NAME):$(VERSION) -o $(NAME).tar

gotest:
	go get
	go test -v

avtest:
	@echo "\n===> ${NAME} EICAR Test"
	@docker run --init --rm --entrypoint=sh $(ORG)/$(NAME):$(VERSION) -c "/etc/init.d/zavd start --no-daemon > /dev/null 2>&1 && zavcli /malware/EICAR" > tests/av.virus || true
	@echo "\n===> ${NAME} Clean Test"
	@docker run --init --rm --entrypoint=sh $(ORG)/$(NAME):$(VERSION) -c "/etc/init.d/zavd start --no-daemon > /dev/null 2>&1 && zavcli /bin/cat" > tests/av.clean || true
	@echo "\n===> ${NAME} Version"
	@docker run --init --rm --entrypoint=sh $(ORG)/$(NAME):$(VERSION) -c "/etc/init.d/zavd start --no-daemon > /dev/null 2>&1 && zavcli --version" > tests/av.version || true
	@echo "\n===> ${NAME} DB version"
	@docker run --init --rm --entrypoint=sh $(ORG)/$(NAME):$(VERSION) -c "/etc/init.d/zavd start --no-daemon > /dev/null 2>&1 && zavcli --version-zavd" > tests/av.update || true

update:
	@docker run  --rm $(ORG)/$(NAME):$(VERSION) update

.PHONY: start_elasticsearch
start_elasticsearch:
ifeq ("$(shell docker inspect -f {{.State.Running}} elasticsearch)", "true")
	@echo "\n===> elasticsearch already running"
else
	@echo "\n===> Starting elasticsearch"
	@docker rm -f elasticsearch || true
	@docker run --init -d --name elasticsearch -p 9200:9200 malice/elasticsearch:6.3; sleep 10
endif

.PHONY: malware
malware:
ifeq (,$(wildcard $(MALWARE)))
	wget https://github.com/maliceio/malice-av/raw/master/samples/befb88b89c2eb401900a68e9f5b78764203f2b48264fcc3f7121bf04a57fd408 -O $(MALWARE)
	cd tests; echo "TEST" > not.malware
endif

.PHONY: test_all
test_all: test test_elastic test_markdown test_web

.PHONY: test
test: malware
	@echo "\n===> ${NAME} --help"
	docker run --init --rm $(ORG)/$(NAME):$(VERSION) --help
	docker run --init --rm -v $(PWD):/malware $(ORG)/$(NAME):$(VERSION) -V $(MALWARE) | jq . > docs/results.json
	cat docs/results.json | jq .

.PHONY: test_elastic
test_elastic: start_elasticsearch malware
	@echo "\n===> ${NAME} test_elastic found"
	docker run --rm --link elasticsearch -e MALICE_ELASTICSEARCH=elasticsearch -v $(PWD):/malware $(ORG)/$(NAME):$(VERSION) -V $(MALWARE)
	# @echo "\n===> ${NAME} test_elastic NOT found"
	# docker run --rm --link elasticsearch -e MALICE_ELASTICSEARCH=elasticsearch $(ORG)/$(NAME):$(VERSION) -V --api ${MALICE_VT_API} lookup $(MISSING_HASH)
	http localhost:9200/malice/_search | jq . > docs/elastic.json

.PHONY: test_markdown
test_markdown:
	@echo "\n===> ${NAME} test_markdown"
	# http localhost:9200/malice/_search query:=@docs/query.json | jq . > docs/elastic.json
	cat docs/elastic.json | jq -r '.hits.hits[] ._source.plugins.${CATEGORY}.${NAME}.markdown' > docs/SAMPLE.md

.PHONY: test_web
test_web: malware stop
	@echo "\n===> Starting web service"
	docker run -d --name $(NAME) -p 3993:3993 $(ORG)/$(NAME):$(VERSION) web
	sleep 10; http -f localhost:3993/scan malware@/Users/blacktop/go/src/github.com/malice-plugins/pdf/test/eicar.pdf
	sleep 10; http -f localhost:3993/scan malware@$(MALWARE)
	@echo "\n===> Stopping web service"
	@docker logs $(NAME)
	# @docker rm -f $(NAME)

.PHONY: stop
stop: ## Kill running docker containers
	@docker rm -f $(NAME) || true

.PHONY: circle
circle: ci-size
	@sed -i.bu 's/docker%20image-.*-blue/docker%20image-$(shell cat .circleci/size)-blue/' README.md
	@echo "\n===> Image size is: $(shell cat .circleci/size)"

ci-build:
	@echo "\n===> Getting CircleCI build number"
	@http https://circleci.com/api/v1.1/project/github/${REPO} | jq '.[0].build_num' > .circleci/build_num

ci-size: ci-build
	@echo "\n===> Getting artifact sizes from CircleCI"
	@cd .circleci; rm size nsrl bloom || true
	@http https://circleci.com/api/v1.1/project/github/${REPO}/$(shell cat .circleci/build_num)/artifacts${CIRCLE_TOKEN} | jq -r ".[] | .url" | xargs wget -q -P .circleci

clean:
	docker-clean stop
	docker image rm $(ORG)/$(NAME):$(VERSION)
	docker image rm $(ORG)/$(NAME):latest
	rm $(MALWARE)

# Absolutely awesome: http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := all
