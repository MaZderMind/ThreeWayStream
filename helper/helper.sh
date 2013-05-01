#!/bin/bash

# Hilfsfunktion zum umleiten bestehendener Audioausgaben
mv2sink()
{
	pacmd set-default-sink $1
	pacmd list-sink-inputs | grep index | while read line
	do
		pacmd move-sink-input `echo $line | cut -f2 -d' '` $1 >/dev/null 2>&1
	done
}

initConfig()
{
	if [ ! -d "$HOME/.tws" ]; then
		cp -R "./baseconf" "$HOME/.tws"
		if ! whiptail --title "Standard-Konfiguration" --yesno --yes-button "Weitermachen" --no-button "bearbeiten" "Im Ordner $HOME/.tws/ wurde eine Standard-Konfiguration erzeugt. Du kannst dort mehrere Profile (für verschiedene Aufnahmesituationen) anlegen, Sendungstitel, Streaming-Server sowie den Namen deiner Headset-Soundkarte konfigurieren\n\nMöchtest du mit dem Standard-Profil weiter machen oder zunächst deine Konfiguration bearbeiten?" 20 80; then
			exit 0;
		fi
	fi
}

listProfiles()
{
	ls -1 $HOME/.tws/*.profile
}

selectProfile()
{
	PROFILES=$(listProfiles)

	# only 1 profile
	if [ $(echo "$PROFILES" | wc -l) -lt 2 ]; then
		echo "$PROFILES"
		exit
	fi

	declare -a OPTIONS
	while read PROFILE; do
		OPTIONS+=( "$(basename "$PROFILE" .profile)" )
		OPTIONS+=( "" ) # no description
	done <<< "$PROFILES"

	PROFILE=$( whiptail --title "Profil" --menu "Wähle eines der vorbereiteren Profile aus" 20 80 10 "${OPTIONS[@]}" 3>&1 1>&2 2>&3 )
	echo "$HOME/.tws/$PROFILE.profile"
}


readTitle()
{
	whiptail --title "Sendungstitel" --inputbox "Gib den Sendungstitel ein" 9 80 "$TITLE" 3>&1 1>&2 2>&3
}

readPasswd()
{
	whiptail --title "Sudo-Passwort" --passwordbox "Sudo-Passwort für Darkice (Realtime-Komponente)" 9 80 3>&1 1>&2 2>&3
}

backupMumbleConfiguration()
{
	cp ~/.config/Mumble/Mumble.conf ~/.config/Mumble/Mumble.conf.twsbackup
}

restoreMumbleConfiguration()
{
	cp ~/.config/Mumble/Mumble.conf.twsbackup ~/.config/Mumble/Mumble.conf
}