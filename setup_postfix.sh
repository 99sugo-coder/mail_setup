#!/bin/bash
# Postfix SMTP 릴레이 설정 스크립트 (AWS 퍼블릭 DNS 자동 사용)
# 사용 예: ./setup_postfix.sh "ID@도메인" "비밀번호"

# ======== 사용자 입력 ========
SMTP_USER="$1"
SMTP_PASS="$2"
SMTP_HOST="$3"
SMTP_PORT="$4"
CN_NAME="$5"

if [ -z "$SMTP_USER" ] || [ -z "$SMTP_PASS" ]; then
    echo "사용법: $0 'ID@도메인' '비밀번호'"
    exit 1
fi


echo "=== 1. SASL 인증 정보 설정 ==="
echo "[$SMTP_HOST]:$SMTP_PORT $SMTP_USER:$SMTP_PASS" > /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd.db

echo "=== 2. Postfix 메인 설정 ==="
postconf -e "relayhost = [$SMTP_HOST]:$SMTP_PORT"
postconf -e "smtp_sasl_auth_enable = yes"
postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
postconf -e "smtp_sasl_security_options = noanonymous"
postconf -e "smtp_tls_security_level = encrypt"
postconf -e "smtp_tls_wrappermode = yes"
postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-bundle.crt"

echo "=== 3. 자체 서명 인증서 생성 ==="
mkdir -p /etc/ssl/private
chmod 700 /etc/ssl/private
openssl req -new -x509 -days 3650 -nodes \
    -out /etc/ssl/certs/postfix-cert.pem \
    -keyout /etc/ssl/private/postfix-key.pem \
    -subj "/C=KR/ST=Seoul/L=Seoul/O=Local/CN=$CN_NAME"
chmod 644 /etc/ssl/certs/postfix-cert.pem
chmod 600 /etc/ssl/private/postfix-key.pem

echo "=== 4. 인증서 경로 Postfix에 반영 ==="
postconf -e "smtpd_tls_cert_file=/etc/ssl/certs/postfix-cert.pem"
postconf -e "smtpd_tls_key_file=/etc/ssl/private/postfix-key.pem"
postconf -e "smtpd_tls_security_level=may"

echo "=== 5. master.cf에서 submission TLS 비활성화 ==="
# 기존 submission 라인 주석 처리
sed -i '/^submission\s\+inet/,+3 s/^/#/' /etc/postfix/master.cf
# 새 설정 추가
cat <<EOL >> /etc/postfix/master.cf

submission inet n       -       n       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=none
  -o smtpd_tls_auth_only=no
EOL

echo "=== 6. Postfix 재시작 ==="
systemctl restart postfix

echo "=== 완료: Postfix SMTP 릴레이 설정이 적용되었습니다. ==="
