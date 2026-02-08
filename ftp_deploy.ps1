$host_ftp = "82.25.73.189"
$user = "u994400602.flopez"
$pass = "Dan15223-"
$local_dir = "dist"

Write-Host "Iniciando despliegue FTP v1.5.0 (IP Directa)..."

# Obtener todos los archivos en dist
$files = Get-ChildItem -Path $local_dir -Recurse | Where-Object { ! $_.PSIsContainer }

foreach ($file in $files) {
    # Calcular la ruta relativa y la ruta remota
    $relative_path = $file.FullName.Substring((Get-Item $local_dir).FullName.Length + 1).Replace("\", "/")
    $remote_url = "ftp://$host_ftp/$relative_path"
    
    Write-Host "Subiendo: $relative_path ..."
    
    # Subir usando curl (con --ftp-create-dirs para crear assets/, api/, etc.)
    # Nota: -k opcional si hay problemas de SSL, pero aquí es FTP plano
    & curl.exe -T "$($file.FullName)" --user "$($user):$($pass)" "$remote_url" --ftp-create-dirs --silent
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK"
    }
    else {
        Write-Host "  FAILED (Error: $LASTEXITCODE)"
    }
}

Write-Host "Despliegue finalizado."
