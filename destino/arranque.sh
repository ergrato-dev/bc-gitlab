#!/bin/sh
# La clave de host vive en un volumen: sobrevive a reconstruir la imagen, así que
# la huella que guardaste en DESTINO_KNOWN_HOSTS sigue valiendo.
set -eu
mkdir -p /etc/ssh/claves
[ -f /etc/ssh/claves/ssh_host_ed25519_key ] \
  || ssh-keygen -q -t ed25519 -N '' -f /etc/ssh/claves/ssh_host_ed25519_key
touch /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy/.ssh /srv/entornos
chmod 600 /home/deploy/.ssh/authorized_keys
/usr/sbin/sshd -e
exec su deploy -s /bin/sh -c 'exec node --experimental-strip-types /opt/destino/servidor.mjs'
