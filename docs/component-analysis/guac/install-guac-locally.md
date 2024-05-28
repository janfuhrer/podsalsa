# Install GUAC locally

## Prerequisites

- [slsa-verifier](https://github.com/slsa-framework/slsa-verifier)
- [docker](https://docs.docker.com/get-docker/)
- [docker-compose](https://docs.docker.com/compose/install/)
- [yarn](https://classic.yarnpkg.com/lang/en/docs/install/#mac-stable)

## Install and start all components

**guacone binary**

Download and verify the latest release of the `guacone` binary (see [Release Page](https://github.com/guacsec/guac/releases)):

```bash
export VERSION=$(curl -s "https://api.github.com/repos/guacsec/guac/releases/latest" | jq -r '.tag_name')
export ARTIFACT=guacone-darwin-amd64

# download the artifact
curl -O -L https://github.com/guacsec/guac/releases/download/$VERSION/$ARTIFACT
curl -O -L https://github.com/guacsec/guac/releases/download/$VERSION/multiple.intoto.jsonl

# verify the artifact
slsa-verifier verify-artifact \
	--provenance-path multiple.intoto.jsonl \
	--source-uri github.com/guacsec/guac \
	--source-tag $VERSION \
    $ARTIFACT

# make the binary executable and move it to a directory in your PATH
chmod +x $ARTIFACT
sudo mv $ARTIFACT /usr/local/bin/guacone

# check version
guacone -v
```

**Docker-compose**

Download the `guac-demo-compose.yaml` file and start the containers:

```bash
curl -O -L https://github.com/guacsec/guac/releases/download/$VERSION/guac-demo-compose.yaml

docker compose -f guac-demo-compose.yaml up -d --force-recreate
```

This will start the following containers:

- `osv-certifier`
- `depsdev-collector`
- `guac-rest`, available on [http://localhost:8081](http://localhost:8081)
- `graphql`, available on [http://localhost:8080](http://localhost:8080)
- `collectsub`, available on [http://localhost:2782](http://localhost:2782)

**guac-visualizer**

Download the source code of the `guac-visualizer` and start the development server with `yarn`:

```bash
export VERSION=$(curl -s "https://api.github.com/repos/guacsec/guac-visualizer/releases/latest" | jq -r '.tag_name')

# download source code
curl -O -L https://github.com/guacsec/guac-visualizer/archive/refs/tags/$VERSION.tar.gz

# extract source code to the directory "guac-visualizer"
mkdir guac-visualizer && tar -xzf $VERSION.tar.gz -C guac-visualizer --strip-components 1
cd guac-visualizer

# install dependencies and start the development server
yarn install
yarn dev
```

Now the `guac-visualizer` is running on [http://localhost:3000](http://localhost:3000).

## Cleanup

To stop and remove the containers, run:

```bash
docker compose -f guac-demo-compose.yaml down
```
