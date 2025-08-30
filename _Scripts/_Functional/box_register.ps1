# Get the output from docker-machine
$dockerEnvOutput = docker-machine env box

# Process each line of the output
$dockerEnvOutput | ForEach-Object {
    # Use a regular expression to reliably capture the variable and value
    # This looks for "SET", then captures the variable name, then "=", then captures the value
    if ($_ -match '^SET\s+([^=]+)=(.+)') {
        # $matches[1] is the variable name (e.g., DOCKER_HOST)
        # $matches[2] is the value (e.g., "tcp://...")
        $variableName = $matches[1]
        $variableValue = $matches[2]

        # Remove quotes from the value if they exist
        $variableValue = $variableValue.Trim('"')

        Write-Host "Setting system variable: $variableName = $variableValue"
        
        # Set the variable at the system (Machine) level
        [System.Environment]::SetEnvironmentVariable($variableName, $variableValue, 'Machine')
    }
}

Write-Host "`nSUCCESS: System variables have been set." -ForegroundColor Green
Write-Host "Please open a NEW terminal window for the changes to take effect."