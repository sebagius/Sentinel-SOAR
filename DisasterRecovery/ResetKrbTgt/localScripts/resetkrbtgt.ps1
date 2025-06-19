function Generate-SecureRandomString {
    param ([int]$Length)

    $allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+``~\/?.,<>;:'`"[]|"
    $bytes = New-Object 'Byte[]' ($length)
    (New-Object System.Security.Cryptography.RNGCryptoServiceProvider).GetBytes($bytes)
    $readable = ($bytes | ForEach-Object { $allowedChars[$_ % $allowedChars.Length]})  -join ''
    return $readable
}

function Generate-Password {
    $password = Generate-SecureRandomString -Length 32
    while(-not ($password -cmatch "[a-z]" -and $password -cmatch "[A-Z]" -and $password -match '\d' -and $password -match '[\^~!@#$%^&*_+=`|\\(){}\[\]:;"''<>,.?/]')) {
        $password = Generate-SecureRandomString -Length 32
    }

    return $password
}

