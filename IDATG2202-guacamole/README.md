# IDATG2202-guacamole
**WORK IN PROGRESS**

This contains a template for building N amount of sysbox servers that's supposed to be accessible from Guacamole. As of now, these servers will create a user "guacamole" with a public-key from an SSH keypair you intend to use in the Guacamole connection. This user will run a docker command upon SSH login, an be "trapped" inside that container. Per now, it's using the ubuntu:22.04 container. You probably want to change that. The docker-command is given in `lib/sysbox-cloud-config.txt`

If you run this stack and the guacamole infrastructure in different Openstack projects, you may/must change some of the default parameters, since the template in its current form assumes that everything runs in the same project, and the VMs connects to an existing Neutron network. The parameters you potentially have to override is:

 - network       (set it to an existing network in your project)
 - subnet        (set it to an existing subnet in your project)
 - subnet\_prefix (set it to whatever is correct for you given subnet)
 - lb\_vip       (set it to a valid address in your subnet, outside of the DHCP scope)

## Howto fire this up
Set the parameters you need in `params.yaml` and run `openstack stack create -e params.yaml -t sysbox-servers-with-lb.yaml <stack_name>`. The SSH public-key you need in `guacamole_ssh_key` should be from the keypair you want Guacamole log into your sysbox-servers with. This keypair can be generated whereever you like.

## A scenario were you would like to use Guacamole in a digital exam
Lets say that you have created several Linux Servers running sysbox, available through a Load Balancer, configured in such a way that when you log in via SSH as the user "guacamole", you will be trapped in a specially crafted container on logon. In an exam situation, you don't want the potential risk of students forgetting their NTNU credentials, so you've decided that everyone can login to Guacamole with the same username and password. This is perfectly fine for the described scenario. This may or may not happen in the IDATG2202 course ;-)

To achieve this, all you have to do is:
### Create the connection
  - Log in to guacamole with a user that's allowed to create users and connections
  - Go to Settings -> Connections and click New Connection
  - Give the following settings (everything else blank or default):
    - EDIT CONNECTION: Give the connection a descriptive name, and select ROOT as location (or something else that's fitting, if you have a hierarchy), SSH as protocol
    - PARAMETERS:
      - Network:
        - `Hostname`: The floating IP of your LoadBalancer
        - `Port`: 22
      - Authentication:
        - `Username`: guacamole
        - `Private key`: \<The private key from the SSH-keypair you want guacamole to login with\>
      - Session / Environment:
        - `Server keepalive interval`: 10
  - Click save

### Create the common user
(Assuming you are still logged in with the user from the last section, and ar looking at the settings menu):
  - Go to Users and click New User
  - Enter the common username and password you want to give to the students
  - Don't bother putting any name or email address
  - (If you think it's useful, set some time limits on the account)
  - Give the user permission to use the connection you created in the last step
  - Click save
