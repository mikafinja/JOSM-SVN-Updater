#!/bin/bash
#
#
# Copyright (C) [2009] [Max Andre - Benutzer Telegnom bei Openstreetmap.org]
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software Foundation; either version 3 of the License,
# or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
# without #even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
# See the GNU General Public License for more details.
#
# To get a copy of the GNU General Public License see <http://www.gnu.org/licenses/>.
#
#
###
# Die Vorgabewerte bitte den eigenen Bedürfnissen anpassen:
###

# Verzeichnis in das das SVN ausgecheckt wird
source_dir=~/source/josm

# Maximaler Heap mit dem die Java-VM gestartet werden soll (in MB)
maxmem="1240"

# Minimaler Heap mit dem die Java-VM gestartet werden soll (in MB)
minmem="128"

# 2D-Beschleunigung aktivieren ja=true; nein=false
acc2d="true"

###
# Beginn des Scripts, aber hier nichts mehr verändern!
###

# Parsen der übergebenen Parameter

set -- `getopt "hrm:" "$@"`
while [ "$1" != "" ]; do
	case "$1" in
		-h) echo "Hilfe: `basename $0` [-h] [-m] [Dateien]"; 
		#-n) echo "Repository wird nicht ausgecheckt. Lokale Version wird gestartet";
		    echo "-h : zeigt diese Hilfe an";	
                    echo "-m : Speicher der JOSM zugewiesen wird (in MB). Muss größer als $minmem sein"; 
		    echo "-r : Erneute Kompilierung der lokal vorhandenen Quellen.";
		    exit;;
		-m) shift; maxmem="$1";;
		-r) shift; build=1;;
		--) break;;
	esac
	shift
done


if [ "$build" == "1" ]; then
	if svn info $source_dir > /dev/null; then
		echo "Quellen lokal vorhanden, kompiliere Quellen erneut."
	else
		echo "Quellen lokal nicht vorhanden. Script wird abgebrochen."
		exit 1
	fi
else

	# prüfung, ob svn-repository erreichbar ist
	if ping josm.openstreetmap.de -c 2 > /dev/null; then
		version_svn=`svn info http://josm.openstreetmap.de/svn/trunk | grep Revision | awk '{print $2}'`
		echo "Repository ist erreichbar."
	else

		# Wenn das Repository nicht erreichbar ist, wird die svn-version auf -1 gesetzt
		version_svn=-1
	fi

	echo "Überprüfe ob Verzeichnis $source_dir existiert..."

	# Prüfung ob das angegebene Verzeichnis existiert
	if [ -d $source_dir ]; then
		echo Verzeichnis $source_dir existiert

		# Prüfung ob REVISION-Datei aus dem SVN lokal vorhanden ist
		version_lokal=`svn info $source_dir | grep Revision | awk '{print $2}'`
		if [ -z $version_lokal ]; then
			echo "Lokale Kopie existiert nicht"

		        # Falls keine lokale Version ermittelt werden konnte, Version auf 0 setzen
			version_lokal=0
		fi
	else

		# falls das verzeichnis nicht gefunden wurde, wird es angelegt
		echo "Verzeichnis $source_dir wird angelegt"
		mkdir -p $source_dir

		# lokale Version wird auf 0 gesetzt
		version_lokal=0
	fi

	echo "lokale Version: $version_lokal"
	echo "aktuelle Version: $version_svn"

	# wenn keine lokale Version vorhanden ist und das SVN-Repository nicht erreichbar ist, wird das Script abgebrochen
	if [ $version_svn -eq -1 ]; then
		echo "Repository ist nicht erreichbar."
		if [ $version_lokal -eq 0 ]; then

		        # abbruch des scripts
			echo "Lokale Version existiert nicht, Script wird abgebrochen."
			exit 1
		fi

	# wenn die lokale Version kleiner ist als die svn version wird das Repository ausgecheckt und kompiliert.
	elif [ $version_lokal -lt $version_svn ]; then
		echo "Die lokale Version ist veraltet. Aktuelle Version wird herunter geladen."
		cd $source_dir

		# auschecken des Repository
		svn co http://josm.openstreetmap.de/svn/trunk $source_dir
		echo "Kompiliere aktualisierte Version."

		# kompilieren der aktuellen JOSM-Version
		build=1;
	else
		echo "Lokale Version ist aktuell."
	fi
fi
if [ $build -eq 1 ]; then
	ant clean dist -f $source_dir/build.xml
fi

version_aktuell=`svn info $source_dir | grep Revision | awk '{print $2}'`
echo "Starte JOSM Version $version_aktuell"

# JOSM mit den oben gewählten Parametern startem
java -Xms"$minmem"M -Xmx"$maxmem"M -Dsun.java2d.opengl=$acc2d -jar $source_dir/dist/josm-custom.jar $@ &

# ProzessID mit der JOSM gestartet wurde augeben
echo "JOSM wurde mir der ProzessID $! gestartet"
