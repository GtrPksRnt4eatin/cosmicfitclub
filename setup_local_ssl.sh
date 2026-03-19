#!/bin/bash

# Create the SSL directory if it doesn't exist
mkdir -p shared/.ssl

# Generate self-signed certificate
echo "Generating self-signed SSL certificate..."
openssl req -x509 -newkey rsa:4096 -keyout shared/.ssl/server.key -out shared/.ssl/server.crt -days 365 -nodes -subj "/C=US/ST=NY/L=New York/O=Cosmic Fit Club/CN=localhost"

echo "SSL certificates created in shared/.ssl/"
echo "You can now run: ./local_ssh"
echo ""
echo "Note: Your browser will warn about the self-signed certificate."
echo "Just click 'Advanced' and 'Proceed to localhost' to continue."
