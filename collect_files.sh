#!/bin/bash

# Функция для вывода справки
usage() {
    echo "Использование: $0 [--max_depth N] ИСТОЧНИК НАЗНАЧЕНИЕ"
    echo "Пример: $0 /home/input_dir /home/output_dir"
    echo "        $0 --max_depth 3 /home/input_dir /home/output_dir"
    exit 1
}


# Парсинг аргументов
max_depth=-1  # -1 означает без ограничений
input_dir=""
output_dir=""

if [ "$#" -eq 4 ]; then
    input_dir=$1
    output_dir=$2
    max_depth=$4
else
    input_dir=$1
    output_dir=$2
fi

# Функция для копирования файлов с учетом глубины
copy_files() {
    local src="$3"
    local current_depth="$4"
    
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