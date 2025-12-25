#!/bin/bash

# Скрипт получения подсказки по этапу и категории ошибки
# Использование: ./get-hint.sh -Stage <этап> [-Category <категория>] [-ErrorKey <ключ_ошибки>] [-Json]

set -e

# Парсинг аргументов
STAGE=""
CATEGORY=""
ERROR_KEY=""
JSON=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -Stage)
            STAGE="$2"
            shift 2
            ;;
        -Category)
            CATEGORY="$2"
            shift 2
            ;;
        -ErrorKey)
            ERROR_KEY="$2"
            shift 2
            ;;
        -Json)
            JSON=true
            shift
            ;;
        *)
            echo "Неизвестный параметр: $1" >&2
            exit 1
            ;;
    esac
done

# Проверка обязательных параметров
if [ -z "$STAGE" ]; then
    echo "Ошибка: требуется параметр -Stage" >&2
    exit 1
fi

# Валидация этапа
VALID_STAGES=("concept" "design" "tech" "architecture" "plan" "implement" "review")
VALID_STAGE=false
for valid_stage in "${VALID_STAGES[@]}"; do
    if [ "$STAGE" = "$valid_stage" ]; then
        VALID_STAGE=true
        break
    fi
done

if [ "$VALID_STAGE" = false ]; then
    echo "Ошибка: недопустимый этап: $STAGE" >&2
    exit 1
fi

# Определяем пути (скрипт находится в scripts/bash/, нужно подняться на 1 уровень вверх)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HINTS_FILE="$PROJECT_ROOT/hints/hints.json"
RESOURCES_FILE="$PROJECT_ROOT/hints/resources.json"

# Проверяем существование файлов
if [ ! -f "$HINTS_FILE" ]; then
    ERROR_MSG="Файл подсказок не найден: $HINTS_FILE"
    if [ "$JSON" = true ]; then
        jq -n --arg error "$ERROR_MSG" '{"success": false, "error": $error}'
    else
        echo "Ошибка: $ERROR_MSG" >&2
    fi
    exit 1
fi

# Проверяем наличие jq
if ! command -v jq &> /dev/null; then
    echo "Ошибка: jq не установлен. Установите jq для работы скрипта." >&2
    exit 1
fi

# Загружаем подсказки
HINTS=$(cat "$HINTS_FILE")
RESOURCES="{}"
if [ -f "$RESOURCES_FILE" ]; then
    RESOURCES=$(cat "$RESOURCES_FILE")
fi

# Функция для получения ресурсов
get_resources() {
    local resource_ids="$1"
    local resources_json="$2"
    
    echo "$resource_ids" | jq -r '.[]' | while read -r resource_id; do
        echo "$resources_json" | jq -r --arg id "$resource_id" '.resources[$id] // empty'
    done
}

# Ищем подсказку
HINT=""
HINT_TYPE=""

# Если указан ErrorKey, ищем конкретную подсказку
if [ -n "$ERROR_KEY" ]; then
    HINT=$(echo "$HINTS" | jq -r --arg stage "$STAGE" --arg key "$ERROR_KEY" '.stages[$stage].validationHints[$key] // empty')
    if [ -n "$HINT" ] && [ "$HINT" != "null" ]; then
        HINT_TYPE="validation"
    fi
fi

# Если не найдено по ErrorKey, ищем по категории
if [ -z "$HINT" ] || [ "$HINT" = "null" ]; then
    if [ -n "$CATEGORY" ]; then
        # Ищем подсказку, которая соответствует категории
        VALIDATION_HINTS=$(echo "$HINTS" | jq -r --arg stage "$STAGE" '.stages[$stage].validationHints // {}')
        if [ "$VALIDATION_HINTS" != "{}" ] && [ "$VALIDATION_HINTS" != "null" ]; then
            # Ищем по ключевым словам в message или ключах
            HINT_KEY=$(echo "$VALIDATION_HINTS" | jq -r --arg cat "$CATEGORY" 'to_entries[] | select(.value.message | ascii_downcase | contains($cat | ascii_downcase)) | .key' | head -n 1)
            if [ -z "$HINT_KEY" ]; then
                HINT_KEY=$(echo "$VALIDATION_HINTS" | jq -r --arg cat "$CATEGORY" 'to_entries[] | select(.key | ascii_downcase | contains($cat | ascii_downcase)) | .key' | head -n 1)
            fi
            if [ -n "$HINT_KEY" ]; then
                HINT=$(echo "$VALIDATION_HINTS" | jq -r --arg key "$HINT_KEY" '.[$key]')
                HINT_TYPE="validation"
            fi
        fi
    fi
fi

# Если все еще не найдено, берем первую доступную подсказку для этапа
if [ -z "$HINT" ] || [ "$HINT" = "null" ]; then
    VALIDATION_HINTS=$(echo "$HINTS" | jq -r --arg stage "$STAGE" '.stages[$stage].validationHints // {}')
    if [ "$VALIDATION_HINTS" != "{}" ] && [ "$VALIDATION_HINTS" != "null" ]; then
        FIRST_KEY=$(echo "$VALIDATION_HINTS" | jq -r 'keys[0]')
        if [ -n "$FIRST_KEY" ]; then
            HINT=$(echo "$VALIDATION_HINTS" | jq -r --arg key "$FIRST_KEY" '.[$key]')
            HINT_TYPE="validation"
        fi
    fi
fi

# Если не найдено, пробуем общие подсказки
if [ -z "$HINT" ] || [ "$HINT" = "null" ]; then
    HINT=$(echo "$HINTS" | jq -r '.generalHints.stuck // empty')
    if [ -n "$HINT" ] && [ "$HINT" != "null" ]; then
        HINT_TYPE="general"
    fi
fi

# Формируем результат
if [ -n "$HINT" ] && [ "$HINT" != "null" ]; then
    HINT_MESSAGE=$(echo "$HINT" | jq -r '.message // ""')
    HINT_TEXT=$(echo "$HINT" | jq -r '.hint')
    RESOURCE_IDS=$(echo "$HINT" | jq -r '.resources // []')
    
    # Получаем ресурсы
    RESOURCES_ARRAY="[]"
    if [ "$RESOURCE_IDS" != "[]" ] && [ "$RESOURCE_IDS" != "null" ]; then
        RESOURCES_ARRAY=$(echo "$RESOURCE_IDS" | jq -r '.[]' | while read -r resource_id; do
            echo "$RESOURCES" | jq -r --arg id "$resource_id" '.resources[$id] // empty'
        done | jq -s '.')
    fi
    
    if [ "$JSON" = true ]; then
        jq -n \
            --argjson success true \
            --arg stage "$STAGE" \
            --arg category "$CATEGORY" \
            --arg hintType "$HINT_TYPE" \
            --arg message "$HINT_MESSAGE" \
            --arg hint "$HINT_TEXT" \
            --argjson resources "$RESOURCES_ARRAY" \
            '{
                "success": $success,
                "stage": $stage,
                "category": $category,
                "hintType": $hintType,
                "hint": {
                    "message": $message,
                    "hint": $hint,
                    "resources": $resources
                }
            }'
    else
        echo -e "\033[36mПодсказка для этапа '$STAGE'\033[0m"
        if [ -n "$HINT_MESSAGE" ]; then
            echo -e "\033[33mОшибка: $HINT_MESSAGE\033[0m"
        fi
        echo -e "\033[32mПодсказка: $HINT_TEXT\033[0m"
        if [ "$RESOURCES_ARRAY" != "[]" ] && [ "$RESOURCES_ARRAY" != "null" ]; then
            echo -e "\n\033[36mДополнительные ресурсы:\033[0m"
            echo "$RESOURCES_ARRAY" | jq -r '.[] | "  - \(.title): \(.url)"'
        fi
    fi
    exit 0
else
    ERROR_MSG="Подсказка не найдена для этапа '$STAGE'"
    if [ "$JSON" = true ]; then
        jq -n --arg error "$ERROR_MSG" '{"success": false, "error": $error}'
    else
        echo -e "\033[31m$ERROR_MSG\033[0m" >&2
    fi
    exit 1
fi

