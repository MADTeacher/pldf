# Скрипт получения подсказки по этапу и категории ошибки
# Использование: .\get-hint.ps1 -Stage <этап> [-Category <категория>] [-ErrorKey <ключ_ошибки>] [-Json]

param(
    [Parameter(Mandatory=$true)]
    [string]$Stage,
    
    [Parameter(Mandatory=$false)]
    [string]$Category,
    
    [Parameter(Mandatory=$false)]
    [string]$ErrorKey,
    
    [Parameter(Mandatory=$false)]
    [switch]$Json
)

$ErrorActionPreference = "Stop"

# Валидация этапа
$ValidStages = @("concept", "design", "tech", "architecture", "plan", "implement", "review")
if ($ValidStages -notcontains $Stage) {
    $ErrorMsg = "Ошибка: недопустимый этап: $Stage"
    if ($Json) {
        @{success = $false; error = $ErrorMsg} | ConvertTo-Json -Compress | Write-Output
    } else {
        Write-Host $ErrorMsg -ForegroundColor Red
    }
    exit 1
}

# Определяем пути (скрипт находится в scripts/powershell/, нужно подняться на 1 уровень вверх)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$HintsFile = Join-Path $ProjectRoot "hints" "hints.json"
$ResourcesFile = Join-Path $ProjectRoot "hints" "resources.json"

# Проверяем существование файлов
if (-not (Test-Path $HintsFile)) {
    $ErrorMsg = "Файл подсказок не найден: $HintsFile"
    if ($Json) {
        @{success = $false; error = $ErrorMsg} | ConvertTo-Json -Compress | Write-Output
    } else {
        Write-Host "Ошибка: $ErrorMsg" -ForegroundColor Red
    }
    exit 1
}

# Загружаем подсказки
try {
    $Hints = Get-Content $HintsFile -Raw | ConvertFrom-Json
} catch {
    $ErrorMsg = "Ошибка при чтении файла подсказок: $_"
    if ($Json) {
        @{success = $false; error = $ErrorMsg} | ConvertTo-Json -Compress | Write-Output
    } else {
        Write-Host "Ошибка: $ErrorMsg" -ForegroundColor Red
    }
    exit 1
}

$Resources = @{}
if (Test-Path $ResourcesFile) {
    try {
        $Resources = Get-Content $ResourcesFile -Raw | ConvertFrom-Json
    } catch {
        # Игнорируем ошибки чтения resources.json
    }
}

# Ищем подсказку
$Hint = $null
$HintType = ""

# Проверяем существование структуры stages
if (-not $Hints.stages -or -not $Hints.stages.$Stage) {
    $ErrorMsg = "Этап '$Stage' не найден в структуре подсказок"
    if ($Json) {
        @{success = $false; error = $ErrorMsg} | ConvertTo-Json -Compress | Write-Output
    } else {
        Write-Host "Ошибка: $ErrorMsg" -ForegroundColor Red
    }
    exit 1
}

# Если указан ErrorKey, ищем конкретную подсказку
if ($ErrorKey) {
    $StageHints = $Hints.stages.$Stage
    if ($StageHints.validationHints -and $StageHints.validationHints.$ErrorKey) {
        $Hint = $StageHints.validationHints.$ErrorKey
        $HintType = "validation"
    }
}

# Если не найдено по ErrorKey, ищем по категории
if (-not $Hint) {
    if ($Category) {
        $ValidationHints = $Hints.stages.$Stage.validationHints
        if ($ValidationHints) {
            # Ищем по ключевым словам в message или ключах
            $HintKey = $null
            foreach ($key in $ValidationHints.PSObject.Properties.Name) {
                $hintObj = $ValidationHints.$key
                if ($hintObj.message -and $hintObj.message.ToLower().Contains($Category.ToLower())) {
                    $HintKey = $key
                    break
                }
            }
            if (-not $HintKey) {
                foreach ($key in $ValidationHints.PSObject.Properties.Name) {
                    if ($key.ToLower().Contains($Category.ToLower())) {
                        $HintKey = $key
                        break
                    }
                }
            }
            if ($HintKey) {
                $Hint = $ValidationHints.$HintKey
                $HintType = "validation"
            }
        }
    }
}

# Если все еще не найдено, берем первую доступную подсказку для этапа
if (-not $Hint) {
    $ValidationHints = $Hints.stages.$Stage.validationHints
    if ($ValidationHints) {
        $FirstKey = ($ValidationHints.PSObject.Properties.Name | Select-Object -First 1)
        if ($FirstKey) {
            $Hint = $ValidationHints.$FirstKey
            $HintType = "validation"
        }
    }
}

# Если не найдено, пробуем общие подсказки
if (-not $Hint) {
    if ($Hints.generalHints -and $Hints.generalHints.stuck) {
        $Hint = $Hints.generalHints.stuck
        $HintType = "general"
    }
}

# Формируем результат
if ($Hint) {
    $HintMessage = if ($Hint.message) { $Hint.message } else { "" }
    $HintText = $Hint.hint
    $ResourceIds = if ($Hint.resources) { $Hint.resources } else { @() }
    
    # Получаем ресурсы
    $ResourcesArray = @()
    if ($ResourceIds -and ($ResourceIds -is [Array]) -and $ResourceIds.Count -gt 0) {
        foreach ($resourceId in $ResourceIds) {
            if ($Resources.resources -and $Resources.resources.$resourceId) {
                $ResourcesArray += $Resources.resources.$resourceId
            }
        }
    }
    
    if ($Json) {
        $result = @{
            success = $true
            stage = $Stage
            category = if ($Category) { $Category } else { "" }
            hintType = $HintType
            hint = @{
                message = $HintMessage
                hint = $HintText
                resources = $ResourcesArray
            }
        }
        $result | ConvertTo-Json -Depth 10 -Compress | Write-Output
    } else {
        Write-Host "Подсказка для этапа '$Stage'" -ForegroundColor Cyan
        if ($HintMessage) {
            Write-Host "Ошибка: $HintMessage" -ForegroundColor Yellow
        }
        Write-Host "Подсказка: $HintText" -ForegroundColor Green
        if ($ResourcesArray.Count -gt 0) {
            Write-Host "`nДополнительные ресурсы:" -ForegroundColor Cyan
            foreach ($resource in $ResourcesArray) {
                Write-Host "  - $($resource.title): $($resource.url)"
            }
        }
    }
    exit 0
} else {
    $ErrorMsg = "Подсказка не найдена для этапа '$Stage'"
    if ($Json) {
        @{success = $false; error = $ErrorMsg} | ConvertTo-Json -Compress | Write-Output
    } else {
        Write-Host $ErrorMsg -ForegroundColor Red
    }
    exit 1
}

