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

# Pulseaudio Aufräum-Funktion
cleanup() {
	# Mumble beenden
	kill $mumblePid

	# Darkice beenden
	kill $darkicePid

	# Mumble-Konfiguration wieder herstellen
	restoreMumbleConfiguration

	# darkice Konfigu löschen
	rm -f /tmp/darkice.conf.tws /tmp/darkice.log.tws /tmp/mumble.log.tws

	# PulseAudio zurück setzen
	pactl unload-module $loopbackInId
	pactl unload-module $loopbackOutId
	pactl unload-module $streamSinkId
	exit 0
}

# Signals auffangen (Ctrl-C z.B.)
trap 'cleanup' 1 2

# Ein virtuelles Ausgabe-Gerät erstellen, das nicht auf eine echte Soundkarte zeigt.
# puleaudio erzeugt automatisch eine monitor-source, die in diesem Fall "stream.monitor"
# heißt und als Eingabe für Darkice geeignet ist
streamSinkId=$(pactl load-module module-null-sink sink_name=stream)

# Das genannte Ausgabegerät als Standard-Ausgabe-Gerät setzen
mv2sink $OUTPUT

# Einen Loopback erstellen, der die Audio-Eingabe des Mikrofons in das Stream-Device kopiert
loopbackInId=$(pactl load-module module-loopback sink=stream source=$INPUT)

# Einen Loopback erstellen, der die Audio-Ausgabe an den Kopfhörer in das Stream-Device kopiert
loopbackOutId=$(pactl load-module module-loopback sink=stream source=$OUTPUT.monitor)

# Mumble-Konfiguration sichern
backupMumbleConfiguration

# Mumble-Konfiguration mit werten aus dem Profil befüllen
sed "s/###OUTPUT###/$OUTPUT/g" <$MUMBLE | sed "s/###INPUT###/$INPUT/g" >~/.config/Mumble/Mumble.conf

# Mumble starten
mumble $MUMBLE_LOGIN >/tmp/mumble.log.tws 2>&1 &
mumblePid=$!
if [ $? != 0 ]; then
	echo "Mumble konnte nicht gestartet werden"
	cat /tmp/mumble.log.tws
	cleanup
fi

# Darkice konfigurieren
sed "s/###TITLE###/$TITLE/g" <$DARKICE | sed "s/###SERVER###/$DARKICE_SERVER/g" | sed "s/###PORT###/$DARKICE_PORT/g" | sed "s/###PASSWORD###/$DARKICE_PASSWORD/g" | sed "s/###SOURCE###/stream.monitor/g" >/tmp/darkice.conf.tws

# Darkice starten
darkice -c /tmp/darkice.conf.tws >/tmp/darkice.log.tws 2>&1 &
darkicePid=$!
if [ $? != 0 ]; then
	echo "Darkice konnte nicht gestartet werden"
	cat /tmp/darkice.log.tws
	cleanup
fi

# Sendung starten
while true; do
	choice=$( whiptail --title "Sendung" --menu "Die Sendung läuft jetzt. Du hast folgende Optionen." 20 80 3 \
		"noop"    "nichts tun" \
		"reroute" "Audio-Ausgaben neu Routen (behebt manchmal Probleme)" \
		"quit"    "Die Sendung beenden" 3>&1 1>&2 2>&3 )

	if [ $choice = "reroute" ]; then
		mv2sink $OUTPUT
	elif [ $choice = "quit" ]; then
		cleanup
	fi
done
