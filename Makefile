#!make
include .env
export $(shell sed 's/=.*//' .env)
CURRENT_UID := $(shell id -u)
CURRENT_GID := $(shell id -g)
export CURRENT_UID
export CURRENT_GID

default: edk2_build_dir
	docker build -t $(IMAGE_NAME) .
	echo "build complete"
	docker run --rm -v $(PWD)/edk2/build:/home/edk2/tmp $(IMAGE_NAME) sh -c "cp -r $(FD_LOCATION)/OVMF_*.fd /home/edk2/tmp"

edk2_build_dir:
	mkdir -p $(PWD)/edk2/build
	chown $(CURRENT_UID):$(CURRENT_GID) $(PWD)/edk2/build
	touch $(PWD)/edk2/build/tmp
test:
	env

clean:
	rm -rf edk2/build