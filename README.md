# UdacityAzureDevOps
Azure DevOps - Azure IaaS Project: Deploying A Webserver

**Introduction**
This is a project that uses a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

Read through this README file fully before proceeding with deploying the templates.

**Prerequisites**: 
Below are the prerequisites:

a. An azure account and a valid & active subscription with room to create at least 1 Resource Group and about 20 resources under the resource  group that includes Virtual networks, subnets, private & public IP, OS Image, disks, VMs etc

b. Latest version of Terraform installation on your PC or env. Refer (https://www.terraform.io/downloads.html)

c. Latest version of Packer installation on your PC or env. Refer https://www.packer.io/downloads/

d. An installation of Azure CLI on your PC. Refer https://docs.microsoft.com/en-us/cli/azure/

**Getting Started:**
1. Download the three files -  main.tf, variables.tf and server.json from this repository
2. Store the files in a desired empty directory 

**Following are details about the terraform and packer templates:**

**main.tf**
The file "main.tf" is your primary script that contains definition of resources to be created and detailed specifications of each resource in infrastructure element. Resources like resource groups, networks, subnets, NIC, Network Security group, Load balancer, availabilility sets, data disks and VMs are defined in this template.

**variables.tf**
The variables.tf file contains refences for all the variables used in main.tf. Each of the variable values in variables.tf file can be customized either directly on the file or the variables values can be set during runtime when you execute the 'terraform apply'. 
	
	If you wish to change the values on the file variables.tf, then edit it using a standard text editor like notepad++, atom, etc. In variables.tf, Change value of the field 'default = ' to your desired value. 
	For eg. if you want 'prefix' of your deployment to be "MyProject", then set default = "MyProject" on line#3 of variables.tf
	Below are the variables defined on 'variables.tf' file, and each variable has a field named 'default', which has to be changed. Take utmost care not to edit anything else or disturb the formatting of the file. 

	If you wish to set values of each variable during runtime when you execute the 'terraform apply', then delete the lines that contain 'default'. This is least recommended as it might be cumbersom for you to enter the values of variables in the correct format that the main.tf expects.

List of variables in variables.tf:

	prefix
	location
	username
	LbBkEndPoolAddr
	VirtNetCIDR
	subNet4virtNet
	vmCount
	dataDiskCount
	feportstart
	feportend
	beport
	lbHttpPort
	instances
	nb_disks_per_instance

variables.tf file has a description for each of these files.


**server.json**
This is a packer template that is used to upload image onto your azure subscription. 
			

**Instructions to deploy:**

Open PowerSell or AzCLI terminal, change to the execution directory where you have main.tf, variables.tf and server.json and run the command command: 
	
	az login

Follow the instruction to be authenticated to Azure and then execute the command:
	
	az account list
	
Validate the output and make sure you are on the right Az subscription and the subscription is Active and enabled. 

On the terminal, run the command 'ls' and make sure you see the files main.tf, variables.tf and server.json. Eg output:

	PS C:\Users\xxxxxxxxx\Documents\xxxxxxxx\NanoDegree\AzureDevOps\Assignments\IaaSProject\> ls


    Directory: C:\Users\xxxxxxxxx\Documents\xxxxxxxx\NanoDegree\AzureDevOps\Assignments\IaaSProject\>


	Mode                LastWriteTime         Length Name
	----                -------------         ------ ----
	-a----        4/20/2021   5:00 PM          10112 main.tf
	-a----        4/20/2021   5:46 PM            842 server.json
	-a----        4/20/2021   4:04 PM           2215 variables.tf

Note: The above is just an example out and your execution directory can be different than above. 

To begin with, we will create/upload OS image to Azure subscription. Using a text editor of your choice, first edit 'subscription_id' field in server.json:

On line#5, Replace the xxxxxxxxxxxxxxxxxxxxxxxxxxx with your Azure subscription ID.

  	"subscription_id": "xxxxxxxxxxxxxxxxxxxxxxxxxxx"

Azure subscription ID can be obtained from:
			- Aure portal -> Home -> Subscription ID
			or 
			- In the output of command 'az account list'. The value of "id" in the output is your subscription ID. 

Next significant thing on server.json is resource group set by the field - "managed_image_resource_group_name". Make sure that this resource group is different from what you actually planned to have for your IaaS deployment. Note that the resource group on this server.json file should be created before you begin to execute the command - 'packer build server.json' to upload the image to your subscription. Navigate to Azure portal, Home -> Resource Group -> click on New. Select your Az subscription and then enter 'PackerRG' in Resource Group field. Click on Review+Create and on next page click Create. 'PackerRG' resource group will be created.

Now we will deploy the OS image on your subscription by running the below command:

	packer build server.json
	
This command will take about 5-6 minutes. Make sure the command runs successfully and there are no errors. Validate that the image has been uploaded successfully by running the command:

	az image list

Alternately, you can validate successful image upload on Azure portal as well. Next, execute the below command to initialize terraform environment on the current directory.
	
	terraform init

After this command, you will see a new '.terraform' directory on your execution directory.
At this point, edit 'variables.tf' file, if you have not already done, to set your variables to desired values. If you have already edited it, review each value to be sure everything is correct.

Next, execute the below command. This command will validate the main.tf file and variables.tf file. Make sure the command running successfully. 

	terraform plan -out solution.plan
	
Below is the example output (last few lines only of the huge output):

	
	Plan: 27 to add, 0 to change, 0 to destroy.

	------------------------------------------------------------------------

	This plan was saved to: solution.plan

	To perform exactly these actions, run the following command to apply:
    terraform apply "solution.plan"

Review  the output of the previous command, and make sure the deployment & resources is what you actually planned for. If you think there is something undesirable, stop here and review your terraform templates and edit if necessary. If everything is looking good, execute the below command to start your deployment: 
    
	terraform apply "solution.plan"

The actual deployment of resources begins on execution of the above command. Resources like resource groups, networks, subnets, NIC, Network Security group, Load balancer, availabilility sets, data disks and VMs will be created. Once the command finishes running, make sure there is no errors or execution failures. Logon on Azure portal, and navigate to Home -> Resource Groups. Click on your resource group and validate all the planned/desired resources have been created. Make sure the number of VMs you configured in the variables.tf file has been created and desired no of disks attached to every VM. Check for the Load balancer is present and it has the correct public IP address. Validate the network security group and the security rules within it. You can perform more check like VMs not being reachable directly from internet and also inter-VM reachability works fine. 

Open a web browser on your PC and enter the URL   

	http://<Public IP address of Load Balancer front end>:80/index.html 

Make sure you see the text - Hello, World!

You can perform more checks on the VM logs and running packets capture on the PC if you wish. Once you are done with your checks & tests, execute the below command on PowerShell project execution directory to delete your deployment.


	terraform destroy


Make sure the command runs successfully. Navigate to the Azure portal, and check that the resource group has been successfully deleted under your subscription. And then execute the below command to delete the image that you previously uploaded using the packer tool.

	az image delete -g <Packer-Resource-Group> -n <OS Image name or ID>
	
Once again make sure your Azure subscription has been compeltely freed up of all the resources that were created for this project. 

	
