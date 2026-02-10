#!/bin/bash
set -e

echo "Docker Entrypoint configurations..."
echo ""

# Validate required environment variables
if [ -z "${USER}" ] || [ -z "${GROUP}" ]; then
    echo "ERROR: USER and GROUP environment variables must be set"
    exit 1
fi

# Update Supervisord configuration
echo "Configuring Supervisord..."
if [ -f /etc/supervisor/supervisord.conf ]; then
    # Update chown in [unix_http_server] section
    sed -i "s/^chown=.*/chown=${USER}:${GROUP}/" /etc/supervisor/supervisord.conf

    # Update user in [supervisord] section
    sed -i "s/^user=.*/user=${USER}/" /etc/supervisor/supervisord.conf

    echo "✓ Supervisord configured for ${USER}:${GROUP}"
else
    echo "WARNING: /etc/supervisor/supervisord.conf not found"
fi

# Update program-specific configurations if neccesary
#if [ -f /etc/supervisor/conf.d/programs.conf ]; then
#    sed -i "s/^user=.*/user=${USER}/" /etc/supervisor/conf.d/programs.conf
#    echo "✓ Supervisor programs configured for user ${USER}"
#fi

# Fix ownership of supervisor directories
echo "Setting Supervisord permissions..."
mkdir -p /var/log/supervisor /run
chown -R ${USER}:${GROUP} /var/log/supervisor 2>/dev/null || true
chown ${USER}:${GROUP} /run/supervisord.sock 2>/dev/null || true

# Execute the main command
echo ""
echo "Extra configurations completed. Starting services..."
exec "$@"
