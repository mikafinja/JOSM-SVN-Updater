#!/bin/bash

# Verzeichnis in das das SVN ausgecheckt wird
source_dir=~/source/josm

# Maximaler Heap mit dem die Java-VM gestartet werden soll
maxmem="1024M"

# Minimaler Heap mit dem die Java-VM gestartet werden soll
minmem="128M"

# 2D-Beschleunigung aktivieren ja=true; nein=false
acc2d="true"

if ping josm.openstreetmap.de -c 2 > /dev/null; then
	version_svn=`svn info http://josm.openstreetmap.de/svn/trunk | grep Revision | awk '{print $2}'`
	echo "Repository ist erreichbar."
else
	version_svn=-1
fi

echo "Überprüfe ob Verzeichnis für JOSM SVN-Version existiert..."

if [ -d $source_dir ]; then
	echo Verzeichnis $source_dir existiert
	if [ -f $source_dir/trunk/build/REVISION ]; then
		version_lokal=`grep "Revision" < $source_dir/trunk/build/REVISION | awk '{print $2}'`
	else
		echo "Lokale Kopie existiert nicht"
		version_lokal=0
	fi
else
	echo "Verzeichnis $source_dir wird angelegt"
	mkdir -p $source_dir
	version_lokal=0
fi

echo "lokale Version: $version_lokal"
echo "aktuelle Version: $version_svn"

if [ $version_svn -eq -1 ]; then
	echo "Repository ist nicht erreichbar."
	if [ $version_lokal -eq 0 ]; then
		echo "Lokale Version existiert nicht, Script wird abgebrochen."
		exit 1
	fi
elif [ $version_lokal -lt $version_svn ]; then
	echo "Die lokale Version ist veraltet. Aktuelle Version wird herunter geladen."
	cd $source_dir
	svn co http://josm.openstreetmap.de/svn/trunk
	echo "Kompiliere aktualisierte Version."
	ant clean dist -f $source_dir/trunk/build.xml
else
	echo "Lokale Version ist aktuell."
fi
version_aktuell=`grep "Revision" < $source_dir/trunk/build/REVISION | awk '{print $2}'`
echo "Starte JOSM Version $version_aktuell"
java -Xms$minmem -Xmx$maxmem -Dsun.java2d.opengl=$acc2d -jar $source_dir/trunk/dist/josm-custom.jar $* &
echo "JOSM wurde mir der ProzessID $! gestartet"