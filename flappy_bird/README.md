# Flappy Bird en Lua

Version simple pour débuter avec `Lua` et `LOVE2D`.

## Lancement

1. Installer `LOVE2D` version 11.x : https://love2d.org/
2. Ouvrir un terminal dans `flappy_bird`
3. Lancer :

```powershell
cd C:\wamp64\www\Portfolio2\flappy_bird
"C:\Program Files\LOVE\love.exe" .
```

## Commandes

- `Espace` ou clic gauche : sauter
- `P` : mettre en pause
- `Entrée` : recommencer après un game over
- `Échap` : revenir au menu

## Organisation du code

- `main.lua` : point d'entrée LOVE2D
- `config.lua` : état global, sauvegarde et logique de jeu
- `assets.lua` : chargement des images, polices et sprites
- `controls.lua` : clavier, souris et mise à jour du jeu
- `screens.lua` : affichage des menus et de la partie
- `conf.lua` : configuration de la fenêtre

## Contenu du jeu

- un menu principal
- trois niveaux de difficulté
- trois vies
- des pièces à ramasser
- une boutique
- des skins pour l'oiseau, le décor et les tuyaux
- un meilleur score sauvegardé
- un sol qui défile

Le jeu utilise les images présentes dans `assets/`.
