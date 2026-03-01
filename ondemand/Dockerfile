ARG HPCTS_VERSION=latest

FROM --platform=linux/amd64 ubccr/hpcts:slurm-${HPCTS_VERSION} as stage-amd64
# Install rclone binary from official download (rclone not in EPEL 8; ondemand RPM Requires: rclone)
RUN dnf install -y curl unzip \
    && curl -sL -o /tmp/rclone.zip https://downloads.rclone.org/rclone-current-linux-amd64.zip \
    && unzip -q -d /tmp /tmp/rclone.zip \
    && cp /tmp/rclone-*-linux-amd64/rclone /usr/bin/ \
    && chmod 755 /usr/bin/rclone \
    && rm -rf /tmp/rclone.zip /tmp/rclone-*-linux-amd64
# Dummy rclone RPM so dnf dependency is satisfied; then install ondemand
RUN dnf install -y https://yum.osc.edu/ondemand/3.0/ondemand-release-web-3.0-1.noarch.rpm \
    && dnf install -y rpm-build \
    && mkdir -p /tmp/rclone-build/{BUILD,RPMS,SOURCES,SPECS,SRPMS} \
    && echo -e 'Summary: Satisfies ondemand rclone dependency\nName: rclone\nVersion: 1.0\nRelease: 1\nLicense: MIT\n%description\nDummy package.\n%install\nmkdir -p %{buildroot}/usr/share/rclone\ntouch %{buildroot}/usr/share/rclone/.placeholder\n%files\n/usr/share/rclone/.placeholder\n' > /tmp/rclone.spec \
    && rpmbuild -bb --define '_topdir /tmp/rclone-build' /tmp/rclone.spec \
    && rpm -ivh /tmp/rclone-build/RPMS/*/rclone-1.0-1.*.rpm \
    && rm -rf /tmp/rclone.spec /tmp/rclone-build
RUN dnf install -y netcat ondemand ondemand-dex libyaml-devel
RUN gem install rdoc -v 6.3.3

FROM --platform=linux/arm64 ubccr/hpcts:slurm-${HPCTS_VERSION} as stage-arm64
RUN dnf install -y file lsof sudo gcc gcc-c++ git \
        patch lua-posix rsync ruby ruby-devel python2 python3 \
        nodejs sqlite sqlite-devel nmap-ncat httpd httpd-devel mod_ssl \
        libcurl-devel autoconf openssl-devel jansson-devel libxml2-devel \
        libxslt-devel gd-devel libaio-devel libyaml-devel
RUN gem install rake dotenv bcrypt && gem install rdoc -v 6.3.3
COPY . /build
RUN /build/install-dex-arm64.sh
RUN /build/install-passenger-arm64.sh
RUN /build/install-ood-arm64.sh
RUN rm -rf /build

FROM stage-amd64 AS final

COPY . /build
RUN /build/install.sh && rm -rf /build
COPY cluster-config.yml /etc/ood/config/clusters.d/hpc.yml
COPY bc_desktop.yml /etc/ood/config/apps/bc_desktop/hpc.yml
COPY jupyter /var/www/ood/apps/sys/jupyter
COPY python_job_template /etc/ood/config/apps/myjobs/templates/python
COPY motd /etc/motd
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY notebook_data /data/notebook_data
COPY initializers /etc/ood/config/apps/dashboard/initializers
COPY themes/hpc-coop /usr/share/ondemand-dex/web/themes/hpc-coop
COPY config/dashboard/env /etc/ood/config/apps/dashboard/env
COPY config/ondemand.yml /etc/ood/config/ondemand.d/ondemand.yml
COPY config/dashboard/widgets /etc/ood/config/apps/dashboard/views/widgets

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
