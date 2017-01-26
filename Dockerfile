FROM alpine:edge
MAINTAINER Jeremy T. Bouse <Jeremy.Bouse@UnderGrid.net>

RUN set -ex && \
    apk upgrade --update && \
    apk add --no-cache postfix postfix-pcre postfix-pgsql ca-certificates policyd-spf-fs curl && \
    curl -L -s https://github.com/just-containers/s6-overlay/releases/download/v1.18.1.5/s6-overlay-amd64.tar.gz | tar xvzf - -C /  && \
    apk del --no-cache curl && \
    (rm -rf /var/cache/apk/* 2>/dev/null || true) 

RUN postconf -e virtual_alias_maps= && \
    postconf -e virtual_mailbox_domains= && \
    postconf -e virtual_mailbox_maps= && \
    postconf -e virtual_transport=lmtp:imap.undergrid.net:24 && \
    postconf -e append_dot_mydomain=no && \
    postconf -e biff=no && \
    postconf -e content_filter=amavis:amavis:10024 && \
    postconf -e disable_vrfy_command=yes && \
    postconf -e header_checks=regexp:/etc/postfix/header_checks && \
    postconf -e mailbox_size_limit=0 && \
    postconf -e masquerade_classes="envelop_sender, envelope_recipient, header_sender, header_recipient" && \
    postconf -e masquerade_domains="undergrid.net undergrid.com" && \
    postconf -e receive_override_options=no_address_mappings && \
    postconf -e recipient_delimiter=+ && \
    postconf -e smtp_header_checks=regexp:/etc/postfix/header_checks && \
    postconf -e smtp_tls_CAfile=/etc/ssl/certs/ca-certificates.crt && \
    postconf -e smtp_tls_exclude_ciphers=aNULL && \
    postconf -e smtp_tls_mandatory_exclude_ciphers="RC4, MD5" && \
    postconf -e smtp_tls_mandatory_protocols="!SSLv2, !SSLv3" && \
    postconf -e smtp_tls_note_starttls_offer=yes && \
    postconf -e smtp_tls_protocols="!SSLv2, !SSLv3" && \
    postconf -e smtp_tls_security_level=may && \
    postconf -e smtp_tls_session_cache_database=btree:${data_directory}/smtp_scache && \
    postconf -e smtpd_client_restrictions="permit_mynetworks, permit_sasl_authenticated, reject_rbl_client zen.spamhaus.org, reject_rbl_client bl.spamcop.net, reject_rbl_client bogons.cymru.com" && \
    postconf -e smtpd_data_restrictions=reject_unauth_pipelining && \
    postconf -e smtpd_helo_required=yes && \
    postconf -e smtpd_helo_restrictions="permit_mynetworks, reject_non_fqdn_helo_hostname, reject_invalid_helo_hostname" && \
    postconf -e smtpd_recipient_restrictions="reject_non_fqdn_sender, reject_unknown_sender_domain, reject_non_fqdn_recipient, reject_unknown_recipient_domain, permit_mynetworks, permit_sasl_authenticated, reject_unauth_pipelining, reject_unauth_destination, reject_invalid_helo_hostname, reject_non_fqdn_helo_hostname, reject_rbl_client zen.spamhaus.org, reject_rbl_client bl.spamcop.net, reject_rbl_client bogons.cymru.com, check_policy_service unix:private/policyd-spf" && \
    postconf -e smtpd_sasl_auth_enable=yes && \
    postconf -e smtpd_sasl_authenticated_header=yes && \
    postconf -e smtpd_sasl_path=inet:imap.undergrid.net:54321 && \
    postconf -e smtpd_sasl_type=dovecot && \
    postconf -e smtpd_sender_restrictions="reject_non_fqdn_sender, reject_unknown_sender_domain, check_client_access cidr:/etc/postfix/drop.cidr, check_sender_ns_access cidr:/etc/postfix/drop.cidr, check_sender_mx_access cidr:/etc/postfix/drop.cidr, reject_rbl_client bogons.cymru.com, check_sender_access pcre:/etc/postfix/sender_access, permit_sasl_authenticated, permit_mynetworks" && \
    postconf -e smtpd_tls_CAfile=/etc/ssl/certs/ca-certificates.crt && \
    postconf -e smtpd_tls_auth_only=yes && \
    postconf -e smtpd_tls_cert_file=/etc/ssl/certs/server.crt && \
    postconf -e smtpd_tls_dh1024_param_file=${config_directory}/dhparams.pem && \
    postconf -e smtpd_tls_exclude_ciphers="aNULL, eNULL, EXPORT, DES, RC4, MD5, PSK, aECDH, EDH-DSS-DES-CBC4-SHA, EDH-RSA-DES-CDC3-SHA, KRB5-DES, CBC3-SHA" && \
    postconf -e smtpd_tls_key_file=/etc/ssl/private/server.key && \
    postconf -e smtpd_tls_mandatory_protocols="!SSLv2, !SSLv3" && \
    postconf -e smtpd_tls_received_header=yes && \
    postconf -e smtpd_tls_security_level=may && \
    postconf -e smtpd_tls_session_cache_database=btree:${data_directory}/smtpd_scache && \
    postconf -e smtpd_use_tls=yes && \
    postconf -e strict_rfc821_envelopes=yes

RUN postconf -M submission/inet="submission inet n - n - - smtpd" && \
    postconf -P "submission/inet/syslog_name=postfix/submission" && \
    postconf -P "submission/inet/smtpd_tls_security_level=encrypt" && \
    postconf -P "submission/inet/smtpd_sasl_auth_enable=yes" && \
    postconf -P "submission/inet/smtpd_client_restrictions= permit_sasl_authenticated,reject" && \
    postconf -P "submission/inet/milter_macro_daemon_name=ORIGINATING" && \
    postconf -M amavis/unix="amavis unix - - n - 2 lmtp" && \
    postconf -P "amavis/unix/lmtp_data_done_timeout=1200" && \
    postconf -P "amavis/unix/lmtp_send_xforward_command=yes" && \
    postconf -P "amavis/unix/disable_dns_lookups=yes" && \
    postconf -P "amavis/unix/max_use=20" && \
    postconf -M 10025/inet="10025 inet n - n - - smtpd" && \
    postconf -P "10025/inet/content_filter=" && \
    postconf -P "10025/inet/smtpd_delay_reject=no" && \
    postconf -P "10025/inet/smtpd_client_restrictions= permit_mynetworks,reject" && \
    postconf -P "10025/inet/smtpd_helo_restrictions=" && \
    postconf -P "10025/inet/smtpd_sender_restrictions=" && \
    postconf -P "10025/inet/smtpd_recipient_restrictions= permit_mynetworks,reject" && \
    postconf -P "10025/inet/smtpd_data_restrictions=reject_unauth_pipelining" && \
    postconf -P "10025/inet/smtpd_end_of_data_restrictions=" && \
    postconf -P "10025/inet/smtpd_restriction_classes=" && \
    postconf -P "10025/inet/mynetworks=10.0.0.0/8" && \
    postconf -P "10025/inet/smtpd_error_sleep_time=0" && \
    postconf -P "10025/inet/smtpd_soft_error_limit=1001" && \
    postconf -P "10025/inet/smtpd_hard_error_limit=1000" && \
    postconf -P "10025/inet/smtpd_client_connection_count_limit=0" && \
    postconf -P "10025/inet/smtpd_client_connection_rate_limit=0" && \
    postconf -P "10025/inet/receive_override_options= no_header_body_checks,no_unknown_recipient_checks,no_milters" && \
    postconf -P "10025/inet/local_header_rewrite_clients=" && \
    postconf -P "10025/inet/smtpd_milters=" && \
    postconf -P "10025/inet/local_recipient_maps=" && \
    postconf -P "10025/inet/relay_recipient_maps=" && \
    postconf -M policyd-spf/unix="policyd-spf unix - n n - - spawn user=nobody argv=/usr/bin/policyd-spf-fs -debug 1"
    
EXPOSE 25 587

ENTRYPOINT ["/init"]