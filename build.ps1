# Скрипт сборки проекта (PowerShell)
# Создает директорию build с двумя каталогами:
# - .cursor: содержит папку commands со всем содержимым
# - .pldf: содержит все содержимое .pldf кроме директории commands

$ErrorActionPreference = "Stop"

# Определяем корневую директорию проекта
$ProjectRoot = $PSScriptRoot
$BuildDir = Join-Path $ProjectRoot "build"
$CursorDir = Join-Path $BuildDir ".cursor"
$PldfBuildDir = Join-Path $BuildDir ".pldf"
$CommandsSource = Join-Path $ProjectRoot "templates\commands"

# Проверяем существование папки commands
if (-not (Test-Path $CommandsSource -PathType Container)) {
    Write-Error "Ошибка: директория commands не найдена: $CommandsSource"
    exit 1
}

# Удаляем старую директорию build, если она существует
if (Test-Path $BuildDir -PathType Container) {
    Write-Host "Удаление старой директории build..."
    Remove-Item -Path $BuildDir -Recurse -Force
}

# Создаем директории
Write-Host "Создание директорий..."
New-Item -ItemType Directory -Path $CursorDir -Force | Out-Null
New-Item -ItemType Directory -Path $PldfBuildDir -Force | Out-Null

# Копируем папку commands в .cursor
Write-Host "Копирование commands в build\.cursor..."
Copy-Item -Path $CommandsSource -Destination (Join-Path $CursorDir "commands") -Recurse -Force

# Копируем все содержимое из корня проекта в build/.pldf, исключая templates/commands
Write-Host "Копирование содержимого в build\.pldf (исключая templates\commands)..."

# Копируем templates (без commands)
$TemplatesDir = Join-Path $ProjectRoot "templates"
if (Test-Path $TemplatesDir -PathType Container) {
    $TemplatesBuildDir = Join-Path $PldfBuildDir "templates"
    if (-not (Test-Path $TemplatesBuildDir -PathType Container)) {
        New-Item -ItemType Directory -Path $TemplatesBuildDir -Force | Out-Null
    }
    
    Get-ChildItem -Path $TemplatesDir -Force | ForEach-Object {
        $templateItem = $_
        if ($templateItem.Name -ne "commands") {
            Copy-Item -Path $templateItem.FullName -Destination $TemplatesBuildDir -Recurse -Force
        }
    }
}

# Копируем scripts, если существует
$ScriptsDir = Join-Path $ProjectRoot "scripts"
if (Test-Path $ScriptsDir -PathType Container) {
    Copy-Item -Path $ScriptsDir -Destination $PldfBuildDir -Recurse -Force
}

# Копируем hints, если существует
$HintsDir = Join-Path $ProjectRoot "hints"
if (Test-Path $HintsDir -PathType Container) {
    Copy-Item -Path $HintsDir -Destination $PldfBuildDir -Recurse -Force
}

# Копируем memory/progress.json, если существует
$MemoryDir = Join-Path $ProjectRoot "memory"
$ProgressJson = Join-Path $MemoryDir "progress.json"
if (Test-Path $ProgressJson -PathType Leaf) {
    $MemoryBuildDir = Join-Path $PldfBuildDir "memory"
    if (-not (Test-Path $MemoryBuildDir -PathType Container)) {
        New-Item -ItemType Directory -Path $MemoryBuildDir -Force | Out-Null
    }
    Copy-Item -Path $ProgressJson -Destination $MemoryBuildDir -Force
}

Write-Host "Сборка завершена успешно!"
Write-Host "Результат:"
Write-Host "  - build\.cursor\commands\ - команды для Cursor"
Write-Host "  - build\.pldf\ - содержимое .pldf без templates\commands"

