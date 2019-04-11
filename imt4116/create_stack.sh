#!/bin/bash
openstack stack create --wait -e params.yaml -t imt4116_top.yaml imt4116
