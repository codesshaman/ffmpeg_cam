#!/bin/bash

# Сохраняем текущую директорию в переменную
CURRENT_DIR=$(pwd)

# Сохраняем текущего пользователя в переменную
CURRENT_USER=$(whoami)

# Путь к файлу
SERVICE_PATH="/etc/systemd/system/ffmpeg_capture.service"

# Проверяем, существует ли файл
if [ -f "$SERVICE_PATH" ]; then
    echo "Файл $SERVICE_PATH уже существует."
else
    echo "Файл $SERVICE_PATH отсутствует. Создаём файл..."

    # Содержимое для файла
    SERVICE_CONTENT="[Unit]
Description=Token Update Service
After=network.target

[Service]
ExecStart=$CURRENT_DIR/capture.sh
StandardOutput=file:$CURRENT_DIR/logfile.log
StandardError=file:$CURRENT_DIR/logfile.log
Group=$CURRENT_USER
User=$CURRENT_USER
Restart=on-failure

[Install]
WantedBy=multi-user.target"

    # Создаём файл под sudo и записываем содержимое
    echo "$SERVICE_CONTENT" | sudo tee "$SERVICE_PATH" > /dev/null
    
    # Устанавливаем корректные права доступа
    sudo chmod 644 "$SERVICE_PATH"
    echo "Файл $SERVICE_PATH успешно создан."

    # Создаём лог-файл
    sudo touch $CURRENT_DIR/logfile.log
    sudo chown $CURRENT_USER:$CURRENT_USER $CURRENT_DIR/logfile.log

    # Перезапускаем systemd для применения изменений
    sudo systemctl daemon-reload
    sudo systemctl enable ffmpeg_capture.service
    sudo systemctl start ffmpeg_capture.service
    sudo systemctl status ffmpeg_capture.service
    echo "Systemd перезагружен."
fi
