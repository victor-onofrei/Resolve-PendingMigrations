# Resolve-PendingMigrations

Resolve pending migrations in cases where a mailbox for an user account exists both in Exchange On Premises and in Exchange Online.

Removes the on premises mailboxes if the number of items in the mailbox is below a specific threshold (initialized with `300`) and creates a remote mailbox.

The email addresses are preserved and the remote routing address is taken from the Exchange Organization Configuration (using `Get-OrganizationConfig`).

## Usage

Populate a `.csv` file with a list of mailboxes or pass the argument `-user` followed by the identifier of the mailbox for an ad-hoc run on a single user.
