pwd = $(shell pwd)
container_prefix = bldr
NO_CACHE = false

.PHONY: container test run shell clean bldr-base package-clean packages

all: volumes container packages bldr-base redis

package-clean:
	docker-compose run package bash -c 'rm -rf /opt/bldr/cache/pkgs/*'
	docker-compose run package bash -c 'rm -rf /opt/bldr/pkgs/*'

packages: package-clean
	docker-compose run -e DOCKER_HOST=${DOCKER_HOST} package bash -c 'cd /src/packages; make world'

volumes: pkg-cache-volume key-cache-volume cargo-volume installed-cache-volume src-cache-volume

installed-cache-volume:
	docker create -v /opt/bldr/pkgs --name bldr-installed-cache tianon/true /bin/true

src-cache-volume:
	docker create -v /opt/bldr/cache/src --name bldr-src-cache tianon/true /bin/true

src-cache-clean:
	docker rm bldr-src-cache

pkg-cache-volume:
	docker create -v /opt/bldr/cache/pkgs --name bldr-pkg-cache tianon/true /bin/true

pkg-cache-clean:
	docker rm bldr-pkg-cache

key-cache-volume:
	docker create -v /opt/bldr/cache/keys --name bldr-keys-cache tianon/true /bin/true

key-cache-clean:
	docker rm bldr-key-cache

cargo-volume:
	docker create -v /bldr-cargo-cache --name bldr-cargo-cache tianon/true /bin/true

container:
	docker build -t chef/bldr --no-cache=${NO_CACHE} .

test:
	docker-compose run bldr cargo test

cargo-clean:
	docker-compose run bldr cargo clean

shell:
	docker-compose run bldr bash

pkg-shell:
	docker-compose run -e DOCKER_HOST=${DOCKER_HOST} package bash

bldr-base: packages

base-shell:
	docker-compose run base

clean:
	docker images -q -f dangling=true | xargs docker rmi

redis:
	docker-compose run bldr cargo run -- start redis

publish:
	for x in `docker images | egrep '^bldr/base' | awk '{print $2}'`; do \
		docker tag -f bldr/base:$x quay.io/bldr/base:$x ; \
	done
	docker push quay.io/bldr/base
