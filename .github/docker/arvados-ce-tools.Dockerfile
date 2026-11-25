FROM ghcr.io/scorpia-labs/ergon:devel AS py_venv_base


FROM ubuntu:noble AS build_contrib

RUN apt-get update -q \
 && DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends python3-venv

ARG CONTRIB_SRC
RUN mkdir -p $CONTRIB_SRC

COPY --from=py_venv_base /opt/arvados-py/ /opt/arvados-py/

RUN --mount=type=bind,rw,target=$CONTRIB_SRC \
    . /opt/arvados-py/bin/activate \
 && pip3 install -qq --no-cache-dir --no-input $CONTRIB_SRC/arvados-bootstrap


FROM ubuntu:noble

RUN apt-get update -q \
 && DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends python3 libcurl4 nodejs \
 && rm -rf /var/cache/apt/archives /var/lib/apt/lists/*

COPY --from=build_contrib /opt/arvados-py/ /opt/arvados-py/

USER ubuntu
ENV PATH=/opt/arvados-py/bin:/usr/local/bin:/usr/bin:/bin
