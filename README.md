# ghammer build containers

Static release builds of `ghammer_client` and `ghammer_server`. Run everything from this
folder; the ghammer source must be at `../ghammer`.

## Linux (amd64)

```bash
docker build -f Dockerfile -t ghammer_amd64 .
docker run --rm -u "$(id -u):$(id -g)" -v "$(realpath ../ghammer)":/src -v "$PWD":/out ghammer_amd64
```

Output: `build-linux-amd64/bin/`.

## Windows (amd64)

```bash
docker build -f Dockerfile.windows -t ghammer_win64 .
docker run --rm -u "$(id -u):$(id -g)" -v "$(realpath ../ghammer)":/src -v "$PWD":/out ghammer_win64
```

Output: `build-windows-amd64/bin/`.

## Release zips

```bash
./release.sh   # -> ghammer-<version>-<platform>-<arch>.zip per build-<platform>-<arch>
```

Compile and zip both:

```bash
./compile_and_release.sh
```
