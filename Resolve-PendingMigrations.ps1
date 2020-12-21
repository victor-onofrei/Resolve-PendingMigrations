param (
    [String]$inputPath = "$env:homeshare\VDI-UserData\Download\generic\inputs\",
    [String]$fileName = "pending_migrations.csv",
    [String]$outputPath = "$env:homeshare\VDI-UserData\Download\generic\outputs\pending_mig",
    [String]$user = $null
)

if ($user) {
    $allMailboxes = @($user)
} else {
    $allMailboxes = Get-Content "$inputPath\$fileName"
}

$routingAddress = (
    Get-OrganizationConfig | `
    Select-Object -ExpandProperty MicrosoftExchangeRecipientEmailAddresses | `
    Where-Object {$_ -like "*mail.onmicrosoft.com"}
).Split("@")[1]

foreach ($mailbox in $allMailboxes) {
    $itemCount = Get-MailboxStatistics $mailbox | Select-Object -ExpandProperty ItemCount
    if ($itemCount -le "300") {
        $mailboxOutput = Get-Mailbox -Identity $mailbox
        $mailboxOutput.EmailAddresses > $outputPath\$mailbox.txt
        $hasArchive = ($mailboxOutput.archiveGuid -ne "00000000-0000-0000-0000-000000000000") -and $mailboxOutput.archiveDatabase
        if (!$hasArchive) {
            Disable-Mailbox -Identity $mailboxOutput.Alias -Confirm:$false
            Enable-RemoteMailbox $mailboxOutput.Alias -RemoteRoutingAddress "$mailbox@$routingAddress"
            Set-RemoteMailbox $mailboxOutput.UserPrincipalName -EmailAddresses $mailboxOutput.EmailAddresses `
             -EmailAddressPolicyEnabled $false
        } else {
            Write-Host "Mailbox" $mailbox "has on-premise archive"
        }
    } else {
        Write-Host "Mailbox" $mailbox "has on-premise content"
    }
}
