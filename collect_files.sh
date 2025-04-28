#!/bin/bash

# Проверка количества аргументов
if [ "$#" -ne 2 ]; then
    echo "Ошибка: необходимо указать 2 параметра - входную и выходную директории"
    echo "Использование: $0 /путь/к/входной/директории /путь/к/выходной/директории"
    exit 1
fi

input_dir="$1"
output_dir="$2"

# Проверка существования входной директории
if [ ! -d "$input_dir" ]; then
    echo "Ошибка: входная директория '$input_dir' не существует"
    exit 1
fi

# Создание выходной директории, если её нет
mkdir -p "$output_dir"

# Функция для создания уникального имени файла
generate_unique_name() {
    local base="$1"
    local name="$2"
    local ext="$3"
    local counter=1
    local new_name="${name}.${ext}"

    while [ -e "${base}/${new_name}" ]; do
        new_name="${name}_${counter}.${ext}"
        counter=$((counter + 1))
    done

    echo "$new_name"
}

# Функция для копирования файлов
copy_files() {
    local current_dir="$1"

    # Обработка всех элементов в текущей директории
    for item in "$current_dir"/*; do
        if [ -f "$item" ]; then
            # Обработка файла
            filename=$(basename "$item")
            name="${filename%.*}"
            ext="${filename##*.}"
            dest_path="$output_dir/$filename"

            # Проверка на существование файла с таким же именем
            if [ -e "$dest_path" ]; then
                new_filename=$(generate_unique_name "$output_dir" "$name" "$ext")
                dest_path="$output_dir/$new_filename"
                echo "Файл '$filename' переименован в '$new_filename' (избежание конфликта)"
            fi

            # Копирование файла
            cp "$item" "$dest_path"

        elif [ -d "$item" ]; then
            # Рекурсивный вызов для поддиректории
            copy_files "$item"
        fi
    done
}

# Запуск процесса копирования
echo "Начало копирования файлов из '$input_dir' в '$output_dir'..."
copy_files "$input_dir"
echo "Копирование завершено. Все файлы находятся в '$output_dir'"