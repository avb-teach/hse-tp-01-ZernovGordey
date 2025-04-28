#!/bin/bash

# Функция для вывода справки
usage() {
    echo "Использование: $0 [--max_depth N] ИСТОЧНИК НАЗНАЧЕНИЕ"
    echo "Пример:"
    echo "  $0 /home/input_dir /home/output_dir"
    echo "  $0 /home/input_dir /home/output_dir --max_depth 2"
    exit 1
}

# Проверка минимального количества аргументов
if [ $# -lt 2 ]; then
    usage
fi

# Инициализация переменных
max_depth=-1  # -1 означает неограниченную глубину
input_dir=""
output_dir_dir=""

# Обработка аргументов командной строки
if [ "$3" == "--max_depth" ]; then
    if [ $# -ne 4 ]; then
        echo "Ошибка: для --max_depth требуется указать значение"
        usage
    fi
    
    if ! [[ "$4" =~ ^[0-9]+$ ]]; then
        echo "Ошибка: значение глубины должно быть положительным числом"
        exit 1
    fi
    
    max_depth=$4
    input_dir=$1
    output_dir_dir=$2
else
    if [ $# -ne 2 ]; then
        usage
    fi
    input_dir=$1
    output_dir_dir=$2
fi

# Проверка существования исходной директории
if [ ! -d "$input_dir" ]; then
    echo "Ошибка: исходная директория '$input_dir' не существует"
    exit 1
fi

# Создание целевой директории, если её нет
mkdir -p "$output_dir_dir"

# Функция для генерации уникального имени файла
generate_unique_name() {
    local base="$1"
    local name="$2"
    local ext="$3"
    local counter=1
    
    while [[ -e "$base/$name$counter.$ext" ]]; do
        ((counter++))
    done
    
    echo "$name$counter.$ext"
}

# Основная функция копирования файлов
copy_files() {
    local current_dir="$1"
    local current_depth="$2"
    
    # Проверка ограничения глубины
    if [ $max_depth -ne -1 ] && [ $current_depth -gt $max_depth ]; then
        return
    fi
    
    # Обработка всех элементов в директории
    for item in "$current_dir"/*; do
        if [ -f "$item" ]; then
            # Обработка файла
            filename=$(basename "$item")
            name="${filename%.*}"
            ext="${filename##*.}"
            dest_path="$output_dir_dir/$filename"
            
            # Обработка конфликта имен
            if [ -e "$dest_path" ]; then
                new_name=$(generate_unique_name "$output_dir_dir" "$name" "$ext")
                dest_path="$output_dir_dir/$new_name"
                echo "Переименование: '$filename' -> '$new_name' (конфликт имен)"
            fi
            
            # Копирование файла
            if ! cp "$item" "$dest_path"; then
                echo "Ошибка: не удалось скопировать '$item'"
            fi
            
        elif [ -d "$item" ]; then
            # Рекурсивный вызов для поддиректории
            copy_files "$item" $((current_depth + 1))
        fi
    done
}

# Запуск процесса копирования
echo "Начало копирования из '$input_dir' в '$output_dir_dir'"
if [ $max_depth -ne -1 ]; then
    echo "Ограничение глубины: $max_depth"
fi

copy_files "$input_dir" 1