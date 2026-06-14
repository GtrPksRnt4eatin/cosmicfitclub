#!/bin/bash
# ============================================================
# Renew the Let's Encrypt certificate for loft.cosmicfitclub.com
# using the DNS-01 challenge via the DNSimple API.
#
# Prerequisites (run once):
#   sudo apt install python3-certbot-dns-dnsimple
#   sudo mkdir -p /etc/letsencrypt/dnsimple
#   echo 'dns_dnsimple_token = YOUR_DNSIMPLE_API_TOKEN' | \
#     sudo tee /etc/letsencrypt/dnsimple/credentials.ini
#   sudo chmod 600 /etc/letsencrypt/dnsimple/credentials.ini
#
# Usage:
#   sudo ./utilities/renew_loft_cert.sh
#
# Automatic renewal (cron) — run as root, fires twice a month:
#   0 3 1,15 * * /home/bklein/repos/cosmicfit/utilities/renew_loft_cert.sh >> /var/log/loft_cert_renew.log 2>&1
# ============================================================

set -euo pipefail

DOMAIN="loft.cosmicfitclub.com"
CERT_SRC="/etc/letsencrypt/live/${DOMAIN}"
CERT_DST="$(cd "$(dirname "$0")" && pwd)/certs/loft"
CREDENTIALS="/etc/letsencrypt/dnsimple/credentials.ini"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a /var/log/loft_cert_renew.log; }

# ── Load camera credentials (required) ──────────────────────
if [[ ! -f /etc/loft_camera.env ]]; then
  echo "ERROR: /etc/loft_camera.env not found."
  echo "Copy utilities/loft_camera.env.example to /etc/loft_camera.env and fill in values."
  exit 1
fi
source /etc/loft_camera.env

# ── Must run as root ──────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo: sudo $0"
  exit 1
fi

# ── Check prerequisites ───────────────────────────────────────
if ! python3 -c 'import certbot_dns_dnsimple' 2>/dev/null; then
  echo "ERROR: certbot-dns-dnsimple not installed."
  echo "Run: sudo apt install python3-certbot-dns-dnsimple"
  exit 1
fi

if [[ ! -f "$CREDENTIALS" ]]; then
  echo "ERROR: DNSimple credentials file not found at ${CREDENTIALS}"
  echo "Create it with:"
  echo "  sudo mkdir -p /etc/letsencrypt/dnsimple"
  echo "  echo 'dns_dnsimple_token = YOUR_API_TOKEN' | sudo tee ${CREDENTIALS}"
  echo "  sudo chmod 600 ${CREDENTIALS}"
  exit 1
fi

log "=== Starting certificate renewal for ${DOMAIN} ==="

if [[ -d "$CERT_SRC" ]]; then
  log "Existing cert found — renewing via DNS-01 (DNSimple) ..."
else
  log "No existing cert found — issuing new certificate via DNS-01 (DNSimple) ..."
fi

certbot certonly \
  --dns-dnsimple \
  --dns-dnsimple-credentials "$CREDENTIALS" \
  --dns-dnsimple-propagation-seconds 30 \
  --non-interactive \
  --agree-tos \
  --register-unsafely-without-email \
  --force-renewal \
  -d "$DOMAIN"

# ── Copy cert files to utilities/certs/loft/ ───────────────────
log "Copying certificate files to ${CERT_DST} ..."
mkdir -p "$CERT_DST"
cp -L "${CERT_SRC}/fullchain.pem" "${CERT_DST}/server.crt"
cp -L "${CERT_SRC}/privkey.pem"   "${CERT_DST}/server.key"
cp -L "${CERT_SRC}/chain.pem"     "${CERT_DST}/chain.pem"
chmod 600 "${CERT_DST}/server.key"

# ── Upload certificate to loft camera via ONVIF SOAP ─────────
# The Axis M3004 uses ONVIF tds:LoadCertificateWithPrivateKey for cert management.
# The camera must be reachable on its LAN IP from this machine.
CAMERA_IP="${AXIS_CAMERA_IP:-192.168.1.5}"
CAMERA_USER="${AXIS_CAMERA_USER:-root}"
CAMERA_PASS="${AXIS_CAMERA_PASS:-}"
ONVIF_USER="${AXIS_ONVIF_USER:-${CAMERA_USER}}"
ONVIF_PASS="${AXIS_ONVIF_PASS:-${CAMERA_PASS}}"

if [[ -z "$CAMERA_IP" || -z "$CAMERA_PASS" ]]; then
  log "WARN: AXIS_CAMERA_IP or AXIS_CAMERA_PASS not set — skipping auto-upload."
  log "      Set them in /etc/loft_camera.env to enable auto-upload."
else
  log "Uploading certificate to camera at ${CAMERA_IP} via ONVIF ..."

  # Helper: send an ONVIF SOAP request with WS-Security digest auth
  # WS-Security spec: PasswordDigest = Base64(SHA1(binary_nonce + created + password))
  # The nonce sent in XML is Base64(binary_nonce); the hash uses the raw binary bytes.
  onvif_soap() {
    local body="$1"
    local nonce_hex nonce created password_digest
    nonce_hex=$(openssl rand -hex 16)
    nonce=$(echo -n "$nonce_hex" | xxd -r -p | base64)
    created=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    password_digest=$( (echo -n "$nonce_hex" | xxd -r -p; printf '%s' "${created}${ONVIF_PASS}") | openssl dgst -sha1 -binary | base64)
    curl -sk -X POST \
      -H "Content-Type: application/soap+xml" \
      --data-binary "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<SOAP-ENV:Envelope
  xmlns:SOAP-ENV=\"http://www.w3.org/2003/05/soap-envelope\"
  xmlns:tds=\"http://www.onvif.org/ver10/device/wsdl\"
  xmlns:tt=\"http://www.onvif.org/ver10/schema\"
  xmlns:wsse=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\"
  xmlns:wsu=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\">
  <SOAP-ENV:Header>
    <wsse:Security>
      <wsse:UsernameToken>
        <wsse:Username>${ONVIF_USER}</wsse:Username>
        <wsse:Password Type=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest\">${password_digest}</wsse:Password>
        <wsse:Nonce EncodingType=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary\">${nonce}</wsse:Nonce>
        <wsu:Created>${created}</wsu:Created>
      </wsse:UsernameToken>
    </wsse:Security>
  </SOAP-ENV:Header>
  <SOAP-ENV:Body>${body}</SOAP-ENV:Body>
</SOAP-ENV:Envelope>" \
      "https://${CAMERA_IP}/onvif/device_service"
  }

  CERT_ID="letsencrypt-$(date +%Y%m%d)"
  CERT_B64=$(base64 -w0 "${CERT_DST}/server.crt")
  KEY_B64=$(base64 -w0 "${CERT_DST}/server.key")

  # Get existing cert IDs to clean up afterwards
  OLD_CERT_IDS=$(onvif_soap "<tds:GetCertificates/>" | \
    grep -o '<tt:CertificateID>[^<]*</tt:CertificateID>' | \
    sed 's|<[^>]*>||g' | grep "letsencrypt" || true)

  # Upload cert + private key in one call
  LOAD_RESPONSE=$(onvif_soap "
    <tds:LoadCertificateWithPrivateKey>
      <tds:CertificateWithPrivateKey>
        <tt:CertificateID>${CERT_ID}</tt:CertificateID>
        <tt:Certificate><tt:Data>${CERT_B64}</tt:Data></tt:Certificate>
        <tt:PrivateKey><tt:Data>${KEY_B64}</tt:Data></tt:PrivateKey>
      </tds:CertificateWithPrivateKey>
    </tds:LoadCertificateWithPrivateKey>")

  if echo "$LOAD_RESPONSE" | grep -qi "fault\|NotAuthorized"; then
    log "ERROR: ONVIF certificate upload failed:"
    echo "$LOAD_RESPONSE" | grep -o 'Text>[^<]*' | head -5
    exit 1
  fi
  log "Certificate uploaded (ID: ${CERT_ID})."

  # Activate the new certificate for HTTPS
  ACTIVATE_RESPONSE=$(onvif_soap "
    <tds:SetCertificatesStatus>
      <tds:CertificateStatus>
        <tt:CertificateID>${CERT_ID}</tt:CertificateID>
        <tt:Status>true</tt:Status>
      </tds:CertificateStatus>
    </tds:SetCertificatesStatus>")

  if echo "$ACTIVATE_RESPONSE" | grep -qi "fault"; then
    log "WARN: Activation via SetCertificatesStatus failed — trying SetClientCertificateMode ..."
    onvif_soap "
      <tds:SetClientCertificateMode>
        <tds:Enabled>true</tds:Enabled>
      </tds:SetClientCertificateMode>" > /dev/null || true
  else
    log "Certificate activated on camera."
  fi

  # Remove old letsencrypt certs
  for old_id in $OLD_CERT_IDS; do
    [[ "$old_id" == "$CERT_ID" ]] && continue
    log "Removing old certificate: ${old_id}"
    onvif_soap "<tds:DeleteCertificates><tds:CertificateID>${old_id}</tds:CertificateID></tds:DeleteCertificates>" > /dev/null || true
  done
fi

# ── Show expiry of the new cert ───────────────────────────────
EXPIRY=$(openssl x509 -noout -enddate -in "${CERT_DST}/server.crt" | cut -d= -f2)
log "Certificate valid until: ${EXPIRY}"

log "=== Renewal complete ==="
