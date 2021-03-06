#!/usr/bin/env sh

TRAEFIK_HTTP_COMPRESSION=${TRAEFIK_HTTP_COMPRESSION:-"true"}
TRAEFIK_HTTPS_COMPRESSION=${TRAEFIK_HTTPS_COMPRESSION:-"true"}
TRAEFIK_HTTP_PORT=${TRAEFIK_HTTP_PORT:-"8080"}
TRAEFIK_HTTPS_ENABLE=${TRAEFIK_HTTPS_ENABLE:-"false"}
TRAEFIK_HTTPS_PORT=${TRAEFIK_HTTPS_PORT:-"8443"}
TRAEFIK_ADMIN_ENABLE=${TRAEFIK_ADMIN_ENABLE:-"false"}
TRAEFIK_ADMIN_PORT=${TRAEFIK_ADMIN_PORT:-"8000"}
TRAEFIK_CONSTRAINTS=${TRAEFIK_CONSTRAINTS:-""}
TRAEFIK_DEBUG=${TRAEFIK_DEBUG:="false"}
TRAEFIK_INSECURE_SKIP=${TRAEFIK_INSECURE_SKIP:="false"}
TRAEFIK_LOG_LEVEL=${TRAEFIK_LOG_LEVEL:-"INFO"}
TRAEFIK_LOG_FILE=${TRAEFIK_LOG_FILE:-"${SERVICE_HOME}/log/traefik.log"}
TRAEFIK_ACCESS_FILE=${TRAEFIK_ACCESS_FILE:-"${SERVICE_HOME}/log/access.log"}
TRAEFIK_ADMIN_READ_ONLY=${TRAEFIK_ADMIN_READ_ONLY:="false"}
TRAEFIK_ADMIN_STATISTICS=${TRAEFIK_ADMIN_STATISTICS:-10}
TRAEFIK_ADMIN_AUTH_METHOD=${TRAEFIK_ADMIN_AUTH_METHOD:-"basic"}
TRAEFIK_ADMIN_AUTH_USERS=${TRAEFIK_ADMIN_AUTH_USERS:-""}
TRAEFIK_SSL_PATH=${TRAEFIK_SSL_PATH:-"${SERVICE_HOME}/certs"}
TRAEFIK_ACME_ENABLE=${TRAEFIK_ACME_ENABLE:-"false"}
TRAEFIK_ACME_EMAIL=${TRAEFIK_ACME_EMAIL:-"test@traefik.io"}
TRAEFIK_ACME_ONDEMAND=${TRAEFIK_ACME_ONDEMAND:-"true"}
TRAEFIK_ACME_ONHOSTRULE=${TRAEFIK_ACME_ONHOSTRULE:-"true"}
TRAEFIK_ACME_CASERVER=${TRAEFIK_ACME_CASERVER:-"https://acme-v01.api.letsencrypt.org/directory"}
TRAEFIK_K8S_ENABLE=${TRAEFIK_K8S_ENABLE:-"false"}
TRAEFIK_K8S_OPTS=${TRAEFIK_K8S_OPTS:-""}
TRAEFIK_PROMETHEUS_ENABLE=${TRAEFIK_PROMETHEUS_ENABLE:-"false"}
TRAEFIK_PROMETHEUS_OPTS=${TRAEFIK_PROMETHEUS_OPTS:-""}
TRAEFIK_PROMETHEUS_BUCKETS=${TRAEFIK_PROMETHEUS_BUCKETS:-"[0.1,0.3,1.2,5.0]"}
TRAEFIK_RANCHER_ENABLE=${TRAEFIK_RANCHER_ENABLE:-"false"}
TRAEFIK_RANCHER_REFRESH=${TRAEFIK_RANCHER_REFRESH:-15}
TRAEFIK_RANCHER_MODE=${TRAEFIK_RANCHER_MODE:-"api"}
TRAEFIK_RANCHER_DOMAIN=${TRAEFIK_RANCHER_DOMAIN:-"rancher.internal"}
TRAEFIK_RANCHER_EXPOSED=${TRAEFIK_RANCHER_EXPOSED:-"false"}
TRAEFIK_RANCHER_HEALTHCHECK=${TRAEFIK_RANCHER_HEALTHCHECK:-"false"}
TRAEFIK_RANCHER_INTERVALPOLL=${TRAEFIK_RANCHER_INTERVALPOLL:-"false"}
TRAEFIK_RANCHER_OPTS=${TRAEFIK_RANCHER_OPTS:-""}
TRAEFIK_RANCHER_PREFIX=${TRAEFIK_RANCHER_PREFIX:-"/2016-07-29"}
TRAEFIK_FILE_NAME=${TRAEFIK_FILE_NAME:-"${SERVICE_HOME}/etc/rules.toml"}
TRAEFIK_FILE_ENABLE=${TRAEFIK_FILE_ENABLE:="true"}
TRAEFIK_FILE_OPTS=${TRAEFIK_FILE_OPTS:-""}
TRAEFIK_WEB=${TRAEFIK_WEB:-""}
CATTLE_URL=${CATTLE_URL:-""}
CATTLE_ACCESS_KEY=${CATTLE_ACCESS_KEY:-""}
CATTLE_SECRET_KEY=${CATTLE_SECRET_KEY:-""}

TRAEFIK_ENTRYPOINTS_HTTP="\
  [entryPoints.http]
  address = \":${TRAEFIK_HTTP_PORT}\"
  compress = ${TRAEFIK_HTTP_COMPRESSION}
"

filelist=`ls -1 ${TRAEFIK_SSL_PATH}/*.key | rev | cut -d"." -f2- | rev`
RC=`echo $?`

if [ $RC -eq 0 ]; then
    TRAEFIK_ENTRYPOINTS_HTTPS="\
  [entryPoints.https]
  address = \":${TRAEFIK_HTTPS_PORT}\"
  compress = ${TRAEFIK_HTTPS_COMPRESSION}
    [entryPoints.https.tls]"
    for i in $filelist; do
        if [ -f "$i.crt" ]; then
            TRAEFIK_ENTRYPOINTS_HTTPS=$TRAEFIK_ENTRYPOINTS_HTTPS"
      [[entryPoints.https.tls.certificates]]
      certFile = \"${i}.crt\"
      keyFile = \"${i}.key\"
"
        fi
    done
fi

if [ "X${TRAEFIK_HTTPS_ENABLE}" == "Xtrue" ]; then
    TRAEFIK_ENTRYPOINTS_OPTS=${TRAEFIK_ENTRYPOINTS_HTTP}${TRAEFIK_ENTRYPOINTS_HTTPS}
    TRAEFIK_ENTRYPOINTS='"http", "https"'
elif [ "X${TRAEFIK_HTTPS_ENABLE}" == "Xonly" ]; then
    TRAEFIK_ENTRYPOINTS_HTTP=$TRAEFIK_ENTRYPOINTS_HTTP"\
    [entryPoints.http.redirect]
       entryPoint = \"https\"
"
    TRAEFIK_ENTRYPOINTS_OPTS=${TRAEFIK_ENTRYPOINTS_HTTP}${TRAEFIK_ENTRYPOINTS_HTTPS}
    TRAEFIK_ENTRYPOINTS='"http", "https"'
else
    TRAEFIK_ENTRYPOINTS_OPTS=${TRAEFIK_ENTRYPOINTS_HTTP}
    TRAEFIK_ENTRYPOINTS='"http"'
fi

if [ "X${TRAEFIK_K8S_ENABLE}" == "Xtrue" ]; then
    TRAEFIK_K8S_OPTS="[kubernetes]"
fi

TRAEFIK_ACME_CFG=""
if [ "X${TRAEFIK_HTTPS_ENABLE}" == "Xtrue" ] || [ "X${TRAEFIK_HTTPS_ENABLE}" == "Xonly" ] && [ "X${TRAEFIK_ACME_ENABLE}" == "Xtrue" ]; then

    TRAEFIK_ACME_CFG="\
[acme]
email = \"${TRAEFIK_ACME_EMAIL}\"
storage = \"${SERVICE_HOME}/acme/acme.json\"
onDemand = ${TRAEFIK_ACME_ONDEMAND}
OnHostRule = ${TRAEFIK_ACME_ONHOSTRULE}
caServer = \"${TRAEFIK_ACME_CASERVER}\"
entryPoint = \"https\"

"

fi

if [ "X${TRAEFIK_RANCHER_ENABLE}" == "Xtrue" ]; then
    TRAEFIK_RANCHER_OPTS="\
[rancher]
domain = \"${TRAEFIK_RANCHER_DOMAIN}\"
Watch = true
RefreshSeconds = ${TRAEFIK_RANCHER_REFRESH}
ExposedByDefault = ${TRAEFIK_RANCHER_EXPOSED}
EnableServiceHealthFilter = ${TRAEFIK_RANCHER_HEALTHCHECK}
"
    if [ "X${TRAEFIK_CONSTRAINTS}" != "X" ]; then
        TRAEFIK_RANCHER_OPTS=${TRAEFIK_RANCHER_OPTS}"\
constraints = [ ${TRAEFIK_CONSTRAINTS} ]
"
    fi

    if [ "${TRAEFIK_RANCHER_MODE}" == "api" ]; then
        TRAEFIK_RANCHER_OPTS=${TRAEFIK_RANCHER_OPTS}"
[rancher.api]
Endpoint = \"${CATTLE_URL}\"
AccessKey = \"${CATTLE_ACCESS_KEY}\"
SecretKey = \"${CATTLE_SECRET_KEY}\"
"
    elif [ "${TRAEFIK_RANCHER_MODE}" == "metadata" ]; then
        TRAEFIK_RANCHER_OPTS=${TRAEFIK_RANCHER_OPTS}"
[rancher.metadata]
IntervalPoll = ${TRAEFIK_RANCHER_INTERVALPOLL}
Prefix = \"${TRAEFIK_RANCHER_PREFIX}\"
"
    fi
fi

if [ "X${TRAEFIK_ADMIN_ENABLE}" == "Xtrue" ] || [ "X${TRAEFIK_PROMETHEUS_ENABLE}" == "Xtrue" ]; then
    TRAEFIK_WEB="\
[web]"
fi

if [ "X${TRAEFIK_ADMIN_ENABLE}" == "Xtrue" ]; then
    TRAEFIK_ADMIN_CFG="\
address = \":${TRAEFIK_ADMIN_PORT}\"
ReadOnly = ${TRAEFIK_ADMIN_READ_ONLY}
[web.statistics]
RecentErrors = ${TRAEFIK_ADMIN_STATISTICS}
"

    if [ "${TRAEFIK_ADMIN_AUTH_USERS}" != "" ]; then
        echo ${TRAEFIK_ADMIN_AUTH_USERS} > "${SERVICE_HOME}/.htpasswd"
        TRAEFIK_ADMIN_CFG=${TRAEFIK_ADMIN_CFG}"
[web.auth.${TRAEFIK_ADMIN_AUTH_METHOD}]
usersFile = \"${SERVICE_HOME}/.htpasswd\"
"
    fi
fi

if [ "X${TRAEFIK_PROMETHEUS_ENABLE}" == "Xtrue" ]; then
    TRAEFIK_PROMETHEUS_OPTS="\
[web.metrics.prometheus]
buckets=${TRAEFIK_PROMETHEUS_BUCKETS}
"
fi

if [ "X${TRAEFIK_FILE_ENABLE}" == "Xtrue" ]; then
    TRAEFIK_FILE_OPTS="\
[file]
filename = \"${TRAEFIK_FILE_NAME}\"
watch = true
"
fi

cat << EOF > ${SERVICE_HOME}/etc/traefik.toml
# traefik.toml
debug = ${TRAEFIK_DEBUG}
logLevel = "${TRAEFIK_LOG_LEVEL}"
traefikLogsFile = "${TRAEFIK_LOG_FILE}"
accessLogsFile = "${TRAEFIK_ACCESS_FILE}"
InsecureSkipVerify = ${TRAEFIK_INSECURE_SKIP}
defaultEntryPoints = [${TRAEFIK_ENTRYPOINTS}]

[entryPoints]
${TRAEFIK_ENTRYPOINTS_OPTS}
${TRAEFIK_WEB}
${TRAEFIK_ADMIN_CFG}
${TRAEFIK_PROMETHEUS_OPTS}
${TRAEFIK_RANCHER_OPTS}
${TRAEFIK_FILE_OPTS}
${TRAEFIK_ACME_CFG}
${TRAEFIK_K8S_OPTS}
EOF
