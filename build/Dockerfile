FROM python:3.7-slim-bullseye

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Set deb mirrors
RUN echo 'deb http://mirrors.aliyun.com/debian/ bullseye main non-free contrib' > /etc/apt/sources.list && \
    echo 'deb http://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib' >> /etc/apt/sources.list && \
    echo 'deb http://mirrors.aliyun.com/debian/ bullseye-backports main non-free contrib' >> /etc/apt/sources.list && \
    echo 'deb http://mirrors.aliyun.com/debian-security bullseye-security main' >> /etc/apt/sources.list

# Install essential packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libldap2-dev \
    libsasl2-dev \
    libssl-dev \
    node-less \
    xz-utils

# Install wkhtmltopdf
COPY deb/wkhtmltox_0.12.6.1-2.bullseye_amd64.deb /wkhtmltox.deb
RUN echo 'CECBF5A6ABBD68D324A7CD6C51EC843D71E98951 wkhtmltox.deb' | sha1sum -c - && \
    apt-get update && apt-get install -y --no-install-recommends ./wkhtmltox.deb && \
    rm -f wkhtmltox.deb

# Install fonts
COPY ./fonts/* /usr/share/fonts/windows/
RUN apt-get update && apt-get install -y xfonts-utils fonts-noto-cjk && \
    mkfontscale && mkfontdir && fc-cache -fv

# Install latest postgresql-client
RUN apt-get update && apt-get install -y --no-install-recommends curl gnupg dirmngr && \
    echo "deb http://mirrors.aliyun.com/postgresql/repos/apt/ bullseye-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null && \
    apt-get update && apt-get install -y --no-install-recommends postgresql-client libpq-dev && \
    rm /etc/apt/sources.list.d/pgdg.list

# Copy Odoo 12.0 zip file downloaded from GitHub
ENV ODOO_VERSION 12.0
ENV ODOO_RELEASE=20221013
COPY odoo_${ODOO_VERSION}_${ODOO_RELEASE}.zip /odoo.zip
RUN echo "B417C889E380FC4247D782F3AC67535798689A06 odoo.zip" | sha1sum -c - && \
    apt-get update && apt-get install -y --no-install-recommends unzip && \
    unzip -q odoo.zip && \
    mv /odoo-12.0/odoo /usr/local/lib/python3.7/site-packages/ && \
    mv /odoo-12.0/addons/* /usr/local/lib/python3.7/site-packages/odoo/addons/ && \
    apt-get remove -y unzip && apt-get -y autoremove && \
    rm -rf /odoo.zip /odoo-12.0

# Install python requirements
COPY requirements.txt /requirements.txt
RUN apt-get update && apt-get install -y --no-install-recommends build-essential && \
    pip3 install --no-cache-dir\
      -r /requirements.txt \
      -i https://pypi.tuna.tsinghua.edu.cn/simple && \
    apt-get remove -y build-essential && apt-get -y autoremove

# Modify werkzeug logging format
RUN cd /usr/local/lib/python3.7/site-packages/werkzeug && \
    sed -i "293s/%s - - \[%s\] %s/%s/" serving.py && \
    sed -i "293s/self.address_string(),/message % args))/" serving.py && \
    sed -i '294,295d' serving.py

# Copy entrypoint script, wait scripts and oddoo configuration file
COPY odoo.conf /etc/odoo/odoo.conf
COPY docker-entrypoint.sh /
COPY *.py /usr/local/bin/

# Create user and gourp, create /mnt/extra-addons, set permissions
RUN mkdir -p /mnt/extra-addons && \
    adduser --system --home "/var/lib/odoo" --quiet --group "odoo" && \
    chown odoo /var/lib/odoo /etc/odoo/odoo.conf /mnt/extra-addons /docker-entrypoint.sh /usr/local/bin/*.py && \
    chmod u+x /docker-entrypoint.sh /usr/local/bin/*.py

# Odoo server HTTP/1.1 Patch
RUN sed -i "128i\        self.protocol_version = \"HTTP/1.1\"" \
    /usr/local/lib/python3.7/site-packages/odoo/service/server.py

# Mount /var/lib/odoo to allow restoring filestore
VOLUME ["/var/lib/odoo"]

# Expose Odoo services
EXPOSE 8069 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
USER odoo

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["odoo"]