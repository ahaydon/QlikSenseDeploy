variable "virtualMachineName" {
  default = "qlik-sense"
}
variable "adminUsername" {}
variable "adminPassword" {}
variable "dnsLabelPrefix" {}
variable "qlikSenseVersion" {
  default = "Qlik Sense November 2017"
}
variable "qlikSenseServiceAccount" {
  default = "qService"
}
variable "qlikSenseServiceAccountPassword" {}
variable "qlikSenseRepositoryPassword" {}
variable "qlikSenseSerial" {}
variable "qlikSenseControl" {}
variable "qlikSenseOrganization" {}
variable "qlikSenseName" {}

# Create a resource group
resource "azurerm_resource_group" "sense" {
  name     = "terraform-01"
  location = "UK South"
}

resource "azurerm_storage_account" "sense" {
  name                     = "sensetfdeploy"
  resource_group_name      = "${azurerm_resource_group.sense.name}"
  location                 = "${azurerm_resource_group.sense.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "templates" {
  name                  = "nestedtemplates"
  resource_group_name   = "${azurerm_resource_group.sense.name}"
  storage_account_name  = "${azurerm_storage_account.sense.name}"
  container_access_type = "blob"
}

resource "azurerm_storage_container" "dsc" {
  name                  = "dsc"
  resource_group_name   = "${azurerm_resource_group.sense.name}"
  storage_account_name  = "${azurerm_storage_account.sense.name}"
  container_access_type = "blob"
}

resource "azurerm_storage_container" "scripts" {
  name                  = "customscripts"
  resource_group_name   = "${azurerm_resource_group.sense.name}"
  storage_account_name  = "${azurerm_storage_account.sense.name}"
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "baseresources" {
  name = "BaseResources.json"

  resource_group_name    = "${azurerm_resource_group.sense.name}"
  storage_account_name   = "${azurerm_storage_account.sense.name}"
  storage_container_name = "${azurerm_storage_container.templates.name}"

  type = "block"
  source = "nestedtemplates/BaseResources.json"
}

resource "azurerm_storage_blob" "dsc" {
  name = "SenseSetup.zip"

  resource_group_name    = "${azurerm_resource_group.sense.name}"
  storage_account_name   = "${azurerm_storage_account.sense.name}"
  storage_container_name = "${azurerm_storage_container.dsc.name}"

  type = "block"
  source = "DSC/SenseSetup.zip"
}

resource "azurerm_storage_blob" "bootstrap" {
  name = "bootstrap.ps1"

  resource_group_name    = "${azurerm_resource_group.sense.name}"
  storage_account_name   = "${azurerm_storage_account.sense.name}"
  storage_container_name = "${azurerm_storage_container.scripts.name}"

  type = "block"
  source = "scripts/bootstrap.ps1"
}

resource "azurerm_template_deployment" "central" {
  name                = "qs-central"
  resource_group_name = "${azurerm_resource_group.sense.name}"

  template_body = "${file("${path.module}/centralnode/azuredeploy.json")}"

  # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters {
    "adminUsername" = "${var.adminUsername}"
    "adminPassword" = "${var.adminPassword}"
    "dnsNameForPublicIP" = "${var.dnsLabelPrefix}"
    "serviceUsername" = "${var.qlikSenseServiceAccount}"
    "servicePassword" = "${var.qlikSenseServiceAccountPassword}"
    "licenseSerial" = "${var.qlikSenseSerial}"
    "licenseControl" = "${var.qlikSenseControl}"
    "licenseOrg" = "${var.qlikSenseOrganization}"
    "licenseName" = "${var.qlikSenseName}"
    #"virtualMachineSize" = "Standard_DS2_v2"
    "_artifactsLocation" = "${replace(azurerm_storage_account.sense.primary_blob_endpoint, "/(/)$/", "")}"
    #"_artifactsLocationSasToken" = "${azurerm_storage_account.sense.primary_access_key}"
  }

  deployment_mode = "Incremental"
  depends_on      = ["azurerm_storage_blob.baseresources"]
}

resource "azurerm_template_deployment" "proxy" {
  name                = "qs-proxy01"
  resource_group_name = "${azurerm_resource_group.sense.name}"

  template_body = "${file("${path.module}/rimnode/azuredeploy.json")}"

  # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters {
    "adminUsername" = "${var.adminUsername}"
    "adminPassword" = "${var.adminPassword}"
    "dnsNameForPublicIP" = "${var.dnsLabelPrefix}-proxy"
    "serviceUsername" = "${var.qlikSenseServiceAccount}"
    "servicePassword" = "${var.qlikSenseServiceAccountPassword}"
    "hostname" = "sense-proxy01"
    "centralNode" = "${azurerm_template_deployment.central.outputs["hostname"]}"
    "nodeType" = "ProxyEngine"
    #"virtualMachineSize" = "Standard_DS2_v2"
    "_artifactsLocation" = "${replace(azurerm_storage_account.sense.primary_blob_endpoint, "/(/)$/", "")}"
    #"_artifactsLocationSasToken" = "${azurerm_storage_account.sense.primary_access_key}"
  }

  deployment_mode = "Incremental"
}

resource "azurerm_template_deployment" "scheduler" {
  name                = "sense-scheduler"
  resource_group_name = "${azurerm_resource_group.sense.name}"

  template_body = "${file("${path.module}/rimnode/azuredeploy.json")}"

  # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters {
    "adminUsername" = "${var.adminUsername}"
    "adminPassword" = "${var.adminPassword}"
    "dnsNameForPublicIP" = "${var.dnsLabelPrefix}-scheduler"
    "serviceUsername" = "${var.qlikSenseServiceAccount}"
    "servicePassword" = "${var.qlikSenseServiceAccountPassword}"
    "hostname" = "qs-schedule01"
    "centralNode" = "${azurerm_template_deployment.central.outputs["hostname"]}"
    "nodeType" = "Scheduler"
    #"virtualMachineSize" = "Standard_DS2_v2"
    "_artifactsLocation" = "${replace(azurerm_storage_account.sense.primary_blob_endpoint, "/(/)$/", "")}"
    #"_artifactsLocationSasToken" = "${azurerm_storage_account.sense.primary_access_key}"
  }

  deployment_mode = "Incremental"
}

output "hostname" {
  value = "${azurerm_template_deployment.central.outputs["hostname"]}"
}
