ARG ARCH=
# AlpineLinux with a glibc-2.29-r0 and python3
FROM --platform=linux/${ARCH} alpine:3.15
ARG ARCH
#ENV ARCH=$(cat "$ARCH" | sed -e 's/ \/  //'    )
ENV ARCH=$ARCH

RUN set -ex && \
   echo $ARCH | sed -e 's/\///'  > /etc/ARCH

# This hack is widely applied to avoid python printing issues in docker containers.
# See: https://github.com/Docker-Hub-frolvlad/docker-alpine-python3/pull/13
ENV PYTHONUNBUFFERED=1
ENV LANG=C.UTF-8

#see below
#ARG GLIBC_REPO=https://github.com/$GLIBC_REPO_INFIX/alpine-pkg-glibc
ARG GLIBC_VERSION=2.32-r0


#inspired by https://github.com/docker-library/python/blob/50bc440273100ee39bb1f1f84ed720a33a0be493/3.9/alpine3.16/Dockerfile
#and by previous addittion that has ca-certificates-bundle without version
RUN set -ex && \
    apk add --no-cache \
		ca-certificates \
        tzdata

#dbus-launch, dbus-run-session
#expat is required by one of the other packages
#13 packages at total
RUN set -ex && \
    apk add --no-cache expat=2.4.7-r0 \
                        dbus-libs=1.12.20-r4 dbus=1.12.20-r4 libxau=1.0.9-r0 libxdmcp=1.1.3-r0 \
                        libxcb=1.14-r2 libx11=1.7.2-r0 dbus-x11=1.12.20-r4


#libgnome-keyring
RUN set -ex && \
   apk add --no-cache libgpg-error=1.42-r1 libgcrypt=1.9.4-r0 \
           libffi=3.4.2-r1 libintl=0.21-r0 libblkid=2.37.4-r0 libmount=2.37.4-r0 pcre=8.45-r1 glib=2.70.1-r0 \
           p11-kit=0.24.0-r1 gcr-base=3.40.0-r0 libcap-ng=0.8.2-r1 linux-pam=1.5.2-r0 \
           gnome-keyring=40.0-r0 libgnome-keyring=3.12.0-r3


#gcc, gfortran, lapack, blas (requires also ssl layer?)
#see https://stackoverflow.com/questions/11912878/gcc-error-gcc-error-trying-to-exec-cc1-execvp-no-such-file-or-directory
#see https://stackoverflow.com/a/38571314/1137529
#see https://unix.stackexchange.com/questions/550290/using-blas-in-alpine-linux
#lapack-dev is installed from openblas-dev
#32 packages installed, one of them is musl-dev
RUN set -ex && \
    apk add --no-cache make=4.3-r0 gcc=11.2.1_git20220219-r2 build-base=0.5-r3 freetype-dev=2.12.1-r0 \
                       gfortran=11.2.1_git20220219-r2 lapack-dev musl-dev=1.2.3-r0 openblas-dev=0.3.20-r0


##ssl, curl
##for curl-dev see https://stackoverflow.com/a/51849028/1137529
##for libffi-dev see https://stackoverflow.com/a/58396708/1137529
##note libffi, musl-dev are installed above
##for cargo see https://github.com/pyca/cryptography/issues/5776#issuecomment-775158562
##21 package is installed
#RUN set -ex && \
#    apk add --no-cache openssl-dev=1.1.1q-r0 cyrus-sasl-dev=2.1.28-r0 \
#                       linux-headers=5.16.7-r1 unixodbc-dev=2.3.11-r0 curl-dev=7.83.1-r2 libffi-dev=3.4.2-r1 \
#                       cargo=1.60.0-r2 musl-dev=1.2.3-r0
#
#
##https://stackoverflow.com/questions/5178416/libxml-install-error-using-pip
##python3-dev (we need C++ header for cffi)
##note make is unstalled above
#RUN set -ex && \
#    apk add --no-cache xz-dev=5.2.5-r1 libxslt=1.1.35-r0 libxml2-dev=2.9.14-r0 libxslt-dev=1.1.35-r0 \
#                       make=4.3-r0 python3-dev


#https://stackoverflow.com/questions/66221278/alpine-docker-define-specific-python-version-python3-3-8-7-r0breaks-worldpyt
#alpine-16 already uses Python 3.

#
#
##Git
#RUN set -ex && \
#   apk add --no-cache pcre2=10.40-r0 git=2.36.2-r0 && \
#   #git config --global credential.helper store
#   #git config --global credential.helper cache
#   #see https://git-scm.com/docs/git-credential-cache
#   git config --global credential.helper 'cache --timeout=3600'
#
#
#
##bash+nano+mlocate
##curl is installed above
#RUN set -ex && \
#    apk --no-cache add bash=5.1.16-r2 nano=6.3-r0 mlocate=0.26-r7 && \
#    updatedb && \
#    #disable coloring for nano, see https://stackoverflow.com/a/55597765/1137529
#    echo "syntax \"disabled\" \".\"" > ~/.nanorc; echo "color green \"^$\"" >> ~/.nanorc

#Cleanup
RUN set -ex && rm -rf /var/cache/apk/* /tmp/* /var/tmp/*
#RUN apk del glibc-i18n make gcc musl-dev build-base gfortran
RUN rm -rf /var/cache/apk/*

WORKDIR /
#CMD ["/bin/sh"]
CMD tail -f /dev/null

##docker system prune --all
#docker rmi -f alpine-python39-amd64 alpine-python39-arm64v8
#docker rm -f py39-amd64 py39-arm64v8
#docker build . -t alpine-python39-amd64 --build-arg ARCH=amd64
#docker build . -t alpine-python39-arm64v8 --build-arg ARCH=arm64/v8
#docker run --name py39-amd64 -d alpine-python39-amd64
#docker run --name py39-arm64v8 -d alpine-python39-arm64v8
#smoke test
#docker exec -it $(docker ps -q -n=1) pip config list
#docker exec -it $(docker ps -q -n=1) bash
##docker build --squash . -t alpine-python39-amd64 --build-arg ARCH=amd64
##docker build --squash . -t alpine-python39-arm64v8 --build-arg ARCH=arm64v8


#see https://github.com/fabioz/PyDev.Debugger
#docker run --env-file .env.docker --name py3 -p 54717:54717/tcp -v //C/dev/work/:/opt/project -v //C/Program\ Files/JetBrains/PyCharm\ 2020.1.4/plugins/python/helpers:/opt/.pycharm_helpers -d alpine-python39
##docker exec -it $(docker ps -q -n=1) dbus-run-session bash
#python /opt/.pycharm_helpers/pydev/pydevconsole.py --mode=server --port=54717 #run
#python -u /opt/.pycharm_helpers/pydev/pydevd.py --cmd-line --multiprocess --qt-support=auto --port 54717 --file /opt/project/alpine-python39/keyring_check.py #debug
#runfile('/opt/project/alpine-anaconda3/keyring_check.py', wdir='/opt/project/alpine-anaconda3')


#docker run --name py3-amd64 -d alpine-python39-amd64
#docker export $(docker ps -q -n=1) | docker import - alpine-python39-amd64-e
#docker run --name py3-amd64-e -d alpine-python39-amd64-e bash
#populate from docker inspect -f "{{ .Config.Env }}" alpine-python39-amd64
#populate from docker inspect -f "{{ .Config.Cmd }}" alpine-python39-amd64
#based on https://docs.docker.com/engine/reference/commandline/commit/
#docker commit --change "CMD /bin/sh" --change "ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin: \
#    ARCH=amd64 \
#    PYTHONUNBUFFERED=1 \
#    LANG=C.UTF-8" \
#    $(docker ps -q -n=1) alpine-python39-amd64-ef

#docker run --name py3-arm64v8 -d alpine-python39-arm64v8
#docker export $(docker ps -q -n=1) | docker import - alpine-python39-arm64v8-e
#docker run --name py3-arm64v8-e -d alpine-python39-arm64v8-e bash
#populate from docker inspect -f "{{ .Config.Env }}" alpine-python39-arm64v8
#populate from docker inspect -f "{{ .Config.Cmd }}" alpine-python39-arm64v8
#based on https://docs.docker.com/engine/reference/commandline/commit/
#docker commit --change "CMD /bin/sh" --change "ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin: \
#    ARCH=arm64v8 \
#    PYTHONUNBUFFERED=1 \
#    LANG=C.UTF-8" \
#    $(docker ps -q -n=1)  alpine-python39-arm64v8-ef


#docker tag alpine-python39-amd64-ef alexberkovich/alpine-python39:0.0.1-amd64
#docker tag alpine-python39-arm64v8-ef alexberkovich/alpine-python39:0.0.1-arm64v8
#docker push alexberkovich/alpine-python39:0.0.1-amd64
#docker push alexberkovich/alpine-python39:0.0.1-arm64v8
#docker manifest create alexberkovich/alpine-python39:0.0.1 --amend alexberkovich/alpine-python39:0.0.1-arm64v8 --amend alexberkovich/alpine-python39:0.0.1-amd64
#docker manifest annotate --arch arm64 --variant v8 alexberkovich/alpine-python39:0.0.1 alexberkovich/alpine-python39:0.0.1-arm64v8
#docker manifest annotate --arch amd64 alexberkovich/alpine-python39:0.0.1 alexberkovich/alpine-python39:0.0.1-amd64
#docker manifest push --purge alexberkovich/alpine-python39:0.0.1

#docker manifest create alexberkovich/alpine-python39:latest --amend alexberkovich/alpine-python39:0.0.1-arm64v8 --amend alexberkovich/alpine-python39:0.0.1-amd64
#docker manifest annotate --arch arm64 --variant v8 alexberkovich/alpine-python39:latest alexberkovich/alpine-python39:0.0.1-arm64v8
#docker manifest annotate --arch amd64 alexberkovich/alpine-python39:latest alexberkovich/alpine-python39:0.0.1-amd64
#docker manifest push --purge alexberkovich/alpine-python39:latest
# EOF

