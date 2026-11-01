#!/bin/bash
set -e

echo "start REPEATER"

# 1. Интерактивный запрос данных
echo "[*] Настройка конфигурации:"
read -p "Входной порт прослушивания (по умолчанию :443): " LISTEN_ADDR
LISTEN_ADDR=${LISTEN_ADDR:-:443}

read -p "Введите SNI домен для VPN (например, amd.com): " VPN_SNI
read -p "Введите удаленный IP:порт для VPN (например, 89.125.248.50:443): " VPN_TARGET_ADDR

read -p "Введите локальный адрес назначения (по умолчанию 127.0.0.1:8443): " LOCAL_TARGET_ADDR
LOCAL_TARGET_ADDR=${LOCAL_TARGET_ADDR:-127.0.0.1:8443}

# 2. Создаем файл конфигурации
echo "[*] Создание файла конфигурации /etc/default/repeater..."
sudo mkdir -p /etc/default
cat << EOF | sudo tee /etc/default/repeater > /dev/null
LISTEN_ADDR=${LISTEN_ADDR}
VPN_SNI=${VPN_SNI}
VPN_TARGET_ADDR=${VPN_TARGET_ADDR}
LOCAL_TARGET_ADDR=${LOCAL_TARGET_ADDR}
EOF

# 3. Переносим готовый бинарник и даем ему права на запуск
echo "[*] Установка бинарного файла..."
sudo mv repeater /usr/local/bin/repeater
sudo chmod +x /usr/local/bin/repeater

# 4. Создаем службу Systemd
echo "[*] Создание системной службы..."
cat << EOF | sudo tee /etc/systemd/system/repeater.service > /dev/null
[Unit]
Description=Repeater SNI Router
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/repeater
EnvironmentFile=/etc/default/repeater
Restart=always
RestartSec=5
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

# 5. Запуск
echo "[*] Запуск службы в Systemd..."
sudo systemctl daemon-reload
sudo systemctl enable repeater
sudo systemctl restart repeater

echo "Repeater successfully launched"
