param($Request, $TriggerMetadata)

Write-Output "PowerShell function executed."

# Example: return current date and time
$body = @{
    Message = "Hello from Azure Function!"
    Date    = (Get-Date)
}

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = 200
    Body = $body
})
