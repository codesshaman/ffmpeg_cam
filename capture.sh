#!/bin/bash

DEV_0="/dev/video0"
DEV_1="/dev/video1"
SIZE="640x480"

# Функция для ожидания подключения съёмного устройства
# Возвращает путь к первому найденному устройству через глобальную переменную DEVICE_PATH
wait_for_removable_device() {
    DEVICE_PATH=""  # Сбрасываем переменную на всякий случай

    while true; do
        USER=$(whoami)
        FOUND=0
        FIRST_MOUNT=""

        # Проверяем /media/<user>/
        if [ -d "/media/$USER" ]; then
            for dir in "/media/$USER"/*; do
                if [ -d "$dir" ]; then
                    if [ $FOUND -eq 0 ]; then
                        FIRST_MOUNT="$dir"
                        FOUND=1
                    fi
                fi
            done
        fi

        # Проверяем /run/media/<user>/
        if [ -d "/run/media/$USER" ]; then
            for dir in "/run/media/$USER"/*; do
                if [ -d "$dir" ]; then
                    if [ $FOUND -eq 0 ]; then
                        FIRST_MOUNT="$dir"
                        FOUND=1
                    fi
                fi
            done
        fi

        if [ $FOUND -eq 1 ]; then
            DEVICE_PATH="$FIRST_MOUNT"
            echo "Съёмное устройство подключено: $DEVICE_PATH"
            return 0  # Успешно найдено
        else
            sleep 5
        fi
    done
}

# Функция для ожидания подключения видеоустройства /dev/video0
# Устанавливает в глобальную переменную VIDEO_DEVICE_0 путь к устройству при успехе
wait_for_video_device_0() {
    while true; do
        if [ -c "$DEV_0" ]; then
            echo "Видеоустройство подключено: $DEV_0"
            return 0
        else
            echo "Ожидание подключения видеоустройства $DEV_0..."
            sleep 5
        fi
    done
}

# Функция для ожидания подключения видеоустройства /dev/video1
# Устанавливает в глобальную переменную VIDEO_DEVICE_1 путь к устройству при успехе
wait_for_video_device_1() {
    while true; do
        if [ -c "$DEV_1" ]; then
            echo "Видеоустройство подключено: $DEV_1"
            return 0
        else
            echo "Ожидание подключения видеоустройства $DEV_1..."
            sleep 5
        fi
    done
}

# Проверяем подключенные девайсы
wait_for_removable_device
# Теперь переменная $DEVICE_PATH содержит путь к устройству

# Проверяем подключение первой камеры
wait_for_video_device_0
# Теперь $VIDEO_DEVICE_0 содержит путь, если устройство найдено

# Проверяем подключение второй камеры
wait_for_video_device_1
# Теперь $VIDEO_DEVICE_1 содержит путь, если устройство найдено

# Проверяем подключение второй камеры
# wait_for_video_device_1
# Теперь $VIDEO_DEVICE_1 содержит путь, если устройство найдено

record_video_from_device_0() {
    # Проверяем, что обе переменные заданы
    if [ -z "$DEV_0" ] || [ -z "$DEVICE_PATH" ]; then
        echo "Ошибка: $DEV_0 или $DEVICE_PATH не определены!" >&2
        return 1
    fi

    # Создаём имя файла: dev0_дд.мм.гг_чч:мм:сс.mp4
    TIMESTAMP=$(date +"%d.%m.%y_%H:%M:%S")
    OUTPUT_FILE="$DEVICE_PATH/dev0_${TIMESTAMP}.mp4"

    echo "Начинаем запись видео в: $OUTPUT_FILE"
    echo "Параметры: , 30 FPS, H.264"

    # Запуск ffmpeg
    ffmpeg -f v4l2 \
           -framerate 30 \
           -video_size $SIZE \
           -i "$DEV_0" \
           -c:v libx264 \
           -preset medium \
           -crf 23 \
           "$OUTPUT_FILE"

    if [ $? -eq 0 ]; then
        echo "Запись завершена: $OUTPUT_FILE"
    else
        echo "Ошибка при записи видео!" >&2
        return 1
    fi
}

record_video_from_device_0
