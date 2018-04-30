# Terraform
## Preparation
First you need to download and install Terraform for your OS from the following link.
[Download Terraform](https://www.terraform.io/downloads.html)

Open the following link and follow the instructions to create a service principal for Azure.
[Creating an Azure service principal](https://www.terraform.io/docs/providers/azurerm/authenticating_via_service_principal.html)

Create a file in this directory with a .tf extension and add your Azure credentials in the following format.
```
provider "azurerm" {
  subscription_id = ""
  client_id       = ""
  client_secret   = ""
  tenant_id       = ""
}
```
Create a file with the suffix .auto.tfvars and add your Qlik Sense license details in the following format.
```
"qlikSenseSerial" = ""
"qlikSenseControl" = ""
"qlikSenseOrganization" = ""
"qlikSenseName" = ""
```
Run the following command to initialise the project for use with Terraform.
```sh
terraform init
```
## Deploying
Open a terminal and change to this directory, then run the following command.
```sh
terraform apply
```
Terraform will display a list of additions and changes that will be made for the deployment, when prompted to continue type yes and press enter.
