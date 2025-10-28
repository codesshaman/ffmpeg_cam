#!/bin/bash

# Сохраняем текущую директорию в переменную
CURRENT_DIR=$(pwd)

# Сохраняем текущего пользователя в переменную
CURRENT_USER=$(whoami)

# Путь к файлу
SERVICE_PATH="/etc/systemd/system/ffmpeg_capture_0.service"

# Проверяем, существует ли файл
if [ -f "$SERVICE_PATH" ]; then
    echo "Файл $SERVICE_PATH уже существует."
else
    echo "Файл $SERVICE_PATH отсутствует. Создаём файл..."

    # Содержимое для файла
    SERVICE_CONTENT="[Unit]
Description=Camera 1 capturing service
After=local-fs.target remote-fs.target

[Service]
ExecStart=/usr/local/bin/capture_dev0.sh
StandardOutput=journal
StandardError=journal
Group=$CURRENT_USER
User=$CURRENT_USER
Restart=always

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
    sudo systemctl enable ffmpeg_capture_0.service
    sudo systemctl start ffmpeg_capture_0.service
    sudo systemctl status ffmpeg_capture_0.service
    echo "Systemd перезагружен."
fi
