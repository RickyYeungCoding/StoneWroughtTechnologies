# Function to display the menu and get user choice
function Show-Menu {
    Clear-Host
    Write-Host "~~~ User Management Tool ~~~"
    Write-Host "1. Add User"
    Write-Host "2. Delete User"
    Write-Host "3. Exit"
    $choice = Read-Host "Enter your choice"
    return $choice
}

# Function to add a user
function Add-User {
    while ($true) {
        # Prompt for first name, last name, username, and password
        $firstName = Read-Host "Enter first name or type 'exit' to return to main menu"
         if ($firstname -eq "exit") {
            return
        }
        $lastName = Read-Host "Enter last name"
        $username = Read-Host "Enter username"
        $password = Read-Host "Enter password" -AsSecureString # Hides password input
        
        # Check if username is provided
        if ([string]::IsNullOrEmpty($username)) {
            Write-Host "Username cannot be empty. Please try again."
            continue
        }

        # Convert SecureString password to plaintext
        $passwordBSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
        $passwordText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($passwordBSTR)

        # Set user's full name
        $fullName = "$firstName $lastName"

        # Add user with full name
        $null = New-LocalUser -Name $username -Password $password -FullName $fullName -Description "Created via PowerShell"

        # Prompt for group membership
        $groupChoice = Read-Host "Enter 'U' to add user to 'Users' group, 'A' to add user to 'Administrators' group, or 'exit' to return to main menu"

        # Validate and add user to selected group
        if ($groupChoice -eq 'exit') {
            return
        }

        if ($groupChoice.ToUpper() -eq 'U') {
            Add-LocalGroupMember -Group "Users" -Member $username
            Write-Host "User $username added to 'Users' group."
        }
        elseif ($groupChoice.ToUpper() -eq 'A') {
            Add-LocalGroupMember -Group "Administrators" -Member $username
            Write-Host "User $username added to 'Administrators' group."
        }
        else {
            Write-Host "Invalid choice. No group membership changes were made."
        }
        
        # Enabling password change for user at next logon
        if (Get-LocalUser -Name $username -ErrorAction SilentlyContinue) {
            # Expire the user's password
            $user = [ADSI]"WinNT://./$username,user"
            $user.psbase.InvokeSet("PasswordExpired", 1)
            $user.psbase.CommitChanges()
            Write-Output "Password change required for user '$username' at next logon."
        } else {
            Write-Output "User '$username' not found."
        }
    }
}

# Function to delete a user
function Delete-User {
    while ($true) {
        # Display current users with their account type
        Write-Host "Current users:"
        $currentUsers = Get-WmiObject -Class Win32_UserAccount | 
                        Where-Object { $_.LocalAccount -eq $true -and $_.Disabled -eq $false } | 
                        Select-Object Name

        $currentUsers | ForEach-Object {
            $userName = $_.Name
            $isAdmin = $false
            
            # Get user object
            $userObj = New-Object System.DirectoryServices.DirectoryEntry("WinNT://./$userName,user")

            # Get user groups
            $userGroups = $userObj.psbase.Invoke("Groups") | ForEach-Object { $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null) }

            # Check if the user is a member of the Administrators group
            $isAdmin = $userGroups -contains "Administrators"

            $accountType = if ($isAdmin) {"Administrator"} else {"User"}
            Write-Host "$userName - $accountType"
        }

         # Prompt for username to delete or exit
         $choice = Read-Host "Enter the username to delete or type 'exit' to return to the main menu"
         if ($choice -eq "exit") {
               return
        }

         # Delete the user
         net user $choice /delete
         Write-Host "User $choice deleted."
        
        if ([string]::IsNullOrEmpty($choice)) {
            Write-Host "Username cannot be empty. Please try again."
            continue
        }

        # Check if the username exists
        if ($currentUsers.Name -notcontains $choice) {
            Write-Host "User '$choice' not found. Please enter a valid username or type 'exit' to return to main menu."
            continue
        }
    }
}

# Main script
while ($true) {
    $choice = Show-Menu
    switch ($choice) {
        1 { Add-User }
        2 { Delete-User }
        3 { return }
        Default { Write-Host "Invalid choice. Please try again." }
    }
}

# Resources: https://www.youtube.com/watch?v=UBhixaTX8VE, https://www.youtube.com/watch?v=SbAo0_UFJYU
