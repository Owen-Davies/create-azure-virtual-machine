Login-AzureRmAccount

# 1. CREATE RESOURCE GROUP
$resourceGroup = "test-infra12"
$location = "North Europe"

New-AzureRmResourceGroup -Name $resourceGroup -Location $location

# 2. CREATE STORAGE ACCOUNT 
$storageAccountName = "teststorage1x223"
New-AzureRmStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroup -Type Standard_LRS -Location $location

# 3. CREATE VIRTUAL NETWORK
$vnetName = "test-net"
$subnet = New-AzureRmVirtualNetworkSubnetConfig -Name frontendSubnet -AddressPrefix 10.0.1.0/24
$vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet

# 4. SETUP IP ADDRESS AND NETWORK INTERFACE
$nicName ="testvm-nic"
$pip = New-AzureRmPublicIpAddress -Name $nicName -ResourceGroupName $resourceGroup -Location $location -AllocationMethod Dynamic
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $resourceGroup -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id

# 5. START VIRTUAL MACHINE CONFIG SETUP
$vmName = "testvm1"
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize "Basic_A1"

# 6. SET VIRTUAL MACHINE CREDENTIALS
$cred=Get-Credential -Message "Admin credentials"  # Either this for the prompt or
#$username = "YOURUSERNAME"
#$password = ConvertTo-SecureString "YOUR_PASSWORD" -AsPlainText -Force
#$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password

# 7. SELECT OPERATING SYSTEM FOR VIRTUAL MACHINE
$vm=Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm=Set-AzureRmVMSourceImage -VM $vm -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2012-R2-Datacenter" -Version "latest"

# 8. ADD NETWORK INTERFACE TO VIRTUAL MACHINE
$vm=Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

# 9. CREATE DISK FOR VIRTUAL MACHINE
$diskName="os-disk"
$storageAcc=Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName
$osDiskUri= $storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $diskName + ".vhd"
$vm=Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage

# 10. CREATE THE VIRTUAL MACHINE
New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vm