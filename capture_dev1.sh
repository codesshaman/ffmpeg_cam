#!/bin/bash

DEV_1="/dev/video2"
SIZE="640x480"
TIME="00:10:00"

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

# Функция для ожидания подключения видеоустройства /dev/video1
# Устанавливает в глобальную переменную VIDEO_DEVICE_1 путь к устройству при успехе
wait_for_video_device() {
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

# Проверяем подключение второй камеры
wait_for_video_device
# Теперь $VIDEO_DEVICE_1 содержит путь, если устройство найдено

# Проверяем подключение второй камеры
# wait_for_video_device_1
# Теперь $VIDEO_DEVICE_1 содержит путь, если устройство найдено

record_video_from_device() {
    # Проверяем переменные
    if [ -z "$DEV_1" ] || [ -z "$DEVICE_PATH" ]; then
        echo "Ошибка: DEV_1 или DEVICE_PATH не определены!" >&2
        return 1
    fi

    # Проверяем, существует ли папка
    if [ ! -d "$DEVICE_PATH" ]; then
        echo "Ошибка: Папка $DEVICE_PATH не существует!" >&2
        return 1
    fi

    # Проверяем ffmpeg
    if ! command -v ffmpeg >/dev/null 2>&1; then
        echo "Ошибка: ffmpeg не установлен!" >&2
        return 1
    fi

    # Маска времени: дд.мм.гг_чч:мм:сс
    MASK="%d.%m.%y_%H-%M-%S"

    echo "Запуск циклической записи: каждые 10 минут → новый файл"
    echo "Устройство: $DEV_1 → $DEVICE_PATH/dev1_*.mp4"
    echo "Нажмите Ctrl+C для остановки"

    # Ловим Ctrl+C для graceful выхода
    trap 'echo -e "\nОстановлено пользователем."; return 0' INT TERM

    # Бесконечный цикл
    while true; do
        TIMESTAMP=$(date +"$MASK")
        OUTPUT_FILE="$DEVICE_PATH/dev1_${TIMESTAMP}.mp4"

        echo -e "\nНачинаем запись: $OUTPUT_FILE ($TIME минут)"
        echo "Параметры: 30 FPS, H.264, CRF 23"

        # Запускаем ffmpeg на 10 минут
        ffmpeg -f v4l2 \
               -framerate 30 \
               -video_size "$SIZE" \
               -i "$DEV_1" \
               -c:v libx264 \
               -preset medium \
               -crf 23 \
               -t "$TIME" \
               -y \
               "$OUTPUT_FILE" \
               > /dev/null 2>&1

        FF_EXIT=$?
        if [ $FF_EXIT -eq 0 ]; then
            echo "Запись завершена: $OUTPUT_FILE"
        else
            echo "Ошибка ffmpeg (код: $FF_EXIT) в файле: $OUTPUT_FILE" >&2
            # Можно добавить sleep или break при критических ошибках
        fi

        # Пауза перед следующей записью (на случай, если ffmpeg завершился раньше)
        sleep 1
    done
}

record_video_from_device
