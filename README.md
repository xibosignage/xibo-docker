# Xibo Docker

[Docker](https://docker.com/) is an application to package and run any
application in a pre-configured container making it much easier to deploy a Xibo
CMS with recommended configuration.

This repository holds the docker container definitions for Xibo and the launcher
shell script bootstrap, start, stop and destroy the installation.

## Getting Started

The easiest and fastest way to get started with Xibo is to
install Docker and use `launcher` to bootstrap and run your Xibo environment.

### Install Docker

```
wget -qO- https://get.docker.com/ | sh
```

You can [manually install Docker](https://docs.docker.com/installation/) if you
prefer.

### Bootsrap Xibo

```
launcher bootstrap
```

This will bootstrap and start your Xibo CMS. The CMS will be fully installed
with the default credentials.

If you want to edit the default credentials you may do so by editing launcher
and adjusting the variables at the top.

### Start/Stop/Destroy

Pass start/stop or destroy into launcher to take the corresponding action

```
launcher XXX
```

## Upgrading Xibo

```
launcher upgrade
```

## Directory structure

This repository contains Docker configuration (Dockerfile) for the Xibo
containers. A normal installation *only* requires `launcher`.

#### /containers

web and xmr Dockerfiles and associated configuration. These are built by Docker
Hub and packaged into `xibosignage/xibo-cms` and `xibosignage/xibo-xmr`.

#### /shared

Data folders for the Xibo installation.

 - The Library storage can be found in `/shared/web/library` The database
 - storage can be found in `/shared/db` Automated daily backups can be found in
 - `/shared/backup`

## Running without launcher
If you have your own docker environment you may want to run without the
automation provided by launcher. If this is the case you will be responsible
for pulling the docker containers, starting them and manually installing Xibo.


## Reporting problems

Support requests can be reported on the [Xibo Community
Forum](https://community.xibo.org.uk/). Verified, re-producable bugs with this
repository can be reported in the [Xibo parent
repository](https://github.com/xibosignage/xibo/issues).
