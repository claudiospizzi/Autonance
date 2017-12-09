
Properties {

    $ModuleNames = 'Autonance'

    $GalleryEnabled = $true
    $GalleryKey     = Get-VaultSecureString -TargetName 'PS-SecureString-GalleryKey'

    $GitHubEnabled  = $true
    $GitHubRepoName = 'claudiospizzi/Autonance'
    $GitHubToken    = Get-VaultSecureString -TargetName 'PS-SecureString-GitHubToken'
}
