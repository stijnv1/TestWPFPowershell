[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
Add-Type -AssemblyName System.Windows.Forms

$InputXAML = @'
<Window x:Class="TestWPFPowershell.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:TestWPFPowershell"
        mc:Ignorable="d"
        Title="MainWindow" Height="393.309" Width="705.618">
    <Grid Margin="0,0,0.2,0">
        <Button x:Name="btnGetSubscriptionResourceGroups" Content="Get Azure Resource Groups" HorizontalAlignment="Left" Margin="14,20,0,0" VerticalAlignment="Top" Width="256" Height="43"/>
        <ListView x:Name="lstItems" Margin="385,20,80,17">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="ResourceGroupName" DisplayMemberBinding="{Binding ResourceGroupName}"/>
                    <GridViewColumn Header="ResourceGroup ID" DisplayMemberBinding="{Binding ResourceGroupID}"/>
                </GridView>
            </ListView.View>
        </ListView>
        <Label x:Name="lblAzureSubscriptionID" Content="" Margin="14,309,401,17"/>
        <Label x:Name="lblAzureSubscriptionIDTitle" Content="Label" Margin="14,249,401,59" FontSize="30" FontWeight="Bold"/>
    </Grid>
</Window>
'@

#cleanup XAML
$InputXAML = $InputXAML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'
[xml]$XAML = $InputXAML

#Read XAML
$reader= New-Object System.Xml.XmlNodeReader $xaml
Try
{
	$Form = [Windows.Markup.XamlReader]::Load($reader)

}
Catch
{
	Write-Host "Unable to load Windows.Markup.XamlReader. Some possible causes for this problem include: .NET Framework is missing PowerShell must be launched with PowerShell -sta, invalid XAML code was encountered."
}

#region load form objects and show form after login in Azure Subscription
$XAML.SelectNodes("//*[@Name]") | % {
		Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)
	}

#login in Azure Subscription
$AzureSubscriptionInfo = Login-AzureRmAccount

#fill label with subscription ID
$lblAzureSubscriptionIDTitle.Content = "Azure Subscription ID"
$lblAzureSubscriptionID.Content = $AzureSubscriptionInfo.Context.Subscription.SubscriptionId


#add events to form objects - define event handlers
$GetAzureResourceGroupsEventHandler = 
{
	$AzureResourceGroups = Get-AzureRmResourceGroup
	$AzureResourceGroups | % {
			$lstItems.Items.Add([PSCustomObject]@{'ResourceGroupName'=$_.ResourceGroupName;'ResourceGroupID'=$_.ResourceId})
		}
}

$btnGetSubscriptionResourceGroups.Add_Click($GetAzureResourceGroupsEventHandler)

#load the WPF form
$Form.ShowDialog() | out-null

#endregion

