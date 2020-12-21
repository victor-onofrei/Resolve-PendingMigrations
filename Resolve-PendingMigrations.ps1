param (
    [String]$inputPath = "$env:homeshare\VDI-UserData\Download\generic\inputs\",
    [String]$fileName = "pending_migrations.csv",
    [String]$outputPath = "$env:homeshare\VDI-UserData\Download\generic\outputs\pending_mig"
    [String]$user = $null
)

if ($user) {
    $allMailboxes = @($user)
} else {
    $allMailboxes = Get-Content "$inputPath\$fileName"
}

$routingAddress = (
    Get-OrganizationConfig | `
    Select -ExpandProperty MicrosoftExchangeRecipientEmailAddresses | `
    ? {$_ -like "*mail.onmicrosoft.com"}
).Split("@")[1]

foreach ($user in $allMailboxes)
{
    $itemCount = Get-MailboxStatistics $user | Select -ExpandProperty ItemCount
    if ($itemCount -le "300") {
        $mailbox = Get-Mailbox -Identity $user -ResultSize Unlimited
        $mailbox.EmailAddresses > $outputPath\$user.txt
        $archiveState = (Get-Mailbox -Identity $mailbox.Alias).ArchiveState
        if ($archiveState -eq "None") {
            Disable-Mailbox -Identity $mailbox.Alias -Confirm:$false
            Enable-RemoteMailbox $mailbox.Alias -RemoteRoutingAddress "$user@$routingAddress"
            Set-RemoteMailbox $mailbox.UserPrincipalName -EmailAddresses $mailbox.EmailAddresses `
             -EmailAddressPolicyEnabled $false
        } else {Write-Host "Mailbox" $user "has on-premise archive"}
    } else {Write-Host "Mailbox" $user "has on-premise content"}
}
