# add_missing_dtos.ps1
param()

# Basis-Pfad zur neuen Lib
$base = Join-Path (Get-Location) 'new_lib2'

# DTO-Verzeichnis
$dtoDir = Join-Path $base 'data\dtoS'

# Fehlende DTO-Dateien
$dtoFiles = @(
  'affiliate_offer_dto.dart',
  'tenant_dto.dart',
  'training_plan_dto.dart'
)

Write-Host "Erstelle fehlende DTO-Stubs in '$dtoDir'…"

foreach ($f in $dtoFiles) {
    $path = Join-Path $dtoDir $f
    if (-Not (Test-Path $path)) {
        New-Item -ItemType File -Path $path -Force | Out-Null
        Write-Host "  + $f"
    } else {
        Write-Host "  * $f existiert bereits"
    }
}

Write-Host "Fertig!"
