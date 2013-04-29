#!/bin/bash

# simple.sh
# Die einfachst denkbare Implementierung des ThreeWayStreamings.
#  o Nach der Auswahl des Profils wird ein neues Audiogerät "Stream" erstellt
#  o Um Probleme mit div. Quellanwendungen (Chrome, ich schau dich an!), werden
#    die laufenden Audiostreams zurück auf den Kopfhörer umgeleitet
#  o Das im Profil angegebene Mikrofon wird mit einem Loopback in dieses Gerät geklont
#  o Die Monitor-Source des im Profil angegebenen Kopfhörers wird über einen weiteren
#    Loopback ebenfals in das Audiogerät geklont
#  o Abschließend werden Mumble und Darkice konfiguriert und erst Mumble und dann
#    Darkice gestartet
#  o Nach den Beenden der Sendung werden Darkice und Mumble getötet und die
#    Audiostreams wieder aufgeräumt


# Schaltbild
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

. ./helper/helper.sh

# Konfiguration vorbereiten
initConfig

# Profile auswählen
PROFILE=$(selectProfile)

# Profile laden
. "$PROFILE"

# Sendungstitel einlesen
TITLE=$(readTitle)

# Sudo-Passwort abfragen (für darkice realtime-priorität)
PASSWD=$(readPasswd)

exit

# Pulseaudio Aufräum-Funktion
cleanup() {
	echo "Mumble beenden"
	kill $mumblePid

	echo "Mumble-Konfiguration wieder herstellen ###"
	rm -f ~/.config/Mumble/Mumble.conf
	mv ~/.config/Mumble/Mumble.conf.twsbackup ~/.config/Mumble/Mumble.conf

	echo "PulseAudio zurücksetzen"
	pactl unload-module $loopbackInId
	pactl unload-module $loopbackOutId
	pactl unload-module $streamSinkId
	exit 0
}

# Signals auffangen (Ctrl-C z.B.)
trap 'cleanup' 1 2


echo "PulseAudio vorbereiten..."

# Erstellt ein virtuelles Ausgabe-Gerät, das nicht auf eine echte Soundkarte zeigt
# puleaudio erzeugt automatisch eine monitor-source, die in diese m Fall "stream.monitor"
# heißt und als Eingabe für Darkice geeignet ist
streamSinkId=$(pactl load-module module-null-sink sink_name=stream)
mv2sink alsa_output.pci-0000_00_1b.0.analog-stereo

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
sudo darkice -c /tmp/darkice.conf.tws >/dev/null 2>&1

cleanup
