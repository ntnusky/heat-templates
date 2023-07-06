# IMT4116
Requires images for Remnux and the pre-built Windows Image present in glance

Contains a remnux machine, a windows machine on an isolated network, and a fileserver jump-host which is used to transfer files into the isolated network. The windows machine will be configured with REMnux as default gateway and DNS.

The fileserver will always be available within the isolated network at `192.168.10.100`

To get started, fill inn values in `params.yaml` and run the `create_stack.sh` script
