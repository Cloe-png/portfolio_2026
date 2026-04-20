-- Point d'entrée LOVE2D :
-- ce fichier reste volontairement très court.
-- Il ne fait que brancher les modules entre eux.

require("config")
require("assets")
require("controls")
require("screens")

function love.load()
    -- Charge toutes les images et polices.
    initializeAssets()

    -- Recharge ensuite la progression du joueur.
    resetBird()
    loadData()
    syncSpecialUnlocks()
    sanitizeSelections()
    saveData()
end

function love.keypressed(key)
    -- Le détail des touches est géré dans controls.lua.
    handleKeypressed(key)
end

function love.mousepressed(x, y, button)
    -- Les clics sont centralisés aussi dans controls.lua.
    handleMousepressed(x, y, button)
end

function love.update(dt)
    -- Toute la logique d'une frame est déléguée au module de contrôle.
    updateGame(dt)
end

function love.draw()
    -- screens.lua choisit quel écran dessiner selon l'état du jeu.
    drawCurrentScreen()
end
