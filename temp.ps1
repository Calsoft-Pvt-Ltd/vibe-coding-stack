function Test {
    Write-Host "Testing" -NoNewline
    try {
        $result = $true
        if ($result) {
            Write-Host " ok"
        } else {
            Write-Host " fail"
        }
    } catch {
        Write-Host " error"
    }
}

Test
