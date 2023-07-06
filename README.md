# heat-templates
A collection of various heat templates

## IMT4116
Requires images for Remnux and the pre-built Windows Image present in glance

Contains a remnux machine, a windows machine on an isolated network, and a fileserver jump-host which is used to transfer files into the isolated network. The windows machine will be configured with REMnux as default gateway and DNS.

The fileserver will always be available within the isolated network at `192.168.10.100`

To get started, fill inn values in `params.yaml` and run the `create_stack.sh` script

## Guacamole
Building a simple guacamole setup with a reverse proxy, the guacamole software and a database. This particular setup will require the following things on beforehand:
  - A domain name that you will use for the web portal
  - A valid, trusted TLS certificate for the name above, with its key and CA cert chain
  - All the details you need in order to configure LDAPS auth

Fill in values in `params.yaml` and run `openstack stack create -e params.yaml -t guacamole.yaml <stack_name>` to fire it up.

You have now ended up with a blank install of Apache Guacamole. Default credentials are guacadmin/guacadmin. These should obviously be changed on first login. To promote an LDAP user to an admin, create a local user with the same username, set a dummy password, and give it the admin role. Guacamole is configured to prefer LDAP as its auth source, so it will accept the given user's LDAP password on logon.
### IDATG2202-guacamole
**WORK IN PROGRESS**

This contains a template for building N amount of sysbox servers that's supposed to be accessible from Guacamole. As of now, these servers will create a user "guacamole" with a public-key from an SSH keypair you intend to use in the Guacamole connection. This user will run a docker command upon SSH login, an be "trapped" inside that container.
