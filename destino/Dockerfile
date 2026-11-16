# Destino de despliegue del laboratorio (Semana 14).
# Una máquina con SSH y Node: recibe paquetes de app por SSH y los sirve por HTTP.
FROM node:22.23.3-alpine3.24

# sshd solo con clave, solo para deploy. La contraseña bloqueada (!) impide
# también la clave en Alpine; '*' deja la cuenta sin contraseña pero usable.
RUN apk add --no-cache openssh-server \
 && adduser -D -s /bin/sh deploy \
 && sed -i 's/^deploy:!/deploy:*/' /etc/shadow \
 && mkdir -p /srv/entornos /home/deploy/.ssh \
 && chown deploy:deploy /srv/entornos /home/deploy/.ssh \
 && chmod 700 /home/deploy/.ssh \
 && printf '%s\n' 'PasswordAuthentication no' 'KbdInteractiveAuthentication no' \
      'PermitRootLogin no' 'AllowUsers deploy' 'HostKey /etc/ssh/claves/ssh_host_ed25519_key' \
      > /etc/ssh/sshd_config.d/destino.conf

COPY desplegar.sh /usr/local/bin/desplegar
COPY servidor.mjs /opt/destino/servidor.mjs
COPY arranque.sh /usr/local/bin/arranque

EXPOSE 22 8080
ENTRYPOINT ["/usr/local/bin/arranque"]
