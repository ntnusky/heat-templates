# Guacamole
Building a simple guacamole setup with a reverse proxy, the guacamole software and a database. This particular setup will require the following things on beforehand:
  - A domain name that you will use for the web portal
  - A valid, trusted TLS certificate for the name above, with its key and CA cert chain
  - All the details you need in order to configure LDAPS auth

Fill in values in `params.yaml` and run `openstack stack create -e params.yaml -t guacamole.yaml <stack_name>` to fire it up.

You have now ended up with a blank install of Apache Guacamole. Default credentials are guacadmin/guacadmin. These should obviously be changed on first login. To promote an LDAP user to an admin, create a local user with the same username, set a dummy password, and give it the admin role. Guacamole is configured to prefer LDAP as its auth source, so it will accept the given user's LDAP password on logon.
