FROM python:3.7-slim-bullseye

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
COPY deb/wkhtmltox_0.12.6.1-2.bullseye_amd64.deb /wkhtmltox.deb
RUN echo 'deb http://mirrors.aliyun.com/debian/ bullseye main non-free contrib' > /etc/apt/sources.list && \
    echo 'deb http://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib' >> /etc/apt/sources.list && \
    echo 'deb http://mirrors.aliyun.com/debian/ bullseye-backports main non-free contrib' >> /etc/apt/sources.list && \
    echo 'deb http://mirrors.aliyun.com/debian-security bullseye-security main' >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        libldap2-dev \
        libsasl2-dev \
        libssl-dev \
        node-less \
        unzip \
        xfonts-utils \
        xz-utils && \
    echo 'CECBF5A6ABBD68D324A7CD6C51EC843D71E98951 wkhtmltox.deb' | sha1sum -c - && \
    apt-get install -y --no-install-recommends ./wkhtmltox.deb && \
    rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Install latest postgresql-client
RUN echo "deb http://mirrors.aliyun.com/postgresql/repos/apt/ bullseye-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null && \
    apt-get update && \
    apt-get install --no-install-recommends -y postgresql-client libpq-dev && \
    rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/pgdg.list

# Install windows fonts
COPY ./fonts/* /usr/share/fonts/windows/
RUN mkfontscale && mkfontdir && fc-cache -fv

# Install Odoo 12.0 by zip file downloaded from GitHub
ENV ODOO_VERSION 12.0
ENV ODOO_RELEASE=20221013
COPY odoo_${ODOO_VERSION}_${ODOO_RELEASE}.zip /odoo.zip
RUN echo "B417C889E380FC4247D782F3AC67535798689A06 odoo.zip" | sha1sum -c - && \
    unzip -q odoo.zip && \
    mv /odoo-12.0/odoo /usr/local/lib/python3.7/site-packages/ && \
    mv /odoo-12.0/addons/* /usr/local/lib/python3.7/site-packages/odoo/addons/ && \
    echo 'redis==4.5.1' >> /odoo-12.0/requirements.txt && \
    echo 'celery==4.4.7' >> /odoo-12.0/requirements.txt && \
    echo 'importlib-metadata==4.13.0' >> /odoo-12.0/requirements.txt && \
    pip3 install --no-cache-dir -r /odoo-12.0/requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple && \
    rm -rf /odoo.zip /odoo-12.0

# Install project requirements
COPY requirements.txt /
RUN pip3 install --no-cache-dir -r /requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

# Copy entrypoint script and Odoo configuration file
COPY odoo.sample.conf /etc/odoo/odoo.conf
COPY docker-entrypoint.sh /
COPY *.py /usr/local/bin/

# Create user and gourp, create /mnt/extra-addons, set permissions
RUN adduser --system --home "/var/lib/odoo" --quiet --group "odoo" && \
    mkdir -p /mnt/extra-addons && \
    chown odoo /mnt/extra-addons /var/lib/odoo /etc/odoo/odoo.conf && \
    chmod a+x /docker-entrypoint.sh /usr/local/bin/*.py

# Modify werkzeug logging format
RUN cd /usr/local/lib/python3.7/site-packages/werkzeug && \
    sed -i "293s/%s - - \[%s\] %s/%s/" serving.py && \
    sed -i "293s/self.address_string(),/message % args))/" serving.py && \
    sed -i '294,295d' serving.py

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
USER odoo

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["odoo"]