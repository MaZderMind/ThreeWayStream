# Diese Datei kann im Ordner $HOME/.tws/ abgelegt werden. Liegen dort mehrere
# Dateien, wird beim Start nach der richtigen Datei gefragt. So kann z.B. eine
# Test-Konfiguration "test.conf" und eine Produktiv-Konfiguration "produktif.conf"
# angelegt werden.
# Ist nur eine Datei vorhanden, wird nicht gefragt.

# PulseAudio Gerätename des Eingabegerätes
# Verfügbare Eingabegeräte können mit
#   pactl list sources | grep Name
INPUT=alsa_input.usb-Burr-Brown_from_TI_USB_Audio_CODEC-00-CODEC.analog-stereo


# PulseAudio Gerätename des Ausgabegerätes
# Verfügbare Eingabegeräte können mit
#   pactl list sinks | grep Name
OUTPUT=alsa_output.usb-Burr-Brown_from_TI_USB_Audio_CODEC-00-CODEC.analog-stereo


# Vorlage für Sendungstitel
TITLE="EX123 "


# Darkice-Konfigurationsdatei
DARKICE=$HOME/.tws/darkice.conf

# Mumble-Konfigurationsdatei
MUMBLE=$HOME/.tws/Mumble.conf

# Mumble-Login
MUMBLE_LOGIN=mumble://Podcast-Tester@localhost:64738

# Konfigurationseinstellungen, die in der og. Konfigurationsdatei ersetzt werden
#  Tip: Wenn sich die verschiedenen TWS-Profile in mehr als diesen drei Einstellungen
#  unterscheiden sollen (z.B. mehrere Sendungen mit eigenen Titeln und Beschreibungen)
#  einfach jeweils eine eigene Basiskonfigurationsdatei verweden.
#  Diese Dateien können dann je nach Bedarf auch ohne ###-Platzhalter auskommen.
DARKICE_SERVER=localhost
DARKICE_PORT=8000
DARKICE_PASSWORD=password

