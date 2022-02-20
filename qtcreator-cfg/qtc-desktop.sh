#!/bin/bash
qtc_path=$1
sudo cp $qtc_path/share/applications/*.desktop /usr/share/applications/
sudo ln -sf $qtc_path/bin/qtcreator.sh /usr/bin/qtcreator
# sudo cp $qtc_path/share/doc/qtcreator/qtcreator/images/creator-gs-01.png /usr/share/pixmaps/QtProject-qtcreator.png
