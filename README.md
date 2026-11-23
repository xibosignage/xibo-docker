# Xibo Digital Signage - Docker configuration files

> [!IMPORTANT]
> **This repository is retired.** From Xibo CMS 2026.11.71, the Docker Compose files ship with every xibo-cms release
> as the `xibo-docker-<version>` download. Get it from the
> [latest release](https://github.com/xibosignage/xibo-cms/releases/latest). If you installed from this repository,
> follow [Migrating from xibo-docker](https://github.com/xibosignage/xibo-cms/tree/main#migrating-from-xibo-docker)
> to switch. The releases here stay available for older versions.

Xibo is a powerful Open Source Digital Signage platform with a web content management system and player applications 
for various platforms (Android, ChromeOS, Linux, webOS, Windows and Tizen) to show content on your screens.

See [https://xibosignage.com](https://xibosignage.com) for more information.

[Docker](https://docker.com/) is an application to package and run any
application in a pre-configured container and is the only way to deploy a Xibo
CMS with recommended and supported configuration.

This repository holds the docker container definitions for Xibo and the docker-compose
configuration, which is used to bootstrap, start, stop and destroy the installation.

## Licence

[![Licence](https://img.shields.io/github/license/xibosignage/xibo-cms)]()

Copyright (C) 2006-2026 Xibo Signage Ltd and Contributors.

Xibo is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public
License as published by the Free Software Foundation, either version 3 of the License, or any later version.

Xibo is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with Xibo.
If not, see <http://www.gnu.org/licenses/>.

## Installation
Full installation instructions for supported use of these containers can be
found in [our documentation](https://account.xibosignage.com/docs/setup/cms-installation-guides)

## Directory structure

This repository contains Docker configuration (Dockerfile) for the Xibo
containers. A normal installation *only* requires `docker-compose.yaml` and
a `config.env.template` file, suitably configured, saved as `config.env`.

#### /containers

web and xmr Dockerfiles and associated configuration. These are built by Docker
Hub and packaged into `xibosignage/xibo-cms` and `xibosignage/xibo-xmr`.

#### DATA_DIR/shared

Data folders for the Xibo installation.

 - The Library storage can be found in `/shared/cms/library`
 - The database storage can be found in `/shared/db`
 - Automated daily database backups can be found in `/shared/backup`
 - Custom themes should be placed in `/shared/cms/web/theme/custom`
 - Custom modules should be placed in `/shared/cms/custom`
 - Any user generated PHP or resources external to Xibo that you want hosted
   on the same webserver go in `/shared/cms/web/userscripts`. They will then
   be available to you at `http://localhost/userscripts/`

## Running without docker-compose
If you have your own docker environment you may want to run without the
automation provided by docker-compose. If this is the case you will be responsible
for pulling the docker containers, starting them and manually installing Xibo.


## Reporting problems

Support requests can be reported on the [Xibo Community
Forum](https://community.xibo.org.uk/). Verified, re-producible bugs with this
repository can be reported in the [Xibo parent
repository](https://github.com/xibosignage/xibo/issues).
