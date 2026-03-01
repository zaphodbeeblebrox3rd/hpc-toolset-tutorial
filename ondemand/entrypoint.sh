#!/bin/bash
set -e

if [ "$1" = "serve" ]
then
    until nc -vzw 2 frontend 22
    do
        echo "-- Waiting for frontend ssh to become active ..."
        sleep 2
    done

    echo "---> Populating /etc/ssh/ssh_known_hosts from frontend for ondemand..."
    /usr/bin/ssh-keyscan frontend >> /etc/ssh/ssh_known_hosts

    echo "---> Waiting for LDAP to be reachable..."
    until nc -vzw 2 ldap 636; do sleep 2; done

    # So PAM/sudo can get account info: longer offline timeout and allow cached creds when offline
    sed -i 's/^offline_timeout = .*/offline_timeout = 60/' /etc/sssd/sssd.conf
    grep -q 'offline_credentials_expiration' /etc/sssd/sssd.conf || sed -i '/^\[pam\]/a offline_credentials_expiration = 2' /etc/sssd/sssd.conf

    # Let passwordless sudo (NOPASSWD) work even when SSSD account lookup fails.
    # PAM account phase normally uses pam_sssd; if SSSD can't reach LDAP, that fails
    # and sudo reports "password required" despite sudoers NOPASSWD. Use pam_permit
    # for account so sudo only relies on sudoers.
    if [ -f /etc/pam.d/sudo ] && grep -q 'account.*system-auth' /etc/pam.d/sudo; then
      sed -i '/^account.*include.*system-auth/s/.*/account    required     pam_permit.so/' /etc/pam.d/sudo
    fi

    echo "---> Starting SSSD on ondemand ..."
    # Sometimes on shutdown pid still exists, so delete it
    rm -f /var/run/sssd.pid
    /sbin/sssd --logger=stderr -d 2 -i 2>&1 &

    echo "---> Cleaning NGINX ..."
    /opt/ood/nginx_stage/sbin/nginx_stage nginx_clean

    echo "---> Starting the MUNGE Authentication service (munged) on ondemand ..."
    gosu munge /usr/sbin/munged

    echo "---> Starting sshd on ondemand..."
    /usr/sbin/sshd -e

    echo "---> Running update ood portal..."
    /opt/ood/ood-portal-generator/sbin/update_ood_portal

    # Disable SSL verification for OIDC provider (Dex on localhost) to avoid handshake failures in container
    for f in /etc/httpd/conf.d/ood*.conf; do
        if [ -f "$f" ] && grep -q 'OIDCProviderMetadataURL' "$f"; then
            grep -q 'OIDCSSLValidateServer' "$f" || sed -i '/OIDCProviderMetadataURL/a \    OIDCSSLValidateServer Off' "$f"
            break
        fi
    done

    echo "---> Starting ondemand-dex..."
    gosu ondemand-dex /usr/sbin/ondemand-dex serve /etc/ood/dex/config.yaml &

    echo "---> Starting ondemand httpd24..."
    # Sometimes on shutdown pid still exists, so delete it
    rm -f /run/httpd/httpd.pid
    /usr/sbin/httpd -DFOREGROUND
fi

exec "$@"
