<#
.SYNOPSIS
    Genera la galeria de dibujos, la metadata, y la sube a GitHub.
.DESCRIPTION
    Este script:
    1. Ejecuta 'generate-metadata.ps1' para preguntar por fotos nuevas.
    2. Copia las fotos de 'fotos/' a 'docs/images/photos/'.
    3. Ejecuta 'gallery-build' para regenerar el HTML y las miniaturas.
    4. Vacia la carpeta 'fotos/'.
    5. Hace git add, commit y push.
.NOTES
    Requiere Python 3 y simple-photo-gallery instalado:
    pip install simple-photo-gallery
#>

# ===== Colores =====
function Write-Step    { Write-Host "[*] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[+] $args" -ForegroundColor Green }
function Write-Warn    { Write-Host "[!] $args" -ForegroundColor Yellow }
function Write-Err     { Write-Host "[X] $args" -ForegroundColor Red }

# ===== Configuracion =====
$FotosSource = "fotos"
$PublicDir = "docs"
$PhotosDest = "$PublicDir\images\photos"

# ===== Verificar que estamos en la raiz del repo =====
if (-not (Test-Path ".git")) {
    Write-Err "No estas en la raiz del repositorio. Abortando."
    exit 1
}

# ===== Verificar que existe la carpeta de fotos =====
if (-not (Test-Path $FotosSource)) {
    Write-Step "Creando carpeta '$FotosSource'..."
    New-Item -ItemType Directory -Path $FotosSource -Force | Out-Null
    Write-Warn "Carpeta '$FotosSource' creada. Pon tus fotos ahi y vuelve a ejecutar."
    exit 0
}

# ===== Verificar que hay fotos =====
$fotos = Get-ChildItem -Path $FotosSource -File | Where-Object { $_.Name -ne ".gitkeep" }
if ($fotos.Count -eq 0) {
    Write-Warn "No hay fotos en '$FotosSource'. Pon algunas y vuelve a ejecutar."
    exit 0
}

Write-Step "Encontradas $($fotos.Count) foto(s) en '$FotosSource'."

# ===== Paso 1: Generar metadata =====
Write-Host ""
Write-Step "===== Paso 1: Generar metadata ====="
$metadataScript = Join-Path (Get-Location).Path "generate-metadata.ps1"
if (Test-Path $metadataScript) {
    & $metadataScript
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
        Write-Warn "generate-metadata.ps1 termino con codigo $LASTEXITCODE. Continuando..."
    }
} else {
    Write-Warn "No se encontro 'generate-metadata.ps1'. Saltando este paso."
}

# ===== Paso 2: Copiar fotos a docs/images/photos =====
Write-Host ""
Write-Step "===== Paso 2: Copiar fotos ====="
if (-not (Test-Path $PhotosDest)) {
    New-Item -ItemType Directory -Path $PhotosDest -Force | Out-Null
}

foreach ($foto in $fotos) {
    $destino = Join-Path $PhotosDest $foto.Name
    Copy-Item -Path $foto.FullName -Destination $destino -Force
    Write-Host "  -> $($foto.Name)"
}

Write-Success "Fotos copiadas."

# ===== Paso 3: Ejecutar gallery-build =====
Write-Host ""
Write-Step "===== Paso 3: Regenerar galeria ====="
$galleryBuild = Get-Command gallery-build -ErrorAction SilentlyContinue
if (-not $galleryBuild) {
    Write-Err "'gallery-build' no encontrado. Instala con: pip install simple-photo-gallery"
    exit 1
}

Push-Location $PublicDir
try {
    gallery-build
    if ($LASTEXITCODE -ne 0) {
        Write-Err "gallery-build fallo."
        Pop-Location
        exit 1
    }
} finally {
    Pop-Location
}

Write-Success "Galeria regenerada."

# ===== Paso 4: Vaciar la carpeta 'fotos/' =====
Write-Host ""
Write-Step "===== Paso 4: Vaciar carpeta 'fotos/' ====="
Get-ChildItem -Path $FotosSource -File | Where-Object { $_.Name -ne ".gitkeep" } | Remove-Item -Force
Write-Success "Carpeta '$FotosSource' vaciada."

# ===== Paso 5: Git add, commit, push =====
Write-Host ""
Write-Step "===== Paso 5: Git ====="
git add .

$status = git status --short
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Warn "No hay cambios para commitear."
    exit 0
}

Write-Host ""
Write-Host "Cambios a commitear:" -ForegroundColor Cyan
Write-Host $status
Write-Host ""

$commitMsg = Read-Host "Escribe el mensaje del commit (o Enter para 'update gallery')"
if ([string]::IsNullOrWhiteSpace($commitMsg)) {
    $commitMsg = "update gallery"
}

Write-Step "Haciendo git commit ..."
git commit -m "$commitMsg"

Write-Step "Haciendo git push ..."
git push

if ($LASTEXITCODE -ne 0) {
    Write-Warn "Push fallo. Intentando con pull --rebase..."
    git pull --rebase origin main
    git push
}

Write-Host ""
Write-Success "Galeria actualizada y subida con exito."
Write-Host ""