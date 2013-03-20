ThreeWayStream - Live-Stream für [Radio OSM](podcast.openstreetmap.de)
======================================================================
Live-Podcasten ist was tolles, um sicheine Community zu erschaffen, die auch mit einander redet. Auch Podcasten über Städtegrenzen hinweg ist mit Mumble oder Skype kein Problem. Möchte man aber beides - Ferngespräch via Mumble *und* Live-Stream, wird's kniffelig.

Was ins Mikro gesprochen wird, soll an Mumble gehen. Was aus Mumble kommt, soll in die Kopfhörer gehen. Der Stream soll beides hören.
Audioausgabe vom Rechner (z.B. Musik oder Einspieler) sollen sogar alle drei (Kopfhörer, Mumble und der Stream) hören.

Wenn man's dann noch etwas weiter treiben möchte und der Stream während des Vor- und Nachgespräches nur Musik hören soll, während sich die Teilnehmer schon unterhalten können wird daraus ganz schnell ziemlich kompliziertes Audiorouting.

Hardware Lösung
---------------
Man kan das nun entweder mit Hardware lösen, in dem man mehrere Rechner mit mehreren Soundkarten an ein Mischpult hängt - einen für den Stream, einen für Mumble und einen für Musik/Videoeinspieler...


Meine Lösung
------------
Oder man benutzt den bei Ubuntu und anderen Distros beiligenden PulseAudio-Server, der solche Mixes auch kann. Dazu kann man im PulseAudio virtuelle Audiogeräte anlegen, den Anwendungen zuweisen und zwischen den Geräten mit Loopback-Devices verbindungen schaffen (oder auch wieder abbauen).
Diese Skripte und Konfigurationsdateien automatisieren uns beim [Radio OSM](podcast.openstreetmap.de) diese Konfiguration und lösen damit (hoffentlich *g*) [Soundflower](http://cycling74.com/soundflower-landing-page/) und [Nicecast](http://www.rogueamoeba.com/nicecast/) ab.


Installation
------------
PulseAudio liegt z.B. bei den Ubuntu Distris schon bei. Mumble aus den Paketquellen tut's wenn man nicht unbedingt Support für den Opus-Codec braucht. Darkice muss aber aus dem Quellcode kompiliert werden, da die Version in der Paketverwaltung derzeit (Anfang 2013) keine virtuellen PulseAudio-Geräte als Quelle unterstützen. Beim Kompilieren aus dem Quellcode hat mir dieser [Bugreport mit Fix](https://code.google.com/p/darkice/issues/detail?id=62) sehr geholfen.

Kontakt
-------
Bei Fragen oder Problement könnt ihr euch gerne an *github at mazdermind dot de* wenden.
