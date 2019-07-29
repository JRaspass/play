deps:
	@docker build -t play-perl6-deps .
	@docker run --rm --tmpfs /.perl6 --tmpfs /.zef -u $(shell id -u):$(shell id -g) -v $(PWD)/vendor:/usr/share/perl6/vendor play-perl6-deps

build:
	@docker build --target service -t play-perl6 .

run: build
	@docker run --read-only --rm --tmpfs /tmp -p 1080:1080 play-perl6
