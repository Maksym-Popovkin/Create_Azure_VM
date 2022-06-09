# Create_Azure_VM
### This project was created to create an infrastructure in the AZURE cloud.
### For the creation of infrastructure, you need to perform the following actions:
## 1) Have an active AZURE account, if you don't have one, use the [link](https://azure.microsoft.com/en-us/free/?ref=microsoft.com&utm_source=microsoft.com&utm_medium=docs&utm_campaign=visualstudio) to create one
## 2) Setting up Terraform: If you haven't already done so, set up Terraform using one of the following options:
### [Install Terraform on Windows with Bash](https://docs.microsoft.com/en-us/azure/developer/terraform/get-started-windows-bash?tabs=bash)
### [Install Terraform on Windows with Azure PowerShell](https://docs.microsoft.com/en-us/azure/developer/terraform/get-started-windows-powershell?tabs=bash)
## 3) Clone this repository
## 4) Run the following commands:
### terraform init
### terraform apply
### After that, the necessary infrastructure will appear in your AZURE account and a list of IP addresses to the corresponding servers will appear in the console.
## 5) To connect to the servers, you need to run the following commands:
### ssh -i id_rsa azureuser@<ip_address_from_console>
## 6) To delete infrastructures you need to run the following command:
### terraform destroy
