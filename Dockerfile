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
#https://stackoverflow.com/questions/68673221/warning-running-pip-as-the-root-user
ENV PIP_ROOT_USER_ACTION=ignore

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
    apk add --no-cache make=4.3-r0 gcc=10.3.1_git20211027-r0 build-base=0.5-r3 freetype-dev=2.11.1-r2 \
                       gfortran=10.3.1_git20211027-r0 lapack-dev musl-dev=1.2.2-r7 openblas-dev=0.3.18-r1


#ssl, curl
#for curl-dev see https://stackoverflow.com/a/51849028/1137529
#for libffi-dev see https://stackoverflow.com/a/58396708/1137529
#note libffi, musl-dev are installed above
#for cargo see https://github.com/pyca/cryptography/issues/5776#issuecomment-775158562
#21 package is installed
RUN set -ex && \
    apk add --no-cache openssl-dev=1.1.1q-r0 cyrus-sasl-dev=2.1.28-r0 \
                       linux-headers=5.10.41-r0 unixodbc-dev=2.3.9-r1 curl-dev=7.80.0-r2 libffi-dev=3.4.2-r1 \
                       cargo=1.56.1-r0 musl-dev=1.2.2-r7

#https://github.com/h5py/h5py/issues/1461#issuecomment-562871041
#https://stackoverflow.com/questions/66705108/how-to-install-hdf5-on-docker-image-with-linux-alpine-3-13
RUN set -ex && \
    apk add --no-cache hdf5-dev=1.12.2-r0




#Git
RUN set -ex && \
   apk add --no-cache pcre2=10.40-r0 git=2.34.4-r0 && \
   #git config --global credential.helper store
   #git config --global credential.helper cache
   #see https://git-scm.com/docs/git-credential-cache
   git config --global credential.helper 'cache --timeout=3600'



#bash+nano+mlocate
#curl is installed above
RUN set -ex && \
    apk --no-cache add bash=5.1.16-r0 nano=5.9-r0 mlocate=0.26-r7 && \
    updatedb && \
    #disable coloring for nano, see https://stackoverflow.com/a/55597765/1137529
    echo "syntax \"disabled\" \".\"" > ~/.nanorc; echo "color green \"^$\"" >> ~/.nanorc

#install glibc (another c++ compiler, older one)
# do all in one step
RUN set -ex && \
    #Remarked by Alex \
    #apk -U upgrade && \
    #Alex added --no-cache
    apk --no-cache add libstdc++=10.3.1_git20211027-r0 curl=7.80.0-r2 && \
    #Added  by Alex \
    #Alex added --no-cache
    apk --no-cache add mii-tool=1.60_git20140218-r2 net-tools=1.60_git20140218-r2 && \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    #Added by Alex \
    if [ "$ARCH" = "arm64v8" ]; then suffix='-arm64'; else suffix=''; fi && \
    #Added by Alex \
    if [ "$ARCH" = "arm64v8" ]; then infix='ljfranklin'; else infix='sgerrand'; fi && \
    GLIBC_REPO=https://github.com/$infix/alpine-pkg-glibc && \
    for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do curl -sSL ${GLIBC_REPO}/releases/download/${GLIBC_VERSION}${suffix}/${pkg}.apk -o /tmp/${pkg}.apk; done  && \
    #Alex added --no-cache
    apk --no-cache --allow-untrusted add /tmp/*.apk && \
    rm -v /tmp/*.apk && \
    ( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true ) && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib

#https://stackoverflow.com/questions/9510474/removing-pips-cache
#https://pip.pypa.io/en/stable/reference/pip_install/#caching
#pip config set global.cache-dir false doesn't work
#https://stackoverflow.com/questions/9510474/removing-pips-cache/61762308#61762308
RUN mkdir -p /root/.config/pip
RUN echo "[global]" > /root/.config/pip/pip.conf; echo "no-cache-dir = false" >> /root/.config/pip/pip.conf; echo >> /root/.config/pip/pip.conf;



#https://stackoverflow.com/questions/5178416/libxml-install-error-using-pip
#python3-dev (we need C++ header for cffi)
#note make is unstalled above
RUN set -ex && \
    apk add --no-cache libxslt=1.1.35-r0 libxslt-dev=1.1.35-r0 \
                        libxml2-dev=2.9.14-r1 python3-dev=3.9.13-r1


#https://stackoverflow.com/a/62555259/1137529
RUN set -ex && \
    ln -s /usr/bin/python3.9 /usr/bin/python && \
    ln -s /usr/bin/python3.9-config /usr/bin/python-config && \
    python -m ensurepip && \
    cp /usr/bin/pip3.9 /usr/bin/pip


RUN set -ex && \
   pip install --upgrade pip==22.2.2 setuptools==58.1.0 wheel==0.36.1

RUN set -ex && \
    pip install ruamel_yaml==0.15.100

RUN set -ex && \
        #entrypoints==0.2.3 used in setup.py
        #This version of PyYAML==5.1 works with awscli
        #pyyaml installation from pypi
        pip install entrypoints==0.2.3 pyyaml==5.1 && \
        pip install MarkupSafe==2.0.1 Jinja2==2.11.2 && \
        pip install toml==0.10.2


#slim
RUN set -ex && \
        pip install attrs==20.2.0 && \
        pip install bcrypt==3.2.0 six==1.16.0 pycparser==2.21 cffi==1.15.0 && \
        pip install charset-normalizer==2.0.4 certifi==2022.6.15 idna==3.3 urllib3==1.26.9 requests==2.27.1 && \
        pip install six==1.16.0 python-dateutil==2.8.2 && \
        pip install cffi==1.15.0 cryptography==3.4.8 && \
        pip install cffi==1.15.0 cryptography==3.4.8 pyOpenSSL==21.0.0 && \
        #Fabric
        pip install bcrypt==3.2.0 PyNaCl==1.3.0 paramiko==2.7.2 invoke==1.4.1 fabric==2.5.0 && \
        #pytest+mock
        pip install iniconfig==1.1.1 packaging==20.4 pluggy==0.13.1 py==1.9.0 pyparsing==2.4.7 \
                  pytest-assume==2.3.3 pytest-mock==3.3.1 pytest==6.1.2 mock==4.0.2 && \
        pip install python-dotenv==0.20.0 && \
        pip install bidict==0.22.0 && \
        #boto3
        pip install rsa==4.7.2 pyasn1==0.4.8 jmespath==1.0.1 docutils==0.16 s3transfer==0.6.0 colorama==0.4.4 \
               awscli==1.25.60 botocore==1.27.59 boto3==1.24.59 && \
        #SQLAlchemy & Hive & Postgress
        pip install thrift==0.16.0 thrift-sasl==0.4.3 sasl==0.3.1 pure-sasl==0.6.2 pure-transport==0.2.0 \
                     future==0.18.2 PyHive==0.6.5 pg8000==1.19.3 SQLAlchemy==1.4.11 && \
        #Twine (old pkginfo==1.6.1 rfc3986==1.4.0 readme-renderer==28.0)   \
        pip install Pygments==2.13.0 SecretStorage==3.3.3 bleach==5.0.1 importlib-metadata==4.12.0 \
                  requests-toolbelt==0.9.1 readme-renderer==37.0 rfc3986==2.0.0 pkginfo==1.8.3 \
                    jeepney==0.8.0 keyring==23.8.2 tqdm==4.64.0  webencodings==0.5.1 zipp==3.8.1 twine==3.2.0

#nltk-data
#RUN set -ex && python -m nltk.downloader -d /usr/share/nltk_data all

RUN set -ex && pip freeze > /etc/installed.txt

#Cleanup
RUN set -ex && rm -rf /var/cache/apk/* /tmp/* /var/tmp/*
#RUN apk del glibc-i18n make gcc musl-dev build-base gfortran
RUN rm -rf /var/cache/apk/*

COPY enter_keyring.sh /etc/enter_keyring.sh
COPY reuse_keyring.sh /etc/reuse_keyring.sh
COPY unlock_keyring.sh /etc/unlock_keyring.sh
COPY rest_keyring.sh /etc/rest_keyring.sh


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

