CFLAGS = -Wall -Wextra -Werror
DEPS   = docker run --rm --tmpfs /.perl6 --tmpfs /.zef -u $(shell id -u):$(shell id -g) -v $(PWD)/vendor:/usr/share/perl6/vendor play-perl6-deps

build:
	docker build --target service -t play-perl6 .

build-deps:
	docker build -t play-perl6-deps .

bump: build-deps
	$(DEPS) upgrade

deploy: build
	docker tag play-perl6 jraspass/play-perl6
	docker push jraspass/play-perl6:latest
	ssh root@play-perl6.org "docker pull jraspass/play-perl6:latest && docker rm -f play-perl6; docker run --name play-perl6 --privileged --read-only --rm --tmpfs /tmp -dp 80:1080 -p 443:1443 -v /root/.acme.sh/play-perl6.org_ecc:/tls jraspass/play-perl6"

deps: build-deps
	$(DEPS) install Cro::WebApp

dev: build
	docker run --privileged --read-only --rm --tmpfs /tmp -p 80:1080 -p 443:1443 play-perl6

run-perl: run-perl.c
	$(CC) -o $@ $< $(CFLAGS)
	chown 0:0 $@
	chmod u+s $@
