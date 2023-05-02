# demo-azure-network-1
Demo of creating client-router-server network in Azure

## Getting Started

List locations, images and sizes:
```
az account list-locations -o table
az vm image list -f ubuntu -o table
```

Edit the script and set the following variables to selected values from above:
- LOCATION: location, e.g. australiacentral
- IMAGE: VM image, e.g. UbuntuLTS
- VM_SIZE: size of VM, e.g. Standard
