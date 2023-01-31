FROM debian:stretch-slim

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
COPY ./deb/wkhtmltox_0.12.5-1.stretch_amd64.deb ./wkhtmltox.deb
RUN echo 'deb http://mirrors.aliyun.com/debian/ stretch main non-free contrib' > /etc/apt/sources.list && \
    echo 'deb http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib' >> /etc/apt/sources.list && \
    echo 'deb http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib' >> /etc/apt/sources.list && \
    echo 'deb http://mirrors.aliyun.com/debian-security stretch/updates main' >> /etc/apt/sources.list && \
    apt-get update &&\
    apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        libssl1.0-dev \
        node-less \
        python3-num2words \
        python3-paramiko \
        python3-pip \
        python3-phonenumbers \
        python3-pyldap \
        python3-qrcode \
        python3-renderpm \
        python3-setuptools \
        python3-slugify \
        python3-vobject \
        python3-watchdog \
        python3-xlrd \
        python3-xlwt \
        xz-utils && \
    echo '7e35a63f9db14f93ec7feeb0fce76b30c08f2057 wkhtmltox.deb' | sha1sum -c - && \
    apt-get install -y --no-install-recommends ./wkhtmltox.deb && \
    rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Install latest postgresql-client
RUN echo "deb https://apt-archive.postgresql.org/pub/repos/apt stretch-pgdg-archive main" > /etc/apt/sources.list.d/pgdg.list && \
    curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null && \
    apt-get update && \
    apt-get install --no-install-recommends -y postgresql-client-13 && \
    rm -f /etc/apt/sources.list.d/pgdg.list && \
    rm -rf /var/lib/apt/lists/*

# Install rtlcss
RUN echo "deb https://deb.nodesource.com/node_12.x stretch main" > /etc/apt/sources.list.d/nodesource.list && \
    GNUPGHOME="$(mktemp -d)" && \
    export GNUPGHOME && \
    repokey='9FD3B784BC1C6FC31A8A0A1C1655A0AB68576280' && \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" && \
    gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/nodejs.gpg.asc && \
    gpgconf --kill all && \
    rm -rf "$GNUPGHOME" && \
    apt-get update && \
    apt-get install --no-install-recommends -y nodejs && \
    npm install -g rtlcss && \
    rm -rf /var/lib/apt/lists/*

# Install windows fonts
COPY ./fonts/* /usr/share/fonts/windows/
RUN mkfontscale && mkfontdir && fc-cache -fv

# Install Odoo
ENV ODOO_VERSION 12.0
ARG ODOO_RELEASE=20201026
ARG ODOO_SHA=848d079fdfa76f57bd742c3385096d6743c9532e
COPY ./deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb ./odoo.deb
RUN echo "${ODOO_SHA} odoo.deb" | sha1sum -c - && \
    apt-get update && \
    apt-get -y install --no-install-recommends ./odoo.deb && \
    rm -rf /var/lib/apt/lists/* odoo.deb

# Install project python package
COPY requirements.txt /
RUN pip3 install -q -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

# Copy entrypoint script and Odoo configuration file
COPY entrypoint.sh /
COPY odoo.conf /etc/odoo/
COPY *.py /usr/local/bin/

# Create /mnt/extra-addons and set permissions
RUN mkdir -p /mnt/extra-addons && \
    chown -R odoo /mnt/extra-addons && \
    chown odoo /etc/odoo/odoo.conf && \
    chmod a+x /entrypoint.sh && \
    chmod a+x /usr/local/bin/*.py

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]