# SGU-UNJBG - Semana 14 Cloud-Ready

Proyecto SGU con dashboard, API REST, PostgreSQL, auditoría de los 12 factores y cinco mejoras Cloud-Ready.

Los datos son ficticios; no es un sistema institucional de producción. La auditoría y las mejoras están documentadas en `docs/12-factor-audit.md` y `docs/MEJORAS_PRIORIZADAS.md`.

## 1. GitHub Container Registry y demostraciones adicionales

El procedimiento de ejecución comienza con `scripts/iniciar.ps1`.

### Demostración en dos entornos

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\dos-entornos.ps1
```

Permite ejecutar la misma imagen en dos entornos, utilizando los puertos 8081 y 8082, con diferentes valores de `APP_ENV`, sin reconstruir la imagen.

### Verificación de seguridad

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verificar-imagen.ps1
```

Comprueba aspectos básicos relacionados con la exclusión de secretos y la ejecución sin privilegios de administrador. No sustituye un escaneo de vulnerabilidades.

### Publicación en GitHub Container Registry

El proyecto incluye el workflow:

`.github/workflows/publicar-ghcr.yml`

Para ejecutarlo:

1. Acceder al repositorio de GitHub.
2. Abrir la pestaña **Actions**.
3. Seleccionar **Publicar SGU en GitHub Container Registry**.
4. Hacer clic en **Run workflow**.
5. Revisar los resultados de construcción, pruebas y escaneo Trivy.
6. Registrar la URL, el tag y el digest de la imagen publicada.

La publicación necesita permisos de GitHub Actions y Packages.

## 2. Inicio rápido en Windows

Requisitos:

- Docker Desktop iniciado.
- Contenedores Linux habilitados.
- PowerShell.
- Puerto 8080 disponible.

Abrir PowerShell en la carpeta del proyecto y ejecutar:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\iniciar.ps1
```

El script crea `.env` si no existe, genera una contraseña local, construye los contenedores, inicia los servicios, ejecuta la migración y abre el navegador.

No requiere instalar Node.js localmente.

### Ejecución manual alternativa

```powershell
docker --version
docker compose version
docker info
Copy-Item .env.example .env
notepad .env
docker compose config --quiet
docker compose up --build -d
docker compose exec -T api npm run migrate
docker compose ps
Start-Process 'http://localhost:8080'
```

En `.env` debe configurarse una contraseña local para `DB_PASSWORD`.

Antes de la migración, el endpoint readiness puede devolver HTTP 503 porque todavía no existen las tablas. Después de migrar, debe devolver HTTP 200 cuando la aplicación esté preparada.

Si el puerto 8080 está ocupado, cambiar `HOST_PORT` en `.env` y utilizar el puerto correspondiente.

## 3. Pruebas de endpoints y matrícula

```powershell
curl.exe -i http://localhost:8080/health/live
curl.exe -i http://localhost:8080/health/ready
curl.exe -i http://localhost:8080/api/v1/catalog
curl.exe -i http://localhost:8080/api/v1/dashboard
curl.exe -i http://localhost:8080/api/v1/enrollments
```

Para registrar una matrícula:

```powershell
'{"studentId":1,"sectionId":1}' | Set-Content -Encoding ascii solicitud.json

curl.exe -i -X POST http://localhost:8080/api/v1/enrollments -H 'Content-Type: application/json' --data-binary '@solicitud.json'
```

Resultados esperados:

| Caso | Código HTTP |
|---|---|
| Matrícula creada | 201 |
| Matrícula duplicada | 409 |
| Identificador inválido | 422 |
| Recurso inexistente | 404 |
| JSON malformado | 400 |
| Cuerpo mayor de 32 KB | 413 |
| Error inesperado | 500 |

Las respuestas y los logs utilizan `requestId` y `request_id` para relacionar las solicitudes.

## 4. Pruebas automatizadas

Con Node.js 24 instalado:

```powershell
npm ci
npm test
```

El trabajo anterior registró 22 comprobaciones unitarias y HTTP aprobadas.

Para ejecutar las pruebas de integración con PostgreSQL mediante Docker:

```powershell
docker compose -p sgu-pruebas -f compose.test.yaml up --build --abort-on-container-exit --exit-code-from tests

docker compose -p sgu-pruebas -f compose.test.yaml down
```

La suite de integración contempla 12 comprobaciones, incluyendo matrícula válida, duplicados, errores y concurrencia.

Estas pruebas se ejecutan sobre una base temporal de pruebas, independiente de los datos de demostración.

## 5. Evidencias Docker y persistencia

Para ejecutar las verificaciones automáticas:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\evidencias.ps1 -StudentId 2 -SectionId 1
```

El script comprueba respuestas HTTP, logs, estado del sistema y persistencia.

Para comprobar manualmente los registros y reinicio:

```powershell
docker compose logs --tail=100 api
docker compose down
docker compose up -d
```

`docker compose down` conserva los datos del volumen persistente.

**Importante:** `docker compose down -v` elimina también los volúmenes y puede borrar los datos de laboratorio.

## 6. Validación de configuración externa

Para verificar el manejo de variables obligatorias:

1. Guardar una copia local del archivo `.env`.
2. Eliminar temporalmente la variable `DB_PASSWORD`.
3. Ejecutar:

```powershell
docker compose up -d --force-recreate api
docker compose logs --tail=50 api
```

El sistema debe rechazar el inicio e indicar que falta una variable obligatoria, sin mostrar la contraseña.

Después, restaurar `DB_PASSWORD` y recrear el servicio.

No publicar el archivo `.env` ni capturas que muestren credenciales.

## 7. Acceso desde otra computadora

Obtener la dirección IPv4 de la computadora donde se ejecuta Docker:

```powershell
ipconfig
```

Desde otra computadora conectada a la misma red, abrir:

`http://IPV4_DEL_SERVIDOR:8080`

Si Windows bloquea la conexión, configurar el firewall únicamente para la red local del laboratorio.

## 8. Archivos principales

| Archivo o carpeta | Función |
|---|---|
| `src/` | API REST y lógica del sistema |
| `public/` | Dashboard web |
| `test/` | Pruebas unitarias y HTTP |
| `integration/` | Pruebas de integración con PostgreSQL |
| `scripts/` | Automatización y verificaciones en PowerShell |
| `Dockerfile` | Construcción de la imagen |
| `compose.yaml` | API y PostgreSQL |
| `compose.test.yaml` | Entorno de pruebas |
| `package.json` | Dependencias y comandos |
| `package-lock.json` | Versiones de dependencias |
| `.env.example` | Plantilla de configuración |
| `.dockerignore` | Exclusiones para construir la imagen |
| `docs/12-factor-audit.md` | Auditoría de los 12 factores |
| `docs/MEJORAS_PRIORIZADAS.md` | Cinco mejoras priorizadas |
| `.github/workflows/publicar-ghcr.yml` | Publicación de la imagen en GHCR |

## 9. Estado de validación

El proyecto incorpora las mejoras Cloud-Ready relacionadas con configuración externa, dependencias reproducibles, manejo de errores, logs estructurados, PostgreSQL y pruebas automatizadas.

En las verificaciones anteriores se reportaron 22 comprobaciones unitarias/HTTP y 12 de integración aprobadas.

Las pruebas de Docker Compose, persistencia en volúmenes, ejecución en dos entornos y publicación en GitHub Container Registry deben verificarse durante la ejecución del laboratorio.

## 10. Consideraciones de seguridad

- No subir archivos `.env` con credenciales reales.
- No incluir contraseñas ni tokens en el código.
- Utilizar `.env.example` únicamente como plantilla.
- Ejecutar los contenedores con privilegios mínimos.
- Evitar exponer datos sensibles en respuestas HTTP y logs.
- Utilizar versiones identificables de las imágenes.
- Registrar el digest real al publicar en GitHub Container Registry.

El proyecto es de uso académico y emplea datos ficticios.
