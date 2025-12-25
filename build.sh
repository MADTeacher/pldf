#!/bin/bash

# Скрипт сборки проекта
# Создает директорию build с двумя каталогами:
# - .cursor: содержит папку commands со всем содержимым
# - .pldf: содержит все содержимое .pldf кроме директории commands

set -e

# Определяем корневую директорию проекта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_ROOT/build"
CURSOR_DIR="$BUILD_DIR/.cursor"
PLDF_BUILD_DIR="$BUILD_DIR/.pldf"
COMMANDS_SOURCE="$PROJECT_ROOT/templates/commands"

# Проверяем существование папки commands
if [ ! -d "$COMMANDS_SOURCE" ]; then
    echo "Ошибка: директория commands не найдена: $COMMANDS_SOURCE" >&2
    exit 1
fi

# Удаляем старую директорию build, если она существует
if [ -d "$BUILD_DIR" ]; then
    echo "Удаление старой директории build..."
    rm -rf "$BUILD_DIR"
fi

# Создаем директории
echo "Создание директорий..."
mkdir -p "$CURSOR_DIR"
mkdir -p "$PLDF_BUILD_DIR"

# Копируем папку commands в .cursor
echo "Копирование commands в build/.cursor..."
cp -r "$COMMANDS_SOURCE" "$CURSOR_DIR/commands"

# Копируем все содержимое из корня проекта в build/.pldf, исключая templates/commands
echo "Копирование содержимого в build/.pldf (исключая templates/commands)..."
cd "$PROJECT_ROOT"

# Копируем templates (без commands), scripts, hints и memory/progress.json
if [ -d "templates" ]; then
    mkdir -p "$PLDF_BUILD_DIR/templates"
    for template_item in templates/*; do
        # Проверяем, что template_item существует
        [ -e "$template_item" ] || continue
        template_name=$(basename "$template_item")
        if [ "$template_name" != "commands" ]; then
            cp -r "$template_item" "$PLDF_BUILD_DIR/templates/"
        fi
    done
fi

# Копируем scripts, если существует
if [ -d "scripts" ]; then
    cp -r "scripts" "$PLDF_BUILD_DIR/"
fi

# Копируем hints, если существует
if [ -d "hints" ]; then
    cp -r "hints" "$PLDF_BUILD_DIR/"
fi

# Копируем memory/progress.json, если существует
if [ -f "memory/progress.json" ]; then
    mkdir -p "$PLDF_BUILD_DIR/memory"
    cp "memory/progress.json" "$PLDF_BUILD_DIR/memory/"
fi

echo "Сборка завершена успешно!"
echo "Результат:"
echo "  - build/.cursor/commands/ - команды для Cursor"
echo "  - build/.pldf/ - содержимое .pldf без templates/commands"

