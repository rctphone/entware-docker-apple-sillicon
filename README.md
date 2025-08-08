# Building packages from Docker optimized for Apple Sillicon

A highly reproducible way to build Entware packages. A plesant way for Docker-addicted persons:)

## Usage

Create Docker image tagged as `builder`:
```
git clone https://github.com/rctphone/entware-docker-apple-sillicon.git
docker build docker --pull
```

Create Docker volume for compilation:
```
docker volume create entware-home
```

Run Docker containter named as `builder`:
```
docker run --rm --mount source=entware-home,target=/home/me --interactive --tty --name builder builder
```

Follow [this manual](https://github.com/Entware/Entware/wiki/Compile-packages-from-sources#clone-the-entware-git-repository) for further steps, all dependencies are pre-installed in Docker image.

If you need second (3rd or more) terminal, type:
```
docker exec --interactive --tty builder bash
```

Extract compiled packages:
```
docker cp builder:/home/me/Entware/bin .
```

## Build architectures

By default, the image builds the toolchain for arm64 (aarch64) using the `aarch64-3.10.config`.

- Default (arm64):

  ```
  docker build . -t builder
  ```

- To build for a different architecture, provide the desired config via the `ENTWARE_CONFIG` build arg (see available configs in [`Entware/configs`](https://github.com/Entware/Entware/tree/master/configs)):

  ```
  docker build . -t builder --build-arg ENTWARE_CONFIG=mipsel-3.4.config
  ```
