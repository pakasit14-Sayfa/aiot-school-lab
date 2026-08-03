#!/bin/zsh
set -e

cd /Users/sayfa/my_first_app/apps/user_app
flutter run -d chrome --dart-define-from-file=../../env.json
