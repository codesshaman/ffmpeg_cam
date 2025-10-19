#!/bin/bash

# Скрипт для автоматического распознавания и записи видео с USB-камер (/dev/videoN)
# Требования: ffmpeg, v4l-utils (установите: sudo apt install ffmpeg v4l-utils)
# Использование: ./record_camera.sh [duration] [output_file] [device]
#   duration: время записи в секундах (по умолчанию 60)
#   output_file: имя выходного файла (по умолчанию output.mp4)
#   device: конкретное устройство, e.g. /dev/video0 (по умолчанию автоопределение первого)

set -e  # Остановка при ошибке

# Функция для обнаружения устройств камер
detect_cameras() {
    echo "Обнаружение устройств /dev/video*..."
    local devices=()
    for dev in /dev/video*; do
        if [[ -c "$dev" ]]; then
            # Проверяем, что это UVC-устройство (камера)
            if v4l2-ctl --device="$dev" --all > /dev/null 2>&1; then
                devices+=("$dev")
                echo "Найдено устройство: $dev"
            fi
        fi
    done
    echo "Всего найдено камер: ${#devices[@]}"
    echo "${devices[@]}"
}

# Основная функция записи
record_video() {
    local device="$1"
    local duration="$2"
    local output="$3"

    echo "Запись с устройства: $device"
    echo "Длительность: $duration сек"
    echo "Выходной файл: $output"

    # Команда FFmpeg для записи MJPEG/H.264 с /dev/videoN
    # -f v4l2: формат Video4Linux2
    # -framerate 30: 30 FPS (адаптируйте под камеру)
    # -video_size 640x480: разрешение (измените по необходимости)
    # -t $duration: время записи
    ffmpeg -f v4l2 -framerate 30 -video_size 640x480 -i "$device" \
           -c:v libx264 -preset ultrafast -crf 23 \
           -t "$duration" "$output" -y  # -y перезаписать файл

    echo "Запись завершена: $output"
}

# Парсинг аргументов
DURATION=${1:-60}
OUTPUT=${2:-"output_$(date +%Y%m%d_%H%M%S).mp4"}
DEVICE=${3:-""}

# Если устройство не указано — автоопределение первого
if [[ -z "$DEVICE" ]]; then
    local available_devices=($(detect_cameras))
    if [[ ${#available_devices[@]} -eq 0 ]]; then
        echo "Ошибка: Камеры не найдены!"
        exit 1
    fi
    DEVICE="${available_devices[0]}"
    echo "Автоматически выбранное устройство: $DEVICE"
fi

# Проверка существования устройства
if [[ ! -c "$DEVICE" ]]; then
    echo "Ошибка: Устройство $DEVICE не существует или недоступно!"
    exit 1
fi

# Запуск записи
record_video "$DEVICE" "$DURATION" "$OUTPUT"