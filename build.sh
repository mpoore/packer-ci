#!/bin/sh
VERSION=$(<VERSION)
docker build . -t mpoore/packer-ci:latest -t mpoore/packer-ci:v$VERSION --build-arg VERSION=$VERSION
docker login --username $DOCKERUSER --password $DOCKERPASS
docker push mpoore/packer-ci:latest
docker push mpoore/packer-ci:v$VERSION