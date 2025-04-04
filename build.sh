#!/bin/sh

# This script will run when Netlify builds the project
flutter config --enable-web
flutter build web --release
