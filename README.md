# What is XWiki

[XWiki](https://xwiki.org/) is a free and open source wiki software platform written in Java with a design emphasis on extensibility.

See the documentation of [XWiki.org](https://xwiki.org/) or [Wikipedia's article about XWiki](https://en.wikipedia.org/wiki/XWiki) to know more about XWiki.

![logo](https://www.xwiki.org/xwiki/bin/download/Main/Logo/logo-xwikiorange.svg)

# Documentation

This repository contains the sources of the official `xwiki` [Docker images](https://hub.docker.com/_/xwiki), which provide a production-ready XWiki system running in Docker.

See [Install XWiki using Docker](https://www.xwiki.org/xwiki/bin/view/documentation/xs/admin/installation/methods/install-xwiki-docker/) for the documentation on how to run and configure it.

# License

XWiki is licensed under the [LGPL 2.1](https://github.com/xwiki/xwiki-docker/blob/master/LICENSE).

The Dockerfile repository is also licensed under the [LGPL 2.1](https://github.com/xwiki/xwiki-docker/blob/master/LICENSE).

# Support

-	If you wish to raise an issue or an idea of improvement use [XWiki Docker JIRA project](https://jira.xwiki.org/browse/XDOCKER)
-	If you have questions, use the [XWiki Forum](https://dev.xwiki.org/xwiki/bin/view/Community/Discuss) or the [XWiki Chat](https://dev.xwiki.org/xwiki/bin/view/Community/Chat)

# Contribute

-	If you wish to help out on the code, please send Pull Requests on [XWiki Docker GitHub project](https://github.com/xwiki/xwiki-docker)
-	Note that changes need to be merged to all other branches where they make sense and if they make sense for existing tags, those tags must be deleted and recreated.
-	In addition, whenever a branch or tag is modified, a Pull Request on the [DockerHub XWiki official image](https://github.com/docker-library/official-images/blob/master/library/xwiki) must be made

# Releasing new versions

This is for maintainers performing the "Update Docker Images" step of an XWiki release, see [ReleasePlanHelp](https://dev.xwiki.org/xwiki/bin/view/ReleasePlans/ReleasePlanHelp#HUpdateDocker) for the full context. The version bumps and the DockerHub official-images Pull Request are automated as Gradle tasks; you only review, commit and push the `docker-xwiki` change in between.

-	`./gradlew release` (pre-push): refreshes every cycle to the latest XWiki release, the JDBC drivers (read for each cycle from that cycle's own `xwiki-platform` POM) and the LibreOffice version in `versions.json`, regenerates all the version/variant directories and the build workflow, then smoke-tests the cycles that changed: for each it builds the `postgres-tomcat` variant, plus the variant of any database whose JDBC driver moved, boots each one and waits until its REST API reports the expected version. Docker must be running.
-	Review the resulting diff, then commit and push `versions.json` together with the regenerated directories.
-	`./gradlew submitOfficialImage` (post-push): regenerates the `library/xwiki` file and opens the Pull Request against [docker-library/official-images](https://github.com/docker-library/official-images) from your GitHub fork. Pass `-PdryRun` to only generate the file and show the diff without opening a PR. Requires an authenticated `gh` CLI.

Each step is also runnable on its own: `updateXWiki`, `updateJDBC`, `updateLibreOffice`, `generate`, `generateWorkflows`, `smokeTest` (which takes the same `-Pcycles` and `-Pvariants` filters as `runAll` below) and `submitOfficialImage`. To try the images out by hand, `./gradlew runAll` starts each cycle and variant on its own port and leaves them running (narrow it down with `-Pcycles=18,17` and/or `-Pvariants=postgres-tomcat`), and `./gradlew stopAll` tears them down again. See the comments in `build.gradle` and in the scripts it applies from `gradle/` for the details.

# Credits

-	Originally created by Vincent Massol
-	Contributions from Fabio Mancinelli, Ludovic Dubost, Jean Simard, Denis Germain and a lot of others
-	Some code was copied from https://github.com/ThomasSteinbach/docker_xwiki. Thank you Thomas Steinbach
-	Stolen XWiki ascii art from [https://github.com/babelop](babelop), see https://hub.docker.com/r/binarybabel/xwiki/~/dockerfile/
