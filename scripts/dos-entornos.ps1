# Crea dos configuraciones LOCALES para demostrar la misma imagen (mismo ID).
# Requiere haber ejecutado previamente scripts/iniciar.ps1 y contar con Docker Desktop.
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
if (-not (Test-Path '.env')) { throw 'Primero ejecutar scripts/iniciar.ps1 para crear .env.' }
function Docker-OK {
    docker @args
    if ($LASTEXITCODE -ne 0) { throw 'Fallo Docker; revise la salida anterior.' }
}
Docker-OK image inspect sgu-unjbg/matricula-api:1.0.0 --format '{{.Id}}'
$source = Get-Content '.env'
foreach ($entry in @(@{Suffix='a';Port='8081';Mode='testing'},@{Suffix='b';Port='8082';Mode='staging'})) {
    $filename = ".env.demo-$($entry.Suffix)"
    $lines = @($source | Where-Object { $_ -notmatch '^(SGU_ENV_FILE|HOST_PORT|APP_ENV)=' })
    $lines += "HOST_PORT=$($entry.Port)"
    $lines += "APP_ENV=$($entry.Mode)"
    $lines += "SGU_ENV_FILE=$filename"
    [IO.File]::WriteAllLines((Join-Path (Get-Location) $filename), [string[]]$lines)
    $project = "sgu-demo-$($entry.Suffix)"
    Docker-OK compose --env-file $filename -p $project up -d --no-build
    Docker-OK compose --env-file $filename -p $project exec -T api npm run migrate
    $url = "http://localhost:$($entry.Port)/health/ready"
    $ok=$false
    for ($i=0; $i -lt 45; $i++) {
        try { if ((Invoke-RestMethod $url).status -eq 'ready') { $ok=$true; break } }
        catch { Start-Sleep -Seconds 2 }
    }
    if (-not $ok) { throw "Sin respuesta ready para $project en $url" }
    Write-Host "$project => ready => $url"
}
Write-Host 'AMBOS ENTORNOS usan el mismo tag local (sin recompilar).'
Docker-OK image inspect sgu-unjbg/matricula-api:1.0.0 --format '{{.Id}}'
Write-Host 'Para detener: docker compose --env-file .env.demo-a -p sgu-demo-a down'
Write-Host '              docker compose --env-file .env.demo-b -p sgu-demo-b down'
Write-Host 'Los volumenes nombrados se conservan (NO utilizar down -v).'
