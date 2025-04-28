function parse_arguments() {
    local has_depth_param=false
    local depth_value=0
    
    # Анализ параметров командной строки
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --max_depth)
                if [[ $# -lt 2 ]]; then
                    show_error "Отсутствует значение для --max_depth"
                    exit 1
                fi
                if ! is_number "$2"; then
                    show_error "Значение глубины должно быть числом"
                    exit 1
                fi
                has_depth_param=true
                depth_value="$2"
                shift 2
                ;;
            *)
                if [[ -z "$source_dir" ]]; then
                    source_dir="$1"
                elif [[ -z "$target_dir" ]]; then
                    target_dir="$1"
                else
                    show_error "Неизвестный параметр: $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Проверка обязательных параметров
    if [[ -z "$source_dir" || -z "$target_dir" ]]; then
        echo "Использование: $0 [--max_depth N] ИСТОЧНИК НАЗНАЧЕНИЕ"
        exit 1
    fi

    # Возвращаем результаты через глобальные переменные
    max_depth=$depth_value
    use_depth_limit=$has_depth_param
}

# Функция для создания уникального имени файла
function generate_unique_name() {
    local base_path="$1"
    local original_name="$2"
    local counter=1
    
    # Разделяем имя файла и расширение
    local filename="${original_name%.*}"
    local extension="${original_name##*.}"
    
    # Если файл уже имеет числовой суффикс, извлекаем его
    if [[ "$filename" =~ ^(.*)_([0-9]+)$ ]]; then
        filename="${BASH_REMATCH[1]}"
        counter=$(( ${BASH_REMATCH[2]} + 1 ))
    fi
    
    # Генерируем новое имя пока не найдем свободное
    while [[ -e "${base_path}/${filename}_${counter}.${extension}" ]]; do
        ((counter++))
    done
    
    echo "${filename}_${counter}.${extension}"
}

# Основная функция обработки файлов
function process_files() {
    local current_dir="$1"
    local level="$2"
    
    # Проверка ограничения глубины
    if $use_depth_limit && [[ $level -gt $max_depth ]]; then
        echo "[ПРОПУСК] Достигнута максимальная глубина $max_depth в $current_dir"
        return
    fi
    
    echo "[ОБРАБОТКА] Сканируем $current_dir (уровень $level)"
    
    # Обработка всех элементов в директории
    for item in "$current_dir"/*; do
        if [[ -f "$item" ]]; then
            # Обработка файла
            local filename=$(basename "$item")
            local dest_path="$target_dir/$filename"
            
            if [[ -e "$dest_path" ]]; then
                # Генерация уникального имени при конфликте
                local new_name=$(generate_unique_name "$target_dir" "$filename")
                dest_path="$target_dir/$new_name"
                echo "[КОНФЛИКТ] Переименовываем $filename в $new_name"
            fi
            
            # Копирование файла
            if ! cp "$item" "$dest_path"; then
                show_error "Не удалось скопировать $item в $dest_path"
            else
                echo "[УСПЕХ] Скопирован $item -> $dest_path"
            fi
            
        elif [[ -d "$item" ]]; then
            # Рекурсивная обработка поддиректории
            process_files "$item" $((level + 1))
        fi
    done
}

# Главная точка входа
function main() {
    # Парсинг аргументов
    parse_arguments "$@"
    
    # Проверка существования исходной директории
    if [[ ! -d "$source_dir" ]]; then
        show_error "Исходная директория не существует: $source_dir"
        exit 1
    fi
    
    # Создание целевой директории при необходимости
    if [[ ! -d "$target_dir" ]]; then
        if ! mkdir -p "$target_dir"; then
            show_error "Не удалось создать целевую директорию: $target_dir"
            exit 1
        fi
        echo "[ИНИЦИАЛИЗАЦИЯ] Создана целевая директория: $target_dir"
    fi
    
    # Запуск обработки файлов
    echo "[НАЧАЛО РАБОТЫ] Перенос файлов из $source_dir в $target_dir"
    if $use_depth_limit; then
        echo "[ПАРАМЕТР] Ограничение глубины сканирования: $max_level"
    fi
    
    process_files "$source_dir" 1
    
    echo "[ЗАВЕРШЕНИЕ] Операция успешно выполнена"
    echo "[ИТОГ] Файлы сохранены в: $target_dir"
}

# Запуск главной функции
main "$@"