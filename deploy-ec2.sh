#!/usr/bin/env bash
set -Eeuo pipefail

SERVICE_NAME="java-devops-demo"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
APP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_USER="$(id -un)"
PORT="${PORT:-8080}"
APP_MESSAGE="${APP_MESSAGE:-Hello from my EC2 server!}"

fail() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

if [[ "${EUID}" -eq 0 ]]; then
    fail "Run this script as the normal EC2 user (for example, ubuntu), not with sudo."
fi

if [[ ! -f /etc/os-release ]]; then
    fail "Cannot identify this operating system. This script requires Ubuntu."
fi

# shellcheck disable=SC1091
source /etc/os-release
[[ "${ID:-}" == "ubuntu" ]] || fail "This script currently supports Ubuntu only."

[[ -f "${APP_DIR}/pom.xml" ]] || fail "pom.xml was not found. Run this script from the cloned project."
[[ "${PORT}" =~ ^[0-9]{1,5}$ ]] || fail "PORT must be a number from 1 to 65535."
PORT_NUMBER=$((10#${PORT}))
(( PORT_NUMBER >= 1 && PORT_NUMBER <= 65535 )) || fail "PORT must be a number from 1 to 65535."
[[ "${APP_MESSAGE}" != *$'\n'* && "${APP_MESSAGE}" != *$'\r'* ]] || fail "APP_MESSAGE cannot contain newline characters."

command -v sudo >/dev/null 2>&1 || fail "sudo is required to install packages and configure the service."
sudo -v

JAVA_MAJOR=""
if command -v java >/dev/null 2>&1; then
    JAVA_MAJOR="$(java -version 2>&1 | sed -n '1s/.*version "\([0-9]*\).*/\1/p')"
fi

if ! command -v git >/dev/null 2>&1 \
    || [[ ! "${JAVA_MAJOR}" =~ ^[0-9]+$ ]] \
    || (( JAVA_MAJOR < 17 )) \
    || ! command -v mvn >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y git openjdk-17-jdk maven
fi

JAVA_MAJOR="$(java -version 2>&1 | sed -n '1s/.*version "\([0-9]*\).*/\1/p')"
[[ "${JAVA_MAJOR}" =~ ^[0-9]+$ ]] || fail "Could not determine the installed Java version."
(( JAVA_MAJOR >= 17 )) || fail "Java 17 or newer is required."

java -version
mvn -version

printf 'Building the application in %s...\n' "${APP_DIR}"
mvn --batch-mode --no-transfer-progress clean package

[[ -f "${APP_DIR}/target/java-devops-demo.jar" ]] || fail "Build completed without producing the expected JAR."

ESCAPED_APP_MESSAGE="${APP_MESSAGE//\\/\\\\}"
ESCAPED_APP_MESSAGE="${ESCAPED_APP_MESSAGE//\"/\\\"}"

sudo tee "${SERVICE_FILE}" >/dev/null <<EOF
[Unit]
Description=Java DevOps Demo
After=network.target

[Service]
User=${APP_USER}
WorkingDirectory="${APP_DIR}"
Environment=PORT=${PORT_NUMBER}
Environment="APP_MESSAGE=${ESCAPED_APP_MESSAGE}"
ExecStart=/usr/bin/java -jar "${APP_DIR}/target/java-devops-demo.jar"
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}"
if sudo systemctl is-active --quiet "${SERVICE_NAME}"; then
    sudo systemctl restart "${SERVICE_NAME}"
else
    sudo systemctl start "${SERVICE_NAME}"
fi
sudo systemctl is-active "${SERVICE_NAME}"

printf '\nDeployment completed.\n'
printf 'Open: http://EC2_PUBLIC_IP:%s/\n' "${PORT_NUMBER}"
printf 'Health check: curl http://localhost:%s/health\n' "${PORT_NUMBER}"
printf 'Logs: sudo journalctl -u %s -n 100 --no-pager\n' "${SERVICE_NAME}"
