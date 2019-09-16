CFLAGS = -Wall -Wextra -Werror
DEPS   = docker run --rm --tmpfs /.perl6 --tmpfs /.zef -u $(shell id -u):$(shell id -g) -v $(PWD)/vendor:/usr/share/perl6/vendor play-perl6-deps

build:
	docker build --target service -t play-perl6 .

build-deps:
	docker build -t play-perl6-deps .

bump: build-deps
	$(DEPS) upgrade

deploy: build
	@docker save play-perl6 | ssh root@play-perl6.org "\
		docker load &&                                 \
		docker rm -f play-perl6;                       \
		docker run                                     \
		--detach                                       \
		--name       play-perl6                        \
		--network    mybridge                          \
		--privileged                                   \
		--read-only                                    \
		--restart    always                            \
		--tmpfs      /tmp                              \
		play-perl6"

deps: build-deps
	rm -fr vendor/*
	$(DEPS) install Cro::WebApp

dev: build
	docker run --privileged --read-only --rm --tmpfs /tmp -p 1337:1337 play-perl6

run-perl: run-perl.c
	$(CC) -o $@ $< $(CFLAGS)
	chown 0:0 $@
	chmod u+s $@
