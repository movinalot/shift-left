# Shift Left with Fortinet

## FortiDevSec and FortiDAST

## FortiGate Automation Stitch with Azure Runbook

1. Run terraform in the terraform/azure directory

- Deploys a single FortiGate and a 2 Linux VMs.

  - Linux VM ___vm-linux-1___ is tagged ComputeType=unknown
  - Linux VM ___vm-linux-2___ is tagged ComputeType=WebServer

- Deploys an Azure Automation Account and Runbook to update the route table rt-protected

1. Run terraform in the terraform/fortios directory

- Creates FortiGate Dynamic Addresses

  - AppServers - ComputeType=AppServers
  - DbServers - ComputeType=DbServers
  - WebServers - ComputeType=WebServers

- Creates an Azure SDN Connector with Reader access to the Resource Group where the FortiGate is deployed

- Creates an Automation Stitch that is triggered on the VMs with tag ComputeType=WebServer

The Azure SDN Connector retrieved values may trigger the Automation Stitch to send a webhook to Azure Automation to execute the Runbook and the route ___rt-protected___ with a host route.

1. Change the value of the ComputeType tag on Linux VM ___vm-linux-1___ to AppServer, WebServer, or DbServer. In 2-3 minutes a host route will be added to the route table rt-protected, ensuring that all traffic to the VM will traverse the FortiGate.
