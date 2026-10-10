<#
.SYNOPSIS
    Genera o actualiza metadata.json para los dibujos nuevos.
.DESCRIPTION
    Este script:
    1. Lee las fotos de la carpeta 'fotos/'.
    2. Para cada foto nueva (no presente en metadata.json), pregunta al usuario:
       - Autor (default: Anónimo)
       - Categoría (selección de lista)
       - Fecha (default: hoy)
       - Tags (opcional, separados por coma)
    3. Actualiza 'docs/metadata.json' con la info.
    4. Si una imagen ya existe en el metadata, no la vuelve a preguntar.
.NOTES
    Ejecutar desde la raiz del repo de la web.
#>

# ===== Colores =====
function Write-Step    { Write-Host "[*] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[+] $args" -ForegroundColor Green }
function Write-Warn    { Write-Host "[!] $args" -ForegroundColor Yellow }
function Write-Err     { Write-Host "[X] $args" -ForegroundColor Red }

# ===== Configuracion =====
$FotosSource = "fotos"
$MetadataFile = "docs\metadata.json"

$Categorias = @(
    "retrato",
    "personaje",
    "logo",
    "paisaje",
    "abstracto",
    "animal",
    "objeto",
    "escena",
    "sin-categoria"
)

# ===== Verificar que estamos en la raiz del repo =====
if (-not (Test-Path ".git")) {
    Write-Err "No estas en la raiz del repositorio. Abortando."
    exit 1
}

# ===== Verificar que existe la carpeta de fotos =====
if (-not (Test-Path $FotosSource)) {
    Write-Warn "No existe la carpeta '$FotosSource'. Nada que procesar."
    exit 0
}

# ===== Leer el metadata existente =====
$metadata = @{}
if (Test-Path $MetadataFile) {
    try {
        $metadataJson = Get-Content $MetadataFile -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($prop in $metadataJson.PSObject.Properties) {
            $metadata[$prop.Name] = $prop.Value
        }
        Write-Success "Metadata existente cargado: $($metadata.Count) entradas."
    } catch {
        Write-Warn "No se pudo leer el metadata existente. Se creara uno nuevo."
        $metadata = @{}
    }
} else {
    Write-Step "No existe metadata.json. Se creara uno nuevo."
    # Asegurar que existe docs/
    if (-not (Test-Path "docs")) {
        New-Item -ItemType Directory -Path "docs" -Force | Out-Null
    }
}

# ===== Listar fotos nuevas =====
$fotos = Get-ChildItem -Path $FotosSource -File |
    Where-Object { $_.Name -ne ".gitkeep" -and $_.Extension -match '\.(png|jpg|jpeg|gif|webp|heic)$' }

if ($fotos.Count -eq 0) {
    Write-Warn "No hay fotos en '$FotosSource'. Nada que procesar."
    exit 0
}

$nuevas = $fotos | Where-Object { -not $metadata.ContainsKey($_.Name) }

if ($nuevas.Count -eq 0) {
    Write-Success "Todas las fotos ya tienen metadata. Nada que preguntar."
    exit 0
}

Write-Step "Fotos nuevas sin metadata: $($nuevas.Count)"
Write-Host ""

# ===== Preguntar por cada foto nueva =====
$fechaHoy = Get-Date -Format "yyyy-MM-dd"

foreach ($foto in $nuevas) {
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "  Foto: $($foto.Name)" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host ""

    # --- Autor ---
    Write-Host "Autor (Enter para 'Anonimo'): " -NoNewline
    $autor = Read-Host
    if ([string]::IsNullOrWhiteSpace($autor)) {
        $autor = "Anónimo"
    }

    # --- Categoria ---
    Write-Host ""
    Write-Host "Categorias disponibles:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $Categorias.Count; $i++) {
        Write-Host "  [$($i + 1)] $($Categorias[$i])"
    }
    Write-Host "  [Enter] sin-categoria (default)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Elige una categoria (numero o Enter): " -NoNewline
    $catInput = Read-Host

    $categoria = "sin-categoria"
    if (-not [string]::IsNullOrWhiteSpace($catInput)) {
        $idx = 0
        if ([int]::TryParse($catInput, [ref]$idx) -and $idx -ge 1 -and $idx -le $Categorias.Count) {
            $categoria = $Categorias[$idx - 1]
        } else {
            Write-Warn "Opcion invalida. Usando 'sin-categoria'."
        }
    }

    # --- Fecha ---
    Write-Host ""
    Write-Host "Fecha (YYYY-MM-DD, Enter para hoy: $fechaHoy): " -NoNewline
    $fecha = Read-Host
    if ([string]::IsNullOrWhiteSpace($fecha)) {
        $fecha = $fechaHoy
    }

    # --- Tags ---
    Write-Host ""
    Write-Host "Tags (separados por coma, Enter para ninguno): " -NoNewline
    $tagsInput = Read-Host

    $tags = @()
    if (-not [string]::IsNullOrWhiteSpace($tagsInput)) {
        $tags = $tagsInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    }

    # --- Guardar en el metadata ---
    $metadata[$foto.Name] = [PSCustomObject]@{
        author   = $autor
        category = $categoria
        date     = $fecha
        tags     = $tags
    }

    Write-Host ""
    Write-Success "Metadata de '$($foto.Name)' guardada."
    Write-Host ""
}

# ===== Guardar el metadata.json =====
$metadataJson = $metadata | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText(
    (Join-Path (Get-Location).Path $MetadataFile),
    $metadataJson,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host ""
Write-Success "Metadata guardada en '$MetadataFile'."
Write-Success "Total de entradas: $($metadata.Count)"
Write-Host ""