#!/bin/bash

# Функция для вывода справки
usage() {
    echo "Использование: $0 [--max_depth N] ИСТОЧНИК НАЗНАЧЕНИЕ"
    echo "Пример: $0 /home/input_dir /home/output_dir"
    echo "        $0 --max_depth 3 /home/input_dir /home/output_dir"
    exit 1
}

# Проверка количества аргументов
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    usage
fi

# Парсинг аргументов
max_depth=-1  # -1 означает без ограничений
input_dir=""
output_dir=""

if [ "$1" == "--max_depth" ]; then
    if [ $# -ne 4 ]; then
        usage
    fi
    if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Ошибка: --max_depth требует числового значения"
        exit 1
    fi
    max_depth=$2
    input_dir=$3
    output_dir=$4
else
    input_dir=$1
    output_dir=$2
fi

# Проверка существования входной директории
if [ ! -d "$input_dir" ]; then
    echo "Ошибка: входная директория не существует - $input_dir"
    exit 1
fi

# Создание выходной директории
mkdir -p "$output_dir"

# Функция для копирования файлов с учетом глубины
copy_files() {
    local src="$1"
    local current_depth="$2"
    
    # Проверка ограничения глубины
    if [ $max_depth -ne -1 ] && [ $current_depth -gt $max_depth ]; then
        return
    fi
    
    # Обработка всех элементов в директории
    for item in "$src"/*; do
        if [ -f "$item" ]; then
            # Обработка файла
            filename=$(basename "$item")
            name="${filename%.*}"
            ext="${filename##*.}"
            counter=1
            dest_path="$output_dir/$filename"
            
            # Генерация уникального имени при конфликте
            while [ -e "$dest_path" ]; do
                dest_path="$output_dir/${name}_${counter}.${ext}"
                ((counter++))
            done
            
            cp "$item" "$dest_path"
            
        elif [ -d "$item" ]; then
            # Рекурсивная обработка поддиректории
            copy_files "$item" $((current_depth + 1))
        fi
    done
}

# Начало копирования с глубины 1
copy_files "$input_dir" 1