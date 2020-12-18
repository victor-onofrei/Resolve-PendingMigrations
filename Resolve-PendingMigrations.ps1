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

foreach ($user in $all_mailboxes)
{
    $item_count = Get-MailboxStatistics $user | select -ExpandProperty ItemCount
    if ($item_count -le "300") {
        $mailbox = Get-Mailbox -Identity $user -ResultSize Unlimited
        $mailbox.EmailAddresses > $output_path\$user.txt
        $archive_state = (Get-Mailbox -Identity $mailbox.Alias).ArchiveState
        if ($archive_state -eq "None") {
            Disable-Mailbox -Identity $mailbox.Alias -Confirm:$false
            $routing_address = (Get-OrganizationConfig | Select -ExpandProperty MicrosoftExchangeRecipientEmailAddresses | `
             ? {$_ -like "*mail.onmicrosoft.com"}).Split("@")[1]
            Enable-RemoteMailbox $mailbox.Alias -RemoteRoutingAddress "$user@$routing_address"
            Set-RemoteMailbox $mailbox.UserPrincipalName -EmailAddresses $mailbox.EmailAddresses `
             -EmailAddressPolicyEnabled $false
        } else {Write-Host "Mailbox" $user "has on-premise archive"}
    } else {Write-Host "Mailbox" $user "has on-premise content"}
}
