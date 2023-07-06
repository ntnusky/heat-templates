# IDATG2202-guacamole
**WORK IN PROGRESS**

This contains a template for building N amount of sysbox servers that's supposed to be accessible from Guacamole. As of now, these servers will create a user "guacamole" with a public-key from an SSH keypair you intend to use in the Guacamole connection. This user will run a docker command upon SSH login, an be "trapped" inside that container.
