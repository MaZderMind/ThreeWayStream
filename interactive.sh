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
#  o Während der Sendung gibt's im Menü die Option, die inzwischen neu gestarteten und
#    auf den falschen Ausgang gemappten Audiostreams zurück auf den Kopfhörer zu leiten
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
	pactl unload-module $loopbackMic2Stream
	pactl unload-module $loopbackMumble2StreamId

	pactl unload-module $loopbackMic2MumbleId
	pactl unload-module $loopbackMusic2MumbleId

	pactl unload-module $loopbackMusic2PhonesId
	pactl unload-module $loopbackMumble2PhonesId

	pactl unload-module $loopbackMusic2Stream

	pactl unload-module $musicSinkId
	pactl unload-module $streamSinkId
	pactl unload-module $mumbleSendSinkId
	pactl unload-module $mumbleRecvSinkId

	exit 0
}

# Signals auffangen (Ctrl-C z.B.)
trap 'cleanup' 1 2

# Ein virtuelles Ausgabe-Gerät erstellen, das nicht auf eine echte Soundkarte zeigt.
# puleaudio erzeugt automatisch eine monitor-source, die in diesem Fall "stream.monitor"
# heißt und als Eingabe für Darkice geeignet ist
musicSinkId=$(pactl load-module module-null-sink sink_name=music)
streamSinkId=$(pactl load-module module-null-sink sink_name=stream)
mumbleSendSinkId=$(pactl load-module module-null-sink sink_name=mumble-send)
mumbleRecvSinkId=$(pactl load-module module-null-sink sink_name=mumble-recv)

# Das genannte Ausgabegerät als Standard-Ausgabe-Gerät setzen
mv2sink music

loopbackMic2MumbleId=$(pactl load-module module-loopback sink=mumble-send source=$INPUT latency_msec=25 adjust_time=1 source_dont_move=true sink_dont_move=true)
loopbackMusic2MumbleId=$(pactl load-module module-loopback sink=mumble-send source=music.monitor adjust_time=1 source_dont_move=true sink_dont_move=true)

loopbackMusic2PhonesId=$(pactl load-module module-loopback sink=$OUTPUT source=music.monitor adjust_time=1 source_dont_move=true sink_dont_move=true)
loopbackMumble2PhonesId=$(pactl load-module module-loopback sink=$OUTPUT source=mumble-recv.monitor latency_msec=25 adjust_time=1 source_dont_move=true sink_dont_move=true)

loopbackMusic2Stream=$(pactl load-module module-loopback sink=stream source=music.monitor adjust_time=1 source_dont_move=true sink_dont_move=true)

# Mumble-Konfiguration sichern
backupMumbleConfiguration

# Mumble-Konfiguration mit werten aus dem Profil befüllen
sed "s/###OUTPUT###/mumble-recv/g" <$MUMBLE | sed "s/###INPUT###/mumble-send.monitor/g" >~/.config/Mumble/Mumble.conf

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

startDarkice() {
	if [ -z $darkicePid ]; then

		echo "starting darkice"
		darkice -c /tmp/darkice.conf.tws >/tmp/darkice.log.tws 2>&1 &
		darkicePid=$!
		if [ $? != 0 ]; then
			echo "Darkice konnte nicht gestartet werden"
			cat /tmp/darkice.log.tws
			cleanup
		fi
	fi
}

stopDarkice() {
	if [ -n $darkicePid ]; then

		echo "stopping darkice"
		kill $darkicePid
	fi
}

# modes: offline, music, live
mode="offline"

# Sendung starten
while true; do
	if [ $mode = "offline" ]; then
		choice=$( whiptail --title "Offline" --menu "Mumble läuft aber der Stream ist noch Offline. Du hast folgende Optionen." 20 125 5 \
			"noop"    "nichts tun" \
			"reroute" "Audio-Ausgaben neu Routen (behebt manchmal Probleme)" \
			"music"   "Den Stream starten aber nur Audio-Ausgaben von Programmen senden (Mumble-Gespräch wird noch nicht gestreamt)" \
			"live"    "Den Stream starten und Live gehen (Audio-Ausgaben und Mumble wird gestreamt)" \
			"quit"    "Die Sendung beenden" 3>&1 1>&2 2>&3 )
	elif [ $mode = "music" ]; then
		choice=$( whiptail --title "Musik-Modus" --menu "Mumble und der Stream laufen, aber nur Audio-Ausgaben von Programmen wird gesendet (Mumble-Gespräch wird noch nicht gestreamt). Du hast folgende Optionen." 20 125 5 \
			"noop"    "nichts tun" \
			"reroute" "Audio-Ausgaben neu Routen (behebt manchmal Probleme)" \
			"live"    "Den Stream starten und Live gehen (Audio-Ausgaben und Mumble wird gestreamt)" \
			"offline" "Den Stream beenden, Mumble aber laufen lassen" \
			"quit"    "Die Sendung beenden" 3>&1 1>&2 2>&3 )
	elif [ $mode = "live" ]; then
		choice=$( whiptail --title "Live" --menu "Mumble und der Stream laufen. Du hast folgende Optionen." 20 125 5 \
			"noop"    "nichts tun" \
			"reroute" "Audio-Ausgaben neu Routen (behebt manchmal Probleme)" \
			"music"   "Den Stream laufen lassen aber nur Audio-Ausgaben von Programmen senden (Mumble-Gespräch wird nicht mehr gestreamt)" \
			"offline" "Den Stream beenden, Mumble aber laufen lassen" \
			"quit"    "Die Sendung beenden" 3>&1 1>&2 2>&3 )
	else
		echo "invalid mode $mode"
		cleanup
	fi

	if [ $choice = "reroute" ]; then
		mv2sink music
	elif [ $choice = "quit" ]; then
		cleanup
	elif [ $choice = "music" ]; then
		echo "switching to music-mode"
		mode="music"
		startDarkice

		echo "unloading loopbackMic"
		pactl unload-module $loopbackMic2Stream

		echo "unloading loopbackMumble2StreamId"
		pactl unload-module $loopbackMumble2StreamId

		echo "now in music-mode"
	elif [ $choice = "live" ]; then
		echo "switching to live-mode"
		mode="live"
		startDarkice

		echo "loading loopbackMic2Stream"
		loopbackMic2Stream=$(pactl load-module module-loopback sink=stream source=$INPUT)

		echo "loading loopbackMumble2StreamId"
		loopbackMumble2StreamId=$(pactl load-module module-loopback sink=stream source=mumble-recv.monitor)

		echo "now in live-mode"
	elif [ $choice = "offline" ]; then
		echo "switching to offline-mode"
		mode="offline"
		stopDarkice

		echo "unloading loopbackMic"
		pactl unload-module $loopbackMic2Stream

		echo "unloading loopbackMumble2StreamId"
		pactl unload-module $loopbackMumble2StreamId

		echo "now in offline-mode"
	fi
done
