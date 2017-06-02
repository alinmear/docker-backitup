NAME = alinmear/docker-backitup:testing

all: build-no-cache

build-no-cache:
	docker build -t $(NAME) .

run:
	docker run -d --name platzhalter \
	-h docker-backup -t $(NAME)

tests:
	./test/bats/bin/bats test/tests.bats

clean:
	-docker rm -f platzhalter
