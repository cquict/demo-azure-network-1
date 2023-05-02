#!/bin/bash
# Create a client-router-server network in Azure

RG="crs-rg"
VNET_NAME="crs-vnet"
NSG_NAME="crs-nsg"
VM_SIZE="Standard_B1s"
ADMIN_USER="network"
LOCATION="southeastasia"
IMAGE="Ubuntu"

# Create a resource group
az group create --name $RG --location $LOCATION

# Create public IPs
az network public-ip create --resource-group $RG --location $LOCATION --name node1_ip
az network public-ip create --resource-group $RG --location $LOCATION --name node2_ip
az network public-ip create --resource-group $RG --location $LOCATION --name node3_ip

# Create networks
az network vnet create --resource-group $RG --vnet-name $VNET_NAME \
  --address-prefix 192.168.0.0/16 --subnet-name neta --subnet-prefix 192.168.1.0/24
  
az network vnet create --resource-group $RG --vnet-name $VNET_NAME \
  --subnet-name netb --subnet-prefix 192.168.2.0/24

# Ceate NSG and rules
az network nsg create --resource-group $RG --name $NSG_NAME

az network nsg rule create --resource-group $RG --nsg-name $NSG_NAME \
  --name default-allow-ssh --protocol tcp --priority 1000 --destination-port-range 22

# Create NICs
az network nic create --resource-group $RG --vnet-name $VNET_NAME --network-security-group $NSG_NAME \
  --name node1nic1 --subnet neta --private-ip-address 192.168.1.11 --public-ip-address node1ip

az network nic create --resource-group $RG --vnet-name $VNET_NAME --network-security-group $NSG_NAME \
  --name node2nic1 --subnet neta --private-ip-address 192.168.1.10 --public-ip-address node2ip

az network nic create --resource-group $RG --vnet-name $VNET_NAME --network-security-group $NSG_NAME \
  --name node2nic2 --subnet netb --private-ip-address 192.168.1.20 

az network nic create --resource-group $RG --vnet-name $VNET_NAME --network-security-group $NSG_NAME \
  --name node3nic1 --subnet netb --private-ip-address 192.168.1.21 --public-ip-address node3ip
  
# Create VMs
az vm create --resource-group $RG --image $IMAGE --admin-username $ADMIN_USER --size $VM_SIZE --generate-ssh-keys \
  --name node1 --nics node1nic1

az vm create --resource-group $RG --image $IMAGE --admin-username $ADMIN_USER --size $VM_SIZE --generate-ssh-keys \
  --name node2 --nics node2nic1 node2nic2

az vm create --resource-group $RG --image $IMAGE --admin-username $ADMIN_USER --size $VM_SIZE --generate-ssh-keys \
  --name node3 --nics node3nic1

# Create routing tables
az network route-table create --resource-group $RG --name neta-rt
az network route-table create --resource-group $RG --name netb-rt

# Add routes to routing tables
az network route-table route create --resource-group $RG --route-table-name neta-rt \
  --name route2netb --address-prefix 192.168.2.0/24 --next-hop-type VirtualAppliance --next-hop-ip-address 192.168.1.10
az network route-table route create --resource-group $RG --route-table-name neta-rt \
  --name route2neta --address-prefix 192.168.1.0/24 --next-hop-type VirtualAppliance --next-hop-ip-address 192.168.2.20
  
# Update subnets
az network vnet subnet update --resource-group $RG --vnet-name $VNET_NAME \
  --name neta --route-table neta-rt
az network vnet subnet update --resource-group $RG --vnet-name $VNET_NAME \
  --name netb --route-table netb-rt

# Enable forwarding
az network nic update --resource-group $RG -name node2nic1 --ip-forwarding true
az network nic update --resource-group $RG -name node2nic2 --ip-forwarding true
  
