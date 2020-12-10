# pending_mig
Resolve pending migrations
Handles cases where a specific user migration fails because a mailbox for that user account exists both in Exchange On Premises and in Exchange Online
Removes the on premises mailboxes if the number of items in the mailbox is below a specific threshold (initialized with '300') and creates a remote mailbox
The email addresses are preserved and the remote routing address is taken from "Get-OrganizationConfig"
