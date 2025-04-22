#!/usr/bin/env bash
# Ustawia statyczny adres IP 192.168.0.50/24 na pierwszym wykrytym interfejsie sieciowym
# (z pominięciem lo). Wymagany Ubuntu 17.10+ (netplan).



set -euo pipefail

echo "Rozpoczynam konfigurację statycznego adresu IP..."

# Wykryj pierwszy interfejs inny niż lo
echo "Wykrywanie interfejsu sieciowego..."
IFACE=$(ls /sys/class/net | grep -v '^lo$' | head -n1)

if [[ -z "$IFACE" ]]; then
  echo "Nie znaleziono żadnego interfejsu sieciowego!" >&2
  exit 1
fi

echo "Znaleziono interfejs: $IFACE"

# Utwórz kopię zapasową bieżących ustawień sieci
echo "Tworzenie kopii zapasowej bieżących ustawień sieci..."
BACKUP_DIR="/etc/netplan/backup"
sudo mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
sudo cp /etc/netplan/*.yaml "$BACKUP_DIR/netplan-backup-$TIMESTAMP.yaml" 2>/dev/null || echo "Brak istniejących plików Netplan do skopiowania."
echo "Kopia zapasowa została zapisana w $BACKUP_DIR jako netplan-backup-$TIMESTAMP.yaml"

# Utwórz/aktualizuj plik Netplan
echo "Tworzenie/aktualizacja pliku Netplan..."
sudo tee /etc/netplan/99-static-ip.yaml >/dev/null <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ${IFACE}:
      dhcp4: false
      addresses: [192.168.0.50/24]
      gateway4: 192.168.0.1          # ← zmień, jeśli Twoja brama jest inna
      nameservers:
        addresses: [8.8.8.8,8.8.4.4] # ← opcjonalnie: własne DNS‑y
EOF

echo "Plik Netplan został utworzony/zmodyfikowany."

# Zastosuj konfigurację
echo "Zastosowanie konfiguracji Netplan..."
sudo netplan try

echo "Konfiguracja zakończona pomyślnie! ${IFACE} ma teraz statyczne IP 192.168.0.50"