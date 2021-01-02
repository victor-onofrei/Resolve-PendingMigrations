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
        $mailboxInfo = Get-Mailbox -Identity $mailbox
        $mailboxInfo.EmailAddresses > $outputPath\$mailbox.txt
        $hasArchive = ($mailboxInfo.archiveGuid -ne "00000000-0000-0000-0000-000000000000") -and $mailboxInfo.archiveDatabase
        if (!$hasArchive) {
            Disable-Mailbox -Identity $mailboxInfo.Alias -Confirm:$false
            Enable-RemoteMailbox $mailboxInfo.Alias -RemoteRoutingAddress "$mailbox@$routingAddress"
            Set-RemoteMailbox $mailboxInfo.UserPrincipalName -EmailAddresses $mailboxInfo.EmailAddresses `
             -EmailAddressPolicyEnabled $false
        } else {
            Write-Warning "Mailbox $mailbox has on-premise archive"
        }
    } else {
        Write-Warning "Mailbox $mailbox has on-premise content"
    }
}
