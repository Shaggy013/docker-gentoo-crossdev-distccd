build:
	$(eval TAG := $(shell cat TAG))
	docker build --tag=$(TAG) .

ci: build

run: TAG
	$(eval TAG := $(shell cat TAG))
	@docker run --name=distcc \
	--cidfile="cid" \
	-d \
	-p 3632:3632 \
	-v /var/run/docker.sock:/run/docker.sock \
	-v $(shell which docker):/bin/docker \
	-t $(TAG)

kill:
	-@docker kill `cat cid`

rm-image:
	-@docker rm `cat cid`
	-@rm cid

rm: kill rm-image

clean: rm

enter:
	docker exec -i -t `cat cid` /bin/bash

logs:
	docker logs -f `cat cid`

TAG:
	echo gentoodistcc > TAG
