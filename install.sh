#!/bin/sh

pub get
dart2native bin/main.dart -o fireutil

echo "Moving binary to /usr/local/bin…"
sudo mv fireutil /usr/local/bin/
