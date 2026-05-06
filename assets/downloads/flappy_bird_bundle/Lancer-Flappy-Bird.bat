@echo off
set "LOVE_EXE=C:\Program Files\LOVE\love.exe"
set "GAME_FILE=%~dp0flappy_bird.love"

if not exist "%LOVE_EXE%" (
  echo LOVE2D n'est pas installe sur ce PC.
  echo Installe LOVE2D puis relance ce fichier.
  pause
  exit /b 1
)

if not exist "%GAME_FILE%" (
  echo Le fichier flappy_bird.love est introuvable.
  pause
  exit /b 1
)

start "" "%LOVE_EXE%" "%GAME_FILE%"
