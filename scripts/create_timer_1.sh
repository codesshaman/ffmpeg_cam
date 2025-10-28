#!/bin/bash

# Путь к файлу
SERVICE_PATH="/etc/systemd/system/ffmpeg_capture_1.timer"

# Проверяем, существует ли файл
if [ -f "$SERVICE_PATH" ]; then
    echo "Файл $SERVICE_PATH уже существует."
else
    echo "Файл $SERVICE_PATH отсутствует. Создаём файл..."

    # Содержимое для файла
    SERVICE_CONTENT="[Unit]
Description=Capture ffmpeg video from camera 1

[Timer]
OnCalendar=*-*-* $TIME:00:00
Persistent=true

[Install]
WantedBy=timers.target"

    # Создаём файл под sudo и записываем содержимое
    echo "$SERVICE_CONTENT" | sudo tee "$SERVICE_PATH" > /dev/null
    
    # Устанавливаем корректные права доступа
    sudo chmod 644 "$SERVICE_PATH"
    echo "Файл $SERVICE_PATH успешно создан."

    # Перезапускаем systemd для применения изменений
    sudo systemctl daemon-reload
    sudo systemctl enable ffmpeg_capture_1.timer
    sudo systemctl start ffmpeg_capture_1.timer
    sudo systemctl status ffmpeg_capture_1.timer
    echo "Systemd перезагружен."
fi