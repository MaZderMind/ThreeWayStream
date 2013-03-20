#!/bin/bash

echo "Titel der Sendung (beginnend mit dem Episoden-Slug getrennt durch Leerzeichen)"
echo "z.B. OSMDE023 Titel der Sendung"
read -ep " -> " title

if [ -z $title ]; then
	echo "Ohne Titel geht nix."
	exit 2
fi

cleanup() {
	echo "Mumble beenden"
	kill $mumblePid

	echo "Mumble-Konfiguration wieder herstellen ###"
	mv ~/.config/Mumble/Mumble.conf ~/.config/Mumble/Mumble.conf.tws
	mv ~/.config/Mumble/Mumble.conf.twsbackup ~/.config/Mumble/Mumble.conf

	echo "PulseAudio zurücksetzen"
	# Löschen der virtuellen Audiogeräte und Loopbacks
	#pactl unload-module $loopbackLocalId
	pactl unload-module $loopbackInId
	pactl unload-module $loopbackOutId
	pactl unload-module $streamSinkId
	exit 0
}
trap 'cleanup' 1 2

echo "PulseAudio vorbereiten..."

# Erstellt ein virtuelles Ausgabe-Gerät, das nicht auf eine echte Soundkarte zeigt
# puleaudio erzeugt automatisch eine monitor-source, die in diese m Fall "stream.monitor"
# heißt und als Eingabe für Darkice geeignet ist
streamSinkId=$(pactl load-module module-null-sink sink_name=stream)

# Erstellt einen Loopback, der die Audio-Eingabe des Mikrofons in das Stream-Device kopiert
loopbackInId=$(pactl load-module module-loopback sink=stream source=alsa_input.pci-0000_00_1b.0.analog-stereo)

# Erstellt einen Loopback, der die Audio-Ausgabe an den Kopfhörer in das Stream-Device kopiert
loopbackOutId=$(pactl load-module module-loopback sink=stream source=alsa_output.pci-0000_00_1b.0.analog-stereo.monitor)

echo "Mumble konfugieren"
mv ~/.config/Mumble/Mumble.conf ~/.config/Mumble/Mumble.conf.twsbackup
cp Mumble.conf ~/.config/Mumble/Mumble.conf

echo "Mumble starten"
# Mumble starten
mumble mumble://Marc-und-Peter@heta.saerdnaer.de:64738 >/dev/null 2>&1 &
mumblePid=$!

echo "Darkice konfigurieren"
sed "s/###TITLE###/$title/" <darkice.conf >/tmp/darkice.conf.tws

echo "Darkice  starten"
echo "###### KEEP THIS WINDOW OPEN FOR THE LIVETIME OF THE SHOW ######"
echo "######           CTRL+C ENDS MUMBLE AND STREAM            ######"
# Den Streamer starten
darkice -c /tmp/darkice.conf.tws >/dev/null 2>&1

cleanup




#
#
#                      Stream
#                       ^ ^
#                       | |
#                       / |
# Micro ---------------+---------------> Mumble Ausgang
#                         |
#       .monitor ---------/
# Kopfhörer <--------------------------- Mumble Eingang
#
#
#

# Todos:
# Derzeit wird der Monitor des Kopfhörer-Ausgangs in den Stream gespeist
# Dadurch werden alle Ausgaben, die an den Kopfhörer gehen, auch in den Stream eingespeist

# 

# Wir möchten aber später aber ein Setup haben, in dem das Mikrofon und das Mumble nicht in den Stream gehen, alle anderen Ausgaben des Rechners aber schon (-> Musik)
# Das soll Interaktiv steuerbar sein
