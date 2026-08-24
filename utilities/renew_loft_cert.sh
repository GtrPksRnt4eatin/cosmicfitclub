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

if [[ -z "$CAMERA_IP" || -z "$CAMERA_PASS" ]]; then
  log "WARN: AXIS_CAMERA_IP or AXIS_CAMERA_PASS not set — skipping auto-upload."
  log "      Set them in /etc/loft_camera.env to enable auto-upload."
else
  log "Uploading certificate to camera at ${CAMERA_IP} ..."

  ONVIF_USER="${AXIS_ONVIF_USER:-${CAMERA_USER}}"
  ONVIF_PASS="${AXIS_ONVIF_PASS:-${CAMERA_PASS}}"

  # ── Helper: WS-Security PasswordDigest ONVIF SOAP call ──────────────────────
  # Uses the camera's own clock for the Created timestamp to avoid skew rejection.
  # PasswordDigest = Base64(SHA1(nonce_bytes || created_utf8 || password_utf8))
  onvif_soap() {
    local body="$1" use_created="${2:-}"
    local nonce_hex nonce created password_digest
    nonce_hex=$(openssl rand -hex 16)
    nonce=$(printf '%s' "$nonce_hex" | xxd -r -p | base64)
    # Use caller-supplied timestamp (camera's clock) if provided, else local time
    if [[ -n "$use_created" ]]; then
      created="$use_created"
    else
      created=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    fi
    password_digest=$( (printf '%s' "$nonce_hex" | xxd -r -p; printf '%s' "${created}${ONVIF_PASS}") \
      | openssl dgst -sha1 -binary | base64)
    curl -sk --max-time 10 -X POST \
      -H "Content-Type: application/soap+xml; charset=utf-8" \
      --data-binary "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<s:Envelope xmlns:s=\"http://www.w3.org/2003/05/soap-envelope\"
            xmlns:tds=\"http://www.onvif.org/ver10/device/wsdl\"
            xmlns:tt=\"http://www.onvif.org/ver10/schema\"
            xmlns:wsse=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\"
            xmlns:wsu=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\">
  <s:Header>
    <wsse:Security>
      <wsse:UsernameToken>
        <wsse:Username>${ONVIF_USER}</wsse:Username>
        <wsse:Password Type=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest\">${password_digest}</wsse:Password>
        <wsse:Nonce EncodingType=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary\">${nonce}</wsse:Nonce>
        <wsu:Created>${created}</wsu:Created>
      </wsse:UsernameToken>
    </wsse:Security>
  </s:Header>
  <s:Body>${body}</s:Body>
</s:Envelope>" \
      "https://${CAMERA_IP}/onvif/device_service" || true
  }

  # ── Step 1: get camera clock and test ONVIF connectivity ────────────────────
  # Use unauthenticated GetSystemDateAndTime (no auth needed per ONVIF spec)
  # to fetch the camera's current time and detect clock skew.
  log "Testing ONVIF connectivity and fetching camera clock ..."
  DATE_RESP=$(curl -sk --max-time 10 -X POST \
    -H "Content-Type: application/soap+xml; charset=utf-8" \
    --data-binary '<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"
            xmlns:tds="http://www.onvif.org/ver10/device/wsdl">
  <s:Header/><s:Body><tds:GetSystemDateAndTime/></s:Body>
</s:Envelope>' \
    "https://${CAMERA_IP}/onvif/device_service" || true)

  # Parse camera UTC time from response
  CAM_HOUR=$(echo "$DATE_RESP" | grep -o '<tt:Hour>[^<]*' | sed 's/.*>//' | head -1)
  CAM_MIN=$(echo  "$DATE_RESP" | grep -o '<tt:Minute>[^<]*' | sed 's/.*>//' | head -1)
  CAM_SEC=$(echo  "$DATE_RESP" | grep -o '<tt:Second>[^<]*' | sed 's/.*>//' | head -1)
  CAM_YEAR=$(echo "$DATE_RESP" | grep -o '<tt:Year>[^<]*' | sed 's/.*>//' | head -1)
  CAM_MON=$(echo  "$DATE_RESP" | grep -o '<tt:Month>[^<]*' | sed 's/.*>//' | head -1)
  CAM_DAY=$(echo  "$DATE_RESP" | grep -o '<tt:Day>[^<]*' | sed 's/.*>//' | head -1)

  if [[ -n "$CAM_YEAR" ]]; then
    CAM_CREATED=$(printf '%04d-%02d-%02dT%02d:%02d:%02dZ' \
      "$CAM_YEAR" "$CAM_MON" "$CAM_DAY" "$CAM_HOUR" "$CAM_MIN" "$CAM_SEC")
    LOCAL_NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    log "Camera clock: ${CAM_CREATED}  Local clock: ${LOCAL_NOW}"
    ONVIF_AUTH_OK=true
  else
    log "WARN: Could not reach ONVIF endpoint or parse camera time. Response: ${DATE_RESP}"
    ONVIF_AUTH_OK=false
    CAM_CREATED=""
  fi

  # ── Step 2: upload cert via ONVIF LoadCertificateWithPrivateKey ─────────────
  CERT_UPLOADED=false
  if [[ "$ONVIF_AUTH_OK" == true ]]; then
    CERT_ID="letsencrypt-$(date +%Y%m%d)"
    # ONVIF tt:Data requires DER-encoded (binary) data, not PEM.
    # Convert: strip PEM headers by re-encoding through openssl to get raw DER, then base64.
    CERT_B64=$(openssl x509 -in "${CERT_DST}/server.crt" -outform DER | base64 -w0)
    KEY_B64=$(openssl rsa -in "${CERT_DST}/server.key" -outform DER 2>/dev/null | base64 -w0)

    OLD_CERT_IDS=$(onvif_soap "<tds:GetCertificates/>" "$CAM_CREATED" | \
      grep -o '<tt:CertificateID>[^<]*</tt:CertificateID>' | \
      sed 's|<[^>]*>||g' | grep "letsencrypt" || true)

    log "Uploading certificate via ONVIF (ID: ${CERT_ID}) ..."
    LOAD_RESP=$(onvif_soap "
      <tds:LoadCertificateWithPrivateKey>
        <tds:CertificateWithPrivateKey>
          <tt:CertificateID>${CERT_ID}</tt:CertificateID>
          <tt:Certificate><tt:Data>${CERT_B64}</tt:Data></tt:Certificate>
          <tt:PrivateKey><tt:Data>${KEY_B64}</tt:Data></tt:PrivateKey>
        </tds:CertificateWithPrivateKey>
      </tds:LoadCertificateWithPrivateKey>" "$CAM_CREATED")

    if echo "$LOAD_RESP" | grep -qi "fault\|NotAuthorized\|Unauthorized"; then
      log "WARN: ONVIF LoadCertificateWithPrivateKey failed: ${LOAD_RESP}"
    else
      log "Certificate uploaded via ONVIF."
      CERT_UPLOADED=true

      ACT_RESP=$(onvif_soap "
        <tds:SetCertificatesStatus>
          <tds:CertificateStatus>
            <tt:CertificateID>${CERT_ID}</tt:CertificateID>
            <tt:Status>true</tt:Status>
          </tds:CertificateStatus>
        </tds:SetCertificatesStatus>" "$CAM_CREATED")
      if echo "$ACT_RESP" | grep -qi "fault"; then
        log "WARN: SetCertificatesStatus failed: ${ACT_RESP}"
      else
        log "Certificate activated via ONVIF."
        # Axis cameras require a restart to begin serving the new server certificate.
        log "Restarting camera to apply new certificate ..."
        onvif_soap "<tds:SystemReboot/>" "$CAM_CREATED" > /dev/null || true
        log "Restart command sent — waiting 30 seconds for camera to come back up ..."
        sleep 30
      fi

      for old_id in $OLD_CERT_IDS; do
        [[ "$old_id" == "$CERT_ID" ]] && continue
        log "Removing old certificate: ${old_id}"
        onvif_soap "<tds:DeleteCertificates><tds:CertificateID>${old_id}</tds:CertificateID></tds:DeleteCertificates>" "$CAM_CREATED" > /dev/null || true
      done
    fi
  fi

  # ── Step 3: fallback — Axis VAPIX param.cgi PKCS12 upload ──────────────────
  # Older Axis firmware accepts a PKCS12 bundle via param.cgi.
  # This requires openssl to build the .p12 file.
  if [[ "$CERT_UPLOADED" == false ]]; then
    log "Falling back to VAPIX PKCS12 upload via param.cgi ..."

    P12_FILE=$(mktemp /tmp/axis_cert_XXXXXX.p12)
    trap 'rm -f "$P12_FILE"' EXIT

    if ! openssl pkcs12 -export \
        -in "${CERT_DST}/server.crt" \
        -inkey "${CERT_DST}/server.key" \
        -certfile "${CERT_DST}/chain.pem" \
        -passout pass: \
        -out "$P12_FILE" 2>/dev/null; then
      log "ERROR: Failed to create PKCS12 bundle."
      log "       Cert files are at ${CERT_DST} — upload manually via the camera web UI."
      exit 1
    fi

    P12_RESP=$(curl -sk --digest -u "${CAMERA_USER}:${CAMERA_PASS}" \
      --max-time 15 \
      -X POST \
      -F "primary_certificate=@${P12_FILE};type=application/x-pkcs12" \
      -F "primary_certificate_password=" \
      "https://${CAMERA_IP}/admin/SSL_Management.shtml" 2>&1)

    # Older firmware uses a different form path
    if echo "$P12_RESP" | grep -qi "404\|Not Found"; then
      P12_RESP=$(curl -sk --digest -u "${CAMERA_USER}:${CAMERA_PASS}" \
        --max-time 15 \
        -X POST \
        -F "cert=@${P12_FILE};type=application/x-pkcs12" \
        -F "certpass=" \
        "https://${CAMERA_IP}/admin/advanced.shtml" 2>&1)
    fi

    if echo "$P12_RESP" | grep -qi "401\|unauthorized"; then
      log "ERROR: HTTP Digest auth rejected. Check AXIS_CAMERA_USER/AXIS_CAMERA_PASS in /etc/loft_camera.env."
      log "       Cert files are at ${CERT_DST} — upload manually via the camera web UI"
      log "       (System Options → Security → Certificates → Server/Client)."
      exit 1
    fi
    if echo "$P12_RESP" | grep -qi "error\|fail"; then
      log "WARN: PKCS12 upload response suggests failure: ${P12_RESP}"
      log "      Cert files are at ${CERT_DST} — verify in camera web UI."
    else
      log "Certificate uploaded via PKCS12."
      log "Restarting camera to apply new certificate ..."
      curl -sk --digest -u "${CAMERA_USER}:${CAMERA_PASS}" \
        "https://${CAMERA_IP}/axis-cgi/restart.cgi" > /dev/null || true
      log "Restart command sent — waiting 30 seconds for camera to come back up ..."
      sleep 30
    fi
    CERT_UPLOADED=true
  fi
fi

# ── Show expiry of the new cert ───────────────────────────────
EXPIRY=$(openssl x509 -noout -enddate -in "${CERT_DST}/server.crt" | cut -d= -f2)
log "Certificate valid until: ${EXPIRY}"

# ── Verify cert is live at the public URL ─────────────────────
PUBLIC_PORT="${LOFT_PUBLIC_PORT:-90}"
PUBLIC_HOST="${LOFT_PUBLIC_HOST:-${DOMAIN}}"
log "Verifying certificate at ${PUBLIC_HOST}:${PUBLIC_PORT} ..."
LIVE_EXPIRY=$(echo | openssl s_client \
  -connect "${PUBLIC_HOST}:${PUBLIC_PORT}" \
  -servername "${DOMAIN}" \
  -verify_quiet 2>/dev/null \
  | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || true)

if [[ -z "$LIVE_EXPIRY" ]]; then
  log "WARN: Could not retrieve live certificate from ${PUBLIC_HOST}:${PUBLIC_PORT}."
  log "      Check that DNS resolves correctly and port ${PUBLIC_PORT} is forwarded to the camera."
else
  LOCAL_FP=$(openssl x509 -noout -fingerprint -sha256 -in "${CERT_DST}/server.crt" | cut -d= -f2)
  LIVE_FP=$(echo | openssl s_client \
    -connect "${PUBLIC_HOST}:${PUBLIC_PORT}" \
    -servername "${DOMAIN}" \
    -verify_quiet 2>/dev/null \
    | openssl x509 -noout -fingerprint -sha256 2>/dev/null | cut -d= -f2 || true)

  if [[ "$LOCAL_FP" == "$LIVE_FP" ]]; then
    log "Live certificate matches — renewal fully verified. Expires: ${LIVE_EXPIRY}"
  else
    # Check if live cert is expired
    LIVE_EXPIRY_EPOCH=$(date -d "$LIVE_EXPIRY" +%s 2>/dev/null || true)
    NOW_EPOCH=$(date +%s)
    if [[ -n "$LIVE_EXPIRY_EPOCH" && "$LIVE_EXPIRY_EPOCH" -lt "$NOW_EPOCH" ]]; then
      log "ERROR: Camera is still serving the OLD EXPIRED certificate (expired: ${LIVE_EXPIRY})."
      log "       The camera may need more time to restart, or the certificate activation failed."
      log "       Try manually rebooting the camera at https://${CAMERA_IP}/"
    else
      log "WARN: Live certificate fingerprint does not match the newly uploaded cert."
      log "      Live:  ${LIVE_FP:-<none>}  (expires ${LIVE_EXPIRY})"
      log "      Local: ${LOCAL_FP}"
      log "      The camera may still be restarting — check again in a minute."
    fi
  fi
fi

log "=== Renewal complete ==="
