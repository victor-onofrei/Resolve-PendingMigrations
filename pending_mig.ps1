$input_path = "$env:homeshare\VDI-UserData\Download\generic\inputs"
$output_path = "$env:homeshare\VDI-UserData\Download\generic\outputs\pending_mig"
$file_name = "pending_mig.csv"
$all_mailboxes = Get-Content $path\$file_name

foreach ($user in $all_mailboxes)
{
    $item_count = Get-MailboxStatistics $user | select -ExpandProperty ItemCount
    if ($item_count -le "300") {
        $mailbox = Get-Mailbox -Identity $user -ResultSize Unlimited
        $mailbox.EmailAddresses > $output_path\$user.txt
        $archive_state = (Get-Mailbox -Identity $mailbox.Alias).ArchiveState
        if ($archive_state -eq "None") {
            Disable-Mailbox -Identity $mailbox.Alias -Confirm:$false
            $routing_address = (Get-OrganizationConfig | Select -ExpandProperty MicrosoftExchangeRecipientEmailAddresses`
            | ? {$_ -like "*mail.onmicrosoft.com"}).Split("@")[1]
            Enable-RemoteMailbox $mailbox.Alias -RemoteRoutingAddress "$user@$routing_address"
            Set-RemotMailbox $mailbox.UserPrincipalName -EmailAddresses $mailbox.EmailAddresses`
            -EmailAddressPolicyEnabled $false
        } else {Write-Host "Mailbox" $user "has on-premise archive"}
    } else {Write-Host "Mailbox" $user "has on-premise content"}
}
