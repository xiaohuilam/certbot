#!/bin/bash
# Generate the hooks/post-refresh file for all DNS plugins
set -eu

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CERTBOT_DIR="$(dirname "${DIR}")"

for PLUGIN_PATH in "${CERTBOT_DIR}"/certbot-dns-*; do
  PLUGIN=$(basename "${PLUGIN_PATH}")
  mkdir -p "${PLUGIN_PATH}/snap/hooks"
  cat <<EOF > "${PLUGIN_PATH}/snap/hooks/post-refresh"
#!/bin/sh -e
# This file is generated by tools/generate_dnsplugins_postrefreshhook.sh and should not be edited manually.

# get certbot version
if [ ! -f "\$SNAP/certbot-shared/certbot-version.txt" ]; then
  echo "No certbot version available; not doing version comparison check" >> "\$SNAP_DATA/debuglog"
  exit 0
fi
cb_installed=\$(cat \$SNAP/certbot-shared/certbot-version.txt)

# get required certbot version for plugin. certbot version must be at least the plugin's
# version. note that this is not the required version in setup.py, but the version number itself.
cb_required=\$(grep -oP "version = '\K.*(?=')" \$SNAP/setup.py)


\$SNAP/bin/python3 -c "import sys; from packaging import version; sys.exit(1) if\
  version.parse('\$cb_installed') < version.parse('\$cb_required') else sys.exit(0)" || exit_code=\$?
if [ "\$exit_code" -eq 1 ]; then
  echo "Certbot is version \$cb_installed but needs to be at least \$cb_required before" \\
    "this plugin can be updated; will try again on next refresh."
  exit 1
fi
EOF
done
