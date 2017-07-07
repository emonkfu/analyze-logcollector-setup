#!/bin/bash
#
# reset postgresql db to import new RHV sosreport
#
# 2017-07-07	Jason Woods <jwoods@redhat.com>

echo "#### package installer, dnf if found, default to yum"
if [ "$(type dnf)" = "dnf is /usr/bin/dnf" ] ; then
  PKG_INST="dnf"
else
  echo "#### likely RHEL, it will need optional-rpms"
  subscription-manager repos --enable=rhel-7-server-optional-rpms
  PKG_INST="yum"
fi

echo "#### install RPMs on system, if needed"
"${PKG_INST}" -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RPMS=""
for RPM in postgresql-server rubygem-asciidoctor csv git
do
  rpm -q "${RPM}" || RPMS="${RPMS} ${RPM}"
done
[ -n "${RPMS}" ] && "${PKG_INST}" -y install ${RPMS}

echo "#### git ovirt-log-collector report generator"
PROG="/tmp/postgres.git.clone.sh"
cat << EOF > "${PROG}"
cd /tmp
git clone http://gerrit.ovirt.org/p/ovirt-log-collector
EOF
chmod +x "${PROG}"
su - postgres -c "${PROG}"

echo "#### Start Postgresql on clean DB"
systemctl stop postgresql
sleep 1
postgresql-setup initdb
systemctl enable postgresql
systemctl start postgresql

echo "#### chose latest sosreport-LogCollector*.tar.xz file in /tmp"
FILE_LC="$(ls -t /tmp/sosreport-LogCollector*.tar.xz | head -n1)"
chown postgres: "${FILE_LC}"

if [ -n "${FILE_LC}" ] ; then
  echo "#### process most current log-collector report uploaded"
  PROG="/tmp/postgres.process.lc.sh"
  cat << EOF > "${PROG}"
cd /tmp
ovirt-log-collector/src/inventory_report/ovirt-log-collector-analyzer.sh --keep-working-dir "${FILE_LC}"
  EOF
  chmod +x "${PROG}"
  su - postgres -c "${PROG}"
else
  echo "#### no log-collector files found in /tmp"
fi

