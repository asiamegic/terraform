# Configure the Azure provider
terraform {
  required_providers {


    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }

  required_version = ">= 1.1.0"
}
# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "rg" {
  #name     = "myTFResourceGroup"
  name     = var.resource_group_name
  location = var.location

}


# network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}


resource "azurerm_subnet" "appnet" {
  name                 = "appnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

}

resource "azurerm_subnet" "postgresnet" {
  name                 = "postgresnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.4.0/24"]

}

#public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "publicip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}



#Create NSG
resource "azurerm_network_security_group" "rg" {
  name                = "my_nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                                       = "allow_to_app"
    priority                                   = 102
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_port_range                          = "*"
    source_address_prefix                      = "*"
    destination_port_range                     = "8080"
    destination_address_prefix                 = azurerm_subnet.appnet.address_prefixes[0]
  }

  security_rule {
    name                                       = "allow_admin_app"
    priority                                   = 104
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "*"
    source_port_range                          = "*"
    source_address_prefix                      = "5.29.18.207"
    destination_address_prefix = azurerm_subnet.appnet.address_prefixes[0]
    destination_port_ranges                    = ["22"]
  }

    security_rule {
    name                                       = "allow_admin_postgres"
    priority                                   = 105
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "*"
    source_port_range                          = "*"
    source_address_prefix                      = azurerm_subnet.appnet.address_prefixes[0]
    destination_address_prefix = azurerm_subnet.postgresnet.address_prefixes[0]
    destination_port_ranges                    = ["22"]
  }

    security_rule {
    name                                       = "allow_db_local"
    priority                                   = 101
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_port_range                          = "*"
      source_address_prefix                      = azurerm_subnet.appnet.address_prefixes[0]
    destination_port_ranges                    = ["5432"]
    destination_address_prefix = azurerm_subnet.postgresnet.address_prefixes[0]
  }

}

#association NSG
resource "azurerm_subnet_network_security_group_association" "association_app" {
  subnet_id                 = azurerm_subnet.appnet.id
  network_security_group_id = azurerm_network_security_group.rg.id
}

resource "azurerm_subnet_network_security_group_association" "association_db" {
  subnet_id                 = azurerm_subnet.postgresnet.id
  network_security_group_id = azurerm_network_security_group.rg.id
}

#Create Load Balancer
resource "azurerm_lb"  "azurerm_lb" {
  name                = "loadbalance1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                 = "frontend_ip_configuration"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

#rules for LBalancer

resource "azurerm_lb_rule"  "azurerm_lb_rule" {
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.azurerm_lb.id
  name                           = "lb-rule-http"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = azurerm_lb.azurerm_lb.frontend_ip_configuration[0].name
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.azurerm_lb.id
  name            = "BackEndAddressPool"
}



#VM create
resource "azurerm_network_interface" "network_interface_app" {
  count               = "2"
  name                = "${var.webAppPrefix}-nic${count.index}"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.appnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "network_interface_db" {
  count               = "1"
  name                = "postgres_network_interface"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.postgresnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_availability_set" "avset" {
  name                         = "${var.webAppPrefix}avset"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

#application virtual machine
#resource "azurerm_linux_virtual_machine" "vm_app" {
#  count                           = "2"
#  name                            = "${var.webAppPrefix}-vm${count.index}"
#  resource_group_name             = azurerm_resource_group.rg.name
#  location                        = var.location
#  size                            = "Standard_b1s"
#  admin_username                  = var.username
#  admin_password                  = "0542877567A!"
#  availability_set_id             = azurerm_availability_set.avset.id
#  disable_password_authentication = false
#  network_interface_ids           = [
#    azurerm_network_interface.network_interface_app[count.index].id,
#  ]
#
#  source_image_reference {
#    publisher = "Canonical"
#    offer     = "0001-com-ubuntu-server-focal"
#    sku       = "20_04-lts-gen2"
#    version   = "latest"
#  }
#
#  os_disk {
#    storage_account_type = "Standard_LRS"
#    caching              = "ReadWrite"
#  }
#}
#
#
##====================
resource "azurerm_linux_virtual_machine_scale_set" "scale_machine" {
  name                = "scale-machine"
  admin_username      = "artemrafikov"
  admin_password      = "0542877567A!"
  instances           = 2
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard_b1s"
  #upgrade_mode                    = "Automatic"
  disable_password_authentication = false
  depends_on                      = [azurerm_network_security_group.rg]


  network_interface {
    name                      = "netInterface"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.rg.id
    ip_configuration {
      name                                   = "publicIP"
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_pool.id]
      subnet_id                              = azurerm_subnet.appnet.id
      primary                                = true
      public_ip_address {
        name = "scale_machine-ip"
      }
    }
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_monitor_autoscale_setting" "autoscale_setting" {
  location            = var.location
  name                = "autoscale_setting"
  resource_group_name = var.resource_group_name
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.scale_machine.id
  depends_on          = [azurerm_resource_group.rg, azurerm_linux_virtual_machine_scale_set.scale_machine]
  profile {
    name = "AutoScale"
    capacity {
      default = 3
      maximum = 5
      minimum = 1
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.scale_machine.id
        operator           = "GreaterThan"
        statistic          = "Average"
        threshold          = 75
        time_aggregation   = "Average"
        time_grain         = "PT1M"
        time_window        = "PT5M"
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
      }
      scale_action {
        cooldown  = "PT1M"
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
      }
    }
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.scale_machine.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}


#=======================


#vm postgress (database method through virtual machine)
#resource "azurerm_linux_virtual_machine" "vm_postgres" {
#  name                            = "vm_postgres"
#  resource_group_name             = var..resource_group_name
#  location                        = var.location
#  size                            = "Standard_b1s"
#  admin_username                  = "artemrafikov"
#  admin_password                  = "0542877567A!"
#  availability_set_id             = azurerm_availability_set.avset.id
#  disable_password_authentication = false
#  network_interface_ids = [
#    azurerm_network_interface.network_interface_db[0].id,
#  ]
#
#  source_image_reference {
#    publisher = "Canonical"
#    offer     = "0001-com-ubuntu-server-focal"
#    sku       = "20_04-lts-gen2"
#    version   = "latest"
#  }
#
#  os_disk {
#    storage_account_type = "Standard_LRS"
#    caching              = "ReadWrite"
#  }
#}
#========================

 #postgress as a service to azure
resource "azurerm_postgresql_server" "postgres" {
  resource_group_name = var.resource_group_name
  location            = var.location
  name                         = "postgresql-weighttracker-server"
#  sku_name                     = "B_Gen5_1"
  sku_name                     = "B_Gen5_1"
  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  administrator_login          = "psqladmin"
  administrator_login_password = "H@Sh1CoR3!"
  version                      = "9.5"
  ssl_enforcement_enabled      = false
  depends_on                      = [azurerm_resource_group.rg]
}


