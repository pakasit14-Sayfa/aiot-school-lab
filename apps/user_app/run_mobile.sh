#!/bin/zsh
set -e

cd /Users/sayfa/my_first_app/apps/user_app
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8092 --dart-define-from-file=../../env.json
