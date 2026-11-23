# Inspección básica complementaria: no sustituye un escaneo de vulnerabilidades.
param([string]$Image='sgu-unjbg/matricula-api:1.0.0')
$ErrorActionPreference='Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
docker image inspect $Image --format 'ID={{.Id}} | USER={{.Config.User}} | PORTS={{json .Config.ExposedPorts}}'
if ($LASTEXITCODE -ne 0) { throw 'No se encontró la imagen. Construir primero con Docker.' }
# No imprimir el contenido de posibles archivos secretos.
docker run --rm --entrypoint sh $Image -c 'test ! -e /app/.env && test ! -e /app/.env.local && test ! -d /app/.git && test "$(id -u)" != "0"'
if ($LASTEXITCODE -ne 0) { throw 'Falló la comprobación básica de secretos o usuario no-root.' }
Write-Host 'OK: sin .env en /app, sin .git y usuario no-root.'
Write-Host 'IMPORTANTE: verificar además el resultado del escaneo Trivy en GitHub Actions.'
