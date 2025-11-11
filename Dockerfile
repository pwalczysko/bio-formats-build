ARG BUILD_IMAGE=openjdk:8u322-jdk
# Build image
FROM ${BUILD_IMAGE}
LABEL maintainer="ome-devel@lists.openmicroscopy.org.uk"

USER root
RUN apt-get -q update && apt-get -qy install maven \
   ant \
   git \
   python3-venv

RUN id 1000 || useradd -u 1000 -ms /bin/bash build
COPY --chown=1000:1000 . /bio-formats-build

USER 1000
WORKDIR /bio-formats-build
RUN git submodule update --init
RUN git submodule foreach -q --recursive 'branch="$(git config -f $toplevel/.gitmodules submodule.$name.branch)"; git switch $branch'

RUN python3 -m venv /bio-formats-build/venv
ENV PATH="/bio-formats-build/venv/bin:$PATH"
RUN pip install -r bio-formats-documentation/requirements.txt
RUN pip install -r ome-model/requirements.txt

RUN mvn clean install -DskipSphinxTests -Dmaven.javadoc.skip=true

WORKDIR /bio-formats-build/bioformats

RUN ant jars tools

ENV TZ="Europe/London"

WORKDIR /bio-formats-build/bioformats/components/test-suite
ENTRYPOINT ["/usr/bin/ant", "test-automated", "-Dtestng.directory=/data", "-Dtestng.configDirectory=/config"]
