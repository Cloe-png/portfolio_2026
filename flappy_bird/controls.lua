-- Entrées utilisateur et boucle de mise à jour.
-- Lis ce fichier comme ca :
-- 1. les touches clavier
-- 2. le clic souris
-- 3. les petites animations
-- 4. la vraie boucle du jeu

-- Fait tourner le curseur du menu principal.
function changeMenu(step)
    menuIndex = menuIndex + step

    if menuIndex < 1 then
        menuIndex = 4
    elseif menuIndex > 4 then
        menuIndex = 1
    end
end

-- Fait tourner le curseur du menu de difficulté.
function changeDifficulty(step)
    difficultyIndex = difficultyIndex + step

    if difficultyIndex < 1 then
        difficultyIndex = #difficultyOptions
    elseif difficultyIndex > #difficultyOptions then
        difficultyIndex = 1
    end
end

-- Gere toutes les touches du jeu selon l'ecran actif.
function handleKeypressed(key)
    -- Menu principal.
    if state == "menu" then
        if key == "up" then
            changeMenu(-1)
        elseif key == "down" then
            changeMenu(1)
        elseif key == "return" or key == "space" then
            if menuIndex == 1 then
                difficultyIndex = 1
                state = "difficulty"
            elseif menuIndex == 2 then
                state = "shop"
            elseif menuIndex == 3 then
                state = "reset_confirm"
            else
                love.event.quit()
            end
        end
        return
    end

    -- Ecran de confirmation du reset.
    if state == "reset_confirm" then
        if key == "return" or key == "space" then
            resetProgress()
        elseif key == "escape" then
            state = "menu"
        end
        return
    end

    -- Choix de difficulté.
    if state == "difficulty" then
        if key == "up" then
            changeDifficulty(-1)
        elseif key == "down" then
            changeDifficulty(1)
        elseif key == "return" or key == "space" then
            startRun(difficultyOptions[difficultyIndex].key)
        elseif key == "escape" then
            state = "menu"
        end
        return
    end

    -- Boutique.
    if state == "shop" then
        if key == "tab" then
            if shopSection == "bird" then
                shopSection = "background"
            elseif shopSection == "background" then
                shopSection = "pipe"
            else
                shopSection = "bird"
            end
        elseif key == "escape" then
            state = "menu"
        elseif string.match(key, "^%d$") then
            local index = tonumber(key)

            if shopSection == "bird" then
                buyOrSelectBird(index)
            elseif shopSection == "background" then
                buyOrSelectBackground(index)
            else
                buyOrSelectPipe(index)
            end
        end
        return
    end

    -- Partie en cours.
    if state == "playing" then
        if key == "space" then
            bird.speedY = jumpForce
            playSound("jump")
        elseif key == "p" then
            state = "paused"
        elseif key == "escape" then
            state = "menu"
            saveData()
        end
        return
    end

    -- Pause.
    if state == "paused" then
        if key == "p" then
            state = "playing"
        elseif key == "escape" then
            state = "menu"
            saveData()
        end
        return
    end

    -- Game over.
    if state == "gameover" then
        if key == "return" or key == "space" then
            startRun(difficultyMode)
        elseif key == "escape" then
            state = "menu"
        end
    end
end

-- Gère le saut à la souris pendant la partie.
function handleMousepressed(x, y, button)
    if state == "playing" and button == 1 then
        bird.speedY = jumpForce
        playSound("jump")
    end
end

-- Anime les sprites de l'oiseau.
function updateBirdAnimation(dt)
    local currentBirdData = birdSpriteData[selectedBird]
    local currentBirdFrames = birdSpriteFrames

    if currentBirdData ~= nil then
        currentBirdFrames = currentBirdData.frames
    end

    if currentBirdFrames ~= nil and #currentBirdFrames > 1 then
        birdSpriteFrameTimer = birdSpriteFrameTimer + dt

        if birdSpriteFrameTimer >= birdSpriteFrameDuration then
            birdSpriteFrameTimer = birdSpriteFrameTimer - birdSpriteFrameDuration
            birdSpriteFrameIndex = (birdSpriteFrameIndex % #currentBirdFrames) + 1
        end
    end
end

-- Anime les sprites des pièces.
function updateCoinAnimation(dt)
    -- Si la pièce n'a qu'une seule image, on ne fait rien.
    if coinSprite ~= nil and #coinSpriteFrames > 1 then
        coinSpriteFrameTimer = coinSpriteFrameTimer + dt

        if coinSpriteFrameTimer >= coinSpriteFrameDuration then
            coinSpriteFrameTimer = coinSpriteFrameTimer - coinSpriteFrameDuration
            coinSpriteFrameIndex = (coinSpriteFrameIndex % #coinSpriteFrames) + 1
        end
    end
end

-- Fait défiler les nuages d'ambiance.
function updateClouds(dt)
    -- Les nuages bougent même quand on n'est pas en train de jouer.
    for i = 1, #clouds do
        local cloud = clouds[i]
        cloud.x = cloud.x + cloud.speed * dt

        if cloud.x > WINDOW_WIDTH + 120 then
            cloud.x = -cloud.w - love.math.random(20, 120)
            cloud.y = love.math.random(45, 220)
        end
    end
end

-- Boucle principale d'une frame.
-- On met à jour les animations tout le temps,
-- puis la vraie physique uniquement en partie.
function updateGame(dt)
    -- Petites animations visuelles.
    updateBirdAnimation(dt)
    updateCoinAnimation(dt)
    updateClouds(dt)

    -- Si on n'est pas dans une partie, on arrete ici.
    if state ~= "playing" then
        return
    end

    -- Le jeu devient un peu plus dur avec le score.
    updateDifficulty()

    -- Le sol defile pour donner l'impression de mouvement.
    groundOffset = (groundOffset + pipeSpeed * dt) % 48

    -- Physique de l'oiseau.
    bird.speedY = bird.speedY + gravity * dt
    bird.y = bird.y + bird.speedY * dt

    -- Mise a jour des obstacles et des pieces.
    updatePipes(dt)
    updateCoins(dt)

    -- Collision avec le plafond.
    if bird.y < 0 then
        bird.y = 0
        loseLife()
    end

    -- Collision avec le sol.
    if bird.y + bird.height > GROUND_Y then
        bird.y = GROUND_Y - bird.height
        loseLife()
    end
end
