-- Taille de la fenêtre
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- Sol
GROUND_HEIGHT = 90
GROUND_Y = WINDOW_HEIGHT - GROUND_HEIGHT

-- Etats du jeu :
-- "menu" = menu principal
-- "difficulty" = choix de la difficulte
-- "reset_confirm" = confirmation du reset
-- "shop" = boutique
-- "playing" = partie en cours
-- "paused" = pause
-- "gameover" = fin de partie
state = "menu"

-- Mode de difficulte choisi dans le menu
difficultyMode = "normal"

-- Joueur
bird = {}
birdSprite = nil
birdSpriteFrames = {}
birdSpriteFrameIndex = 1
birdSpriteFrameTimer = 0
birdSpriteFrameDuration = 0.11
backgroundSprites = {}

-- Objets du jeu
pipes = {}
coinsOnMap = {}

-- Score et progression
score = 0
bestScore = 0
coins = 0
coinsRun = 0
lives = 3
maxLives = 3

-- Timers
pipeTimer = 0
coinTimer = 0

-- Physique simple
baseGravity = 850
gravity = 850
jumpForce = -260

-- Vitesse des tuyaux
basePipeSpeed = 190
pipeSpeed = 190

-- Taille des tuyaux
pipeWidth = 80
basePipeGap = 175
pipeGap = 175

-- Sol qui défile
groundOffset = 0

-- Menu
menuIndex = 1
difficultyIndex = 1

-- Boutique
shopSection = "bird"

difficultyOptions = {
    {
        key = "easy",
        label = "Facile",
        description = "Plus lent, plus d'espace et plus de temps pour apprendre."
    },
    {
        key = "normal",
        label = "Moyen",
        description = "Le rythme standard avec une progression équilibrée."
    },
    {
        key = "hard",
        label = "Difficile",
        description = "Plus rapide, plus serré et nettement plus exigeant."
    }
}

-- Skins très simples
birdSkins = {
    { name = "Oiseau jaune", cost = 0, body = { 1.00, 0.90, 0.10 }, wing = { 1.00, 0.70, 0.15 }, beak = { 1.00, 0.45, 0.10 } },
    { name = "Oiseau bleu", cost = 20, body = { 0.30, 0.65, 1.00 }, wing = { 0.20, 0.45, 0.90 }, beak = { 1.00, 0.75, 0.20 } },
    { name = "Oiseau rouge", cost = 40, body = { 1.00, 0.30, 0.25 }, wing = { 0.80, 0.15, 0.15 }, beak = { 1.00, 0.80, 0.25 } }
}

backgroundSkins = {
    { name = "Flappy Bird", cost = 0, file = "assets/background/flappy_bird.jpg" },
    { name = "Forêt", cost = 25, file = "assets/background/forest.jpg" },
    { name = "Maison", cost = 45, file = "assets/background/house.jpg" },
    { name = "Mario", cost = 65, file = "assets/background/mario.jpg" }
}

pipeSkins = {
    { name = "Tuyaux verts", cost = 0, main = { 0.08, 0.75, 0.18 }, line = { 0.02, 0.45, 0.08 } },
    { name = "Tuyaux glace", cost = 20, main = { 0.55, 0.88, 1.00 }, line = { 0.22, 0.55, 0.75 } },
    { name = "Tuyaux lave", cost = 35, main = { 0.92, 0.35, 0.10 }, line = { 0.55, 0.10, 0.04 } }
}

-- Ce que le joueur a déjà débloqué
unlockedBirds = { [1] = true }
unlockedBackgrounds = { [1] = true }
unlockedPipes = { [1] = true }

-- Ce que le joueur utilise en ce moment
selectedBird = 1
selectedBackground = 1
selectedPipe = 1

-- Étoiles pour le décor espace
stars = {}
clouds = {}

-- -------------------------------------------------------------------
-- OUTILS DE SAUVEGARDE
-- -------------------------------------------------------------------

-- Transforme un booleen en texte
function boolToText(value)
    if value then
        return "1"
    end

    return "0"
end

-- Sauvegarde une liste de true / false sous forme de texte
function saveList(name, list, count)
    local parts = {}

    for i = 1, count do
        parts[i] = boolToText(list[i] == true)
    end

    return name .. "=" .. table.concat(parts, ",")
end

-- Relit une liste de true / false depuis le texte
function parseList(text)
    local result = {}

    for value in string.gmatch(text, "[^,]+") do
        table.insert(result, value == "1")
    end

    return result
end

-- Ecrit la sauvegarde dans un fichier
function saveData()
    local lines = {
        "bestScore=" .. bestScore,
        "coins=" .. coins,
        "selectedBird=" .. selectedBird,
        "selectedBackground=" .. selectedBackground,
        "selectedPipe=" .. selectedPipe,
        saveList("unlockedBirds", unlockedBirds, #birdSkins),
        saveList("unlockedBackgrounds", unlockedBackgrounds, #backgroundSkins),
        saveList("unlockedPipes", unlockedPipes, #pipeSkins)
    }

    love.filesystem.write("save.txt", table.concat(lines, "\n"))
end

-- Lit la sauvegarde si elle existe
function loadData()
    if love.filesystem.getInfo("save.txt") == nil then
        return
    end

    local content = love.filesystem.read("save.txt")

    for line in string.gmatch(content, "[^\r\n]+") do
        local key, value = string.match(line, "([^=]+)=(.+)")

        if key == "bestScore" then
            bestScore = tonumber(value) or 0
        elseif key == "coins" then
            coins = tonumber(value) or 0
        elseif key == "selectedBird" then
            selectedBird = tonumber(value) or 1
        elseif key == "selectedBackground" then
            selectedBackground = tonumber(value) or 1
        elseif key == "selectedPipe" then
            selectedPipe = tonumber(value) or 1
        elseif key == "unlockedBirds" then
            local list = parseList(value)
            for i = 1, #list do
                unlockedBirds[i] = list[i]
            end
        elseif key == "unlockedBackgrounds" then
            local list = parseList(value)
            for i = 1, #list do
                unlockedBackgrounds[i] = list[i]
            end
        elseif key == "unlockedPipes" then
            local list = parseList(value)
            for i = 1, #list do
                unlockedPipes[i] = list[i]
            end
        end
    end
end

function resetProgress()
    bestScore = 0
    coins = 0
    coinsRun = 0

    unlockedBirds = { [1] = true }
    unlockedBackgrounds = { [1] = true }
    unlockedPipes = { [1] = true }

    selectedBird = 1
    selectedBackground = 1
    selectedPipe = 1

    difficultyMode = "normal"
    difficultyIndex = 1
    shopSection = "bird"
    state = "menu"

    clearRunObjects()
    resetBird()
    saveData()
end

-- -------------------------------------------------------------------
-- MISE EN PLACE DU JEU
-- -------------------------------------------------------------------

-- Replace l'oiseau au point de depart
function resetBird()
    bird.x = WINDOW_WIDTH * 0.18
    bird.y = WINDOW_HEIGHT * 0.40
    bird.width = 74
    bird.height = 62
    bird.speedY = 0
end

-- Vide les objets de la partie
function clearRunObjects()
    pipes = {}
    coinsOnMap = {}
end

function getDifficultySettings(mode)
    if mode == "easy" then
        return {
            gravityBase = 620,
            speedBase = 130,
            gapBase = 280,
            pipeInterval = 2.35,
            coinInterval = 2.80,
            minGap = 205,
            speedPerScore = 3,
            gravityPerScore = 14,
            gapPerScore = 1
        }
    elseif mode == "hard" then
        return {
            gravityBase = 1040,
            speedBase = 265,
            gapBase = 145,
            pipeInterval = 1.10,
            coinInterval = 5.20,
            minGap = 82,
            speedPerScore = 15,
            gravityPerScore = 64,
            gapPerScore = 7
        }
    end

    return {
        gravityBase = 830,
        speedBase = 185,
        gapBase = 205,
        pipeInterval = 1.55,
        coinInterval = 4.00,
        minGap = 118,
        speedPerScore = 9,
        gravityPerScore = 38,
        gapPerScore = 4
    }
end

-- Commence une nouvelle partie
function startRun(mode)
    difficultyMode = mode
    state = "playing"

    score = 0
    coinsRun = 0
    lives = maxLives

    pipeTimer = 0
    coinTimer = 0

    local settings = getDifficultySettings(mode)
    baseGravity = settings.gravityBase
    basePipeSpeed = settings.speedBase
    basePipeGap = settings.gapBase

    gravity = baseGravity
    pipeSpeed = basePipeSpeed
    pipeGap = basePipeGap
    groundOffset = 0

    clearRunObjects()
    resetBird()
end

-- Termine la partie
function finishRun()
    if score > bestScore then
        bestScore = score
    end

    coins = coins + coinsRun
    saveData()
    state = "gameover"
end

-- Retire une vie
function loseLife()
    lives = lives - 1

    if lives <= 0 then
        finishRun()
        return
    end

    -- On replace l'oiseau pour laisser une chance au joueur
    clearRunObjects()
    resetBird()
end

-- -------------------------------------------------------------------
-- GAMEPLAY
-- -------------------------------------------------------------------

-- Cree un tuyau
function spawnPipe()
    local pipe = {}
    pipe.x = WINDOW_WIDTH + 60
    if difficultyMode == "easy" then
        pipe.topHeight = love.math.random(95, 230)
    elseif difficultyMode == "hard" then
        pipe.topHeight = love.math.random(55, 300)
    else
        pipe.topHeight = love.math.random(75, 265)
    end
    pipe.passed = false
    table.insert(pipes, pipe)
end

-- Cree une piece a attraper
function spawnCoin()
    local item = {}
    item.x = WINDOW_WIDTH + 40
    item.y = love.math.random(120, GROUND_Y - 120)
    item.size = 16
    table.insert(coinsOnMap, item)
end

-- Teste si deux rectangles se touchent
function overlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and
        bx < ax + aw and
        ay < by + bh and
        by < ay + ah
end

-- Teste si l'oiseau touche un tuyau
function birdHitsPipe(pipe)
    local bottomY = pipe.topHeight + pipeGap

    local hitTop = overlap(bird.x, bird.y, bird.width, bird.height, pipe.x, 0, pipeWidth, pipe.topHeight)
    local hitBottom = overlap(bird.x, bird.y, bird.width, bird.height, pipe.x, bottomY, pipeWidth, GROUND_Y - bottomY)

    return hitTop or hitBottom
end

-- Teste si l'oiseau touche une piece
function birdHitsCoin(item)
    return overlap(bird.x, bird.y, bird.width, bird.height, item.x, item.y, item.size, item.size)
end

-- Fait monter la difficulte petit a petit
function updateDifficulty()
    local settings = getDifficultySettings(difficultyMode)
    local speedPlus = score * settings.speedPerScore
    local gravityPlus = score * settings.gravityPerScore
    local gapMinus = score * settings.gapPerScore

    pipeSpeed = basePipeSpeed + speedPlus
    gravity = baseGravity + gravityPlus
    pipeGap = basePipeGap - gapMinus

    if pipeGap < settings.minGap then
        pipeGap = settings.minGap
    end
end

-- Fait bouger et gere les tuyaux
function updatePipes(dt)
    pipeTimer = pipeTimer + dt

    local settings = getDifficultySettings(difficultyMode)

    if pipeTimer > settings.pipeInterval then
        pipeTimer = 0
        spawnPipe()
    end

    for i = #pipes, 1, -1 do
        local pipe = pipes[i]
        pipe.x = pipe.x - pipeSpeed * dt

        if pipe.passed == false and pipe.x + pipeWidth < bird.x then
            pipe.passed = true
            score = score + 1
            coinsRun = coinsRun + 1

            if score > bestScore then
                bestScore = score
            end
        end

        if birdHitsPipe(pipe) then
            loseLife()
            return
        end

        if pipe.x + pipeWidth < 0 then
            table.remove(pipes, i)
        end
    end
end

-- Fait bouger et gere les pieces
function updateCoins(dt)
    coinTimer = coinTimer + dt

    local settings = getDifficultySettings(difficultyMode)

    if coinTimer > settings.coinInterval then
        coinTimer = 0
        spawnCoin()
    end

    for i = #coinsOnMap, 1, -1 do
        local item = coinsOnMap[i]
        item.x = item.x - pipeSpeed * dt

        if birdHitsCoin(item) then
            coinsRun = coinsRun + 3
            table.remove(coinsOnMap, i)
        elseif item.x < -50 then
            table.remove(coinsOnMap, i)
        end
    end
end

-- -------------------------------------------------------------------
-- BOUTIQUE
-- -------------------------------------------------------------------

function buyOrSelectBird(index)
    local item = birdSkins[index]

    if item == nil then
        return
    end

    if unlockedBirds[index] then
        selectedBird = index
        saveData()
        return
    end

    if coins >= item.cost then
        coins = coins - item.cost
        unlockedBirds[index] = true
        selectedBird = index
        saveData()
    end
end

function buyOrSelectBackground(index)
    local item = backgroundSkins[index]

    if item == nil then
        return
    end

    if unlockedBackgrounds[index] then
        selectedBackground = index
        saveData()
        return
    end

    if coins >= item.cost then
        coins = coins - item.cost
        unlockedBackgrounds[index] = true
        selectedBackground = index
        saveData()
    end
end

function buyOrSelectPipe(index)
    local item = pipeSkins[index]

    if item == nil then
        return
    end

    if unlockedPipes[index] then
        selectedPipe = index
        saveData()
        return
    end

    if coins >= item.cost then
        coins = coins - item.cost
        unlockedPipes[index] = true
        selectedPipe = index
        saveData()
    end
end

-- -------------------------------------------------------------------
-- LOVE2D : CHARGEMENT
-- -------------------------------------------------------------------

function love.load()
    love.window.setTitle("Flappy Bird")

    -- Polices
    fontSmall = love.graphics.newFont(16)
    fontUI = love.graphics.newFont(24)
    fontTitle = love.graphics.newFont(42)
    fontScore = love.graphics.newFont(48)

    -- Sprite sheet personnalisé de l'oiseau principal.
    if love.filesystem.getInfo("assets/birds/bird1.png") then
        local ok, imageData = pcall(love.image.newImageData, "assets/birds/bird1.png")
        if ok then
            -- Remplace le fond noir par de la transparence.
            imageData:mapPixel(function(x, y, r, g, b, a)
                if r < 0.05 and g < 0.05 and b < 0.05 then
                    return r, g, b, 0
                end

                return r, g, b, a
            end)

            birdSprite = love.graphics.newImage(imageData)
            birdSprite:setFilter("nearest", "nearest")

            local frameWidth = math.floor(birdSprite:getWidth() / 2)
            local frameHeight = math.floor(birdSprite:getHeight() / 2)

            birdSpriteFrames = {
                love.graphics.newQuad(0, 0, frameWidth, frameHeight, birdSprite:getDimensions()),
                love.graphics.newQuad(frameWidth, 0, frameWidth, frameHeight, birdSprite:getDimensions()),
                love.graphics.newQuad(0, frameHeight, frameWidth, frameHeight, birdSprite:getDimensions())
            }
        end
    end

    for index, background in ipairs(backgroundSkins) do
        if background.file and love.filesystem.getInfo(background.file) then
            local ok, image = pcall(love.graphics.newImage, background.file)
            if ok then
                image:setFilter("linear", "linear")
                backgroundSprites[index] = image
            end
        end
    end

    -- Petites etoiles pour le decor espace
    for i = 1, 70 do
        local star = {}
        star.x = love.math.random(0, WINDOW_WIDTH)
        star.y = love.math.random(0, GROUND_Y - 20)
        table.insert(stars, star)
    end

    for i = 1, 7 do
        local cloud = {}
        cloud.x = love.math.random(-80, WINDOW_WIDTH)
        cloud.y = love.math.random(45, 220)
        cloud.w = love.math.random(90, 170)
        cloud.h = love.math.random(36, 62)
        cloud.speed = love.math.random(12, 24)
        table.insert(clouds, cloud)
    end

    resetBird()
    loadData()
    saveData()
end

-- -------------------------------------------------------------------
-- LOVE2D : CLAVIER / SOURIS
-- -------------------------------------------------------------------

-- Change l'option active du menu
function changeMenu(step)
    menuIndex = menuIndex + step

    if menuIndex < 1 then
        menuIndex = 4
    elseif menuIndex > 4 then
        menuIndex = 1
    end
end

function changeDifficulty(step)
    difficultyIndex = difficultyIndex + step

    if difficultyIndex < 1 then
        difficultyIndex = #difficultyOptions
    elseif difficultyIndex > #difficultyOptions then
        difficultyIndex = 1
    end
end

function love.keypressed(key)
    -- MENU PRINCIPAL
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

    if state == "reset_confirm" then
        if key == "return" or key == "space" then
            resetProgress()
        elseif key == "escape" then
            state = "menu"
        end
        return
    end

    -- CHOIX DE LA DIFFICULTE
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

    -- BOUTIQUE
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
        elseif key == "1" or key == "2" or key == "3" then
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

    -- PARTIE
    if state == "playing" then
        if key == "space" then
            bird.speedY = jumpForce
        elseif key == "p" then
            state = "paused"
        elseif key == "escape" then
            state = "menu"
            saveData()
        end
        return
    end

    -- PAUSE
    if state == "paused" then
        if key == "p" then
            state = "playing"
        elseif key == "escape" then
            state = "menu"
            saveData()
        end
        return
    end

    -- GAME OVER
    if state == "gameover" then
        if key == "return" then
            startRun(difficultyMode)
        elseif key == "escape" then
            state = "menu"
        end
    end
end

function love.mousepressed(x, y, button)
    if state == "playing" and button == 1 then
        bird.speedY = jumpForce
    end
end

-- -------------------------------------------------------------------
-- LOVE2D : UPDATE
-- -------------------------------------------------------------------

function love.update(dt)
    if birdSprite ~= nil and #birdSpriteFrames > 1 then
        birdSpriteFrameTimer = birdSpriteFrameTimer + dt

        if birdSpriteFrameTimer >= birdSpriteFrameDuration then
            birdSpriteFrameTimer = birdSpriteFrameTimer - birdSpriteFrameDuration
            birdSpriteFrameIndex = (birdSpriteFrameIndex % #birdSpriteFrames) + 1
        end
    end

    if selectedBackground ~= 3 then
        for i = 1, #clouds do
            local cloud = clouds[i]
            cloud.x = cloud.x + cloud.speed * dt

            if cloud.x > WINDOW_WIDTH + 120 then
                cloud.x = -cloud.w - love.math.random(20, 120)
                cloud.y = love.math.random(45, 220)
            end
        end
    end

    if state ~= "playing" then
        return
    end

    -- Difficulte progressive
    updateDifficulty()

    -- Sol qui defile
    groundOffset = (groundOffset + pipeSpeed * dt) % 48

    -- Gravite + mouvement de l'oiseau
    bird.speedY = bird.speedY + gravity * dt
    bird.y = bird.y + bird.speedY * dt

    -- Mouvements du jeu
    updatePipes(dt)
    updateCoins(dt)

    -- Collision avec le haut
    if bird.y < 0 then
        bird.y = 0
        loseLife()
    end

    -- Collision avec le sol
    if bird.y + bird.height > GROUND_Y then
        bird.y = GROUND_Y - bird.height
        loseLife()
    end
end

-- -------------------------------------------------------------------
-- DESSINS : PETITES PREVIEWS POUR LA BOUTIQUE
-- -------------------------------------------------------------------

function drawBirdPreview(index, x, y)
    local skin = birdSkins[index]

    if index == 1 and birdSprite ~= nil then
        local previewQuad = birdSpriteFrames[1]
        local frameWidth = math.floor(birdSprite:getWidth() / 2)
        local frameHeight = math.floor(birdSprite:getHeight() / 2)
        local scaleX = 44 / frameWidth
        local scaleY = 32 / frameHeight

        love.graphics.setColor(0, 0, 0, 0.95)
        love.graphics.draw(birdSprite, previewQuad, x - 1, y, 0, scaleX, scaleY)
        love.graphics.draw(birdSprite, previewQuad, x + 1, y, 0, scaleX, scaleY)
        love.graphics.draw(birdSprite, previewQuad, x, y - 1, 0, scaleX, scaleY)
        love.graphics.draw(birdSprite, previewQuad, x, y + 1, 0, scaleX, scaleY)

        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(birdSprite, previewQuad, x, y, 0, scaleX, scaleY)
        return
    end

    love.graphics.setColor(skin.body[1], skin.body[2], skin.body[3])
    love.graphics.rectangle("fill", x, y, 44, 32)

    love.graphics.setColor(skin.beak[1], skin.beak[2], skin.beak[3])
    love.graphics.rectangle("fill", x + 32, y + 11, 14, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x + 7, y + 7, 8, 8)

    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", x + 10, y + 10, 3, 3)

    love.graphics.setColor(skin.wing[1], skin.wing[2], skin.wing[3])
    love.graphics.rectangle("fill", x + 12, y + 21, 16, 7)
end

function drawBackgroundPreview(index, x, y, w, h)
    local image = backgroundSprites[index]

    if image ~= nil then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(image, x, y, 0, w / image:getWidth(), h / image:getHeight())
        return
    end

    love.graphics.setColor(0.45, 0.76, 1)
    love.graphics.rectangle("fill", x, y, w, h)
end

function drawPipePreview(index, x, y)
    local style = pipeSkins[index]

    love.graphics.setColor(style.main[1], style.main[2], style.main[3])
    love.graphics.rectangle("fill", x + 10, y, 18, 58)
    love.graphics.rectangle("fill", x + 42, y + 26, 18, 58)

    love.graphics.setColor(style.line[1], style.line[2], style.line[3])
    love.graphics.rectangle("line", x + 10, y, 18, 58)
    love.graphics.rectangle("line", x + 42, y + 26, 18, 58)
end

function getDifficultyLabel(mode)
    for i = 1, #difficultyOptions do
        if difficultyOptions[i].key == mode then
            return difficultyOptions[i].label
        end
    end

    return "Moyen"
end

function drawSoftPanel(x, y, w, h, borderColor)
    love.graphics.setColor(0, 0, 0, 0.22)
    love.graphics.rectangle("fill", x + 5, y + 6, w, h, 18, 18)
    love.graphics.setColor(0.08, 0.10, 0.16, 0.82)
    love.graphics.rectangle("fill", x, y, w, h, 18, 18)
    love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
    love.graphics.rectangle("line", x, y, w, h, 18, 18)
end

-- -------------------------------------------------------------------
-- DESSINS : ECRAN DE JEU
-- -------------------------------------------------------------------

function drawBackground()
    local background = backgroundSkins[selectedBackground]

    if selectedBackground == 1 then
        love.graphics.clear(0.45, 0.76, 1)
        love.graphics.setColor(1, 0.9, 0.3)
        love.graphics.circle("fill", 820, 90, 35)

        love.graphics.setColor(1, 1, 1, 0.75)
        for i = 1, #clouds do
            local cloud = clouds[i]
            love.graphics.ellipse("fill", cloud.x, cloud.y, cloud.w * 0.30, cloud.h * 0.52)
            love.graphics.ellipse("fill", cloud.x + cloud.w * 0.22, cloud.y - 8, cloud.w * 0.26, cloud.h * 0.46)
            love.graphics.ellipse("fill", cloud.x + cloud.w * 0.42, cloud.y, cloud.w * 0.28, cloud.h * 0.50)
        end

        love.graphics.setColor(0.65, 0.72, 0.82)
        for i = 0, 8 do
            love.graphics.rectangle("fill", i * 120, 270 + (i % 3) * 20, 70, 180)
        end
    elseif selectedBackground == 2 then
        love.graphics.clear(0.48, 0.82, 0.55)
        for i = 0, 11 do
            local x = i * 88
            love.graphics.setColor(0.42, 0.22, 0.08)
            love.graphics.rectangle("fill", x + 18, 310, 22, 140)
            love.graphics.setColor(0.12, 0.55, 0.16)
            love.graphics.rectangle("fill", x, 260, 58, 58)
            love.graphics.rectangle("fill", x + 10, 230, 38, 38)
        end
    else
        love.graphics.clear(0.03, 0.03, 0.08)
        love.graphics.setColor(1, 1, 1)
        for i = 1, #stars do
            local star = stars[i]
            love.graphics.points(star.x, star.y)
        end

        love.graphics.setColor(0.6, 0.2, 1)
        love.graphics.circle("line", 720, 110, 46)
        love.graphics.circle("line", 180, 80, 28)
    end

    -- Ombre juste avant le sol
    love.graphics.setColor(0, 0, 0, 0.12)
    love.graphics.rectangle("fill", 0, GROUND_Y - 14, WINDOW_WIDTH, 14)

    -- Sol principal
    love.graphics.setColor(0.30, 0.30, 0.30)
    love.graphics.rectangle("fill", 0, GROUND_Y, WINDOW_WIDTH, GROUND_HEIGHT)

    -- Petits blocs pour simuler le defilement du sol
    for i = -1, math.ceil(WINDOW_WIDTH / 48) + 1 do
        local x = i * 48 - groundOffset
        love.graphics.setColor(0.45, 0.45, 0.45)
        love.graphics.rectangle("fill", x, GROUND_Y + 10, 42, 26)
        love.graphics.setColor(0.22, 0.22, 0.22)
        love.graphics.rectangle("fill", x, GROUND_Y + 42, 42, 36)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontSmall)
    love.graphics.print("Décor : " .. background.name, 20, GROUND_Y + 28)
end

function drawBird()
    local skin = birdSkins[selectedBird]

    love.graphics.setColor(skin.body[1], skin.body[2], skin.body[3])
    love.graphics.rectangle("fill", bird.x, bird.y, bird.width, bird.height)

    love.graphics.setColor(skin.beak[1], skin.beak[2], skin.beak[3])
    love.graphics.rectangle("fill", bird.x + 26, bird.y + 10, 14, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", bird.x + 6, bird.y + 5, 8, 8)

    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", bird.x + 10, bird.y + 8, 3, 3)

    love.graphics.setColor(skin.wing[1], skin.wing[2], skin.wing[3])
    love.graphics.rectangle("fill", bird.x + 10, bird.y + 18, 14, 7)
end

function drawPipes()
    local style = pipeSkins[selectedPipe]

    for i = 1, #pipes do
        local pipe = pipes[i]
        local bottomY = pipe.topHeight + pipeGap

        love.graphics.setColor(style.main[1], style.main[2], style.main[3])
        love.graphics.rectangle("fill", pipe.x, 0, pipeWidth, pipe.topHeight)
        love.graphics.rectangle("fill", pipe.x, bottomY, pipeWidth, GROUND_Y - bottomY)

        love.graphics.setColor(style.line[1], style.line[2], style.line[3])
        love.graphics.rectangle("line", pipe.x, 0, pipeWidth, pipe.topHeight)
        love.graphics.rectangle("line", pipe.x, bottomY, pipeWidth, GROUND_Y - bottomY)
    end
end

function drawCoins()
    for i = 1, #coinsOnMap do
        local item = coinsOnMap[i]
        love.graphics.setColor(1, 0.9, 0.2)
        love.graphics.rectangle("fill", item.x, item.y, item.size, item.size)
        love.graphics.setColor(0.8, 0.55, 0.0)
        love.graphics.rectangle("line", item.x, item.y, item.size, item.size)
    end
end

function drawLivesAt(startX, startY)
    for i = 1, maxLives do
        if i <= lives then
            love.graphics.setColor(1, 0.3, 0.3)
        else
            love.graphics.setColor(0.4, 0.2, 0.2)
        end

        love.graphics.rectangle("fill", startX + (i - 1) * 28, startY, 20, 18)
    end
end

function drawGameUI()
    drawSoftPanel(WINDOW_WIDTH - 290, 16, 262, 166, { 1, 1, 1, 0.18 })
    drawSoftPanel(16, GROUND_Y - 110, 360, 82, { 1, 1, 1, 0.18 })

    -- Gros score en haut
    love.graphics.setFont(fontScore)
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.printf(tostring(score), 2, 16, WINDOW_WIDTH, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(tostring(score), 0, 14, WINDOW_WIDTH, "center")

    -- Infos à gauche
    love.graphics.setFont(fontUI)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Meilleur : " .. bestScore, WINDOW_WIDTH - 270, 34)
    love.graphics.print("Pièces : " .. (coins + coinsRun), 20, 92)
    love.graphics.print("Mode : " .. getDifficultyLabel(difficultyMode), WINDOW_WIDTH - 270, 106)

    love.graphics.setFont(fontSmall)
    love.graphics.print("Poids : " .. math.floor(gravity), 20, 152)
    love.graphics.print("Vitesse : " .. math.floor(pipeSpeed), 20, 172)
    love.graphics.print("Espace tuyaux : " .. math.floor(pipeGap), 20, 192)
    love.graphics.print("P = pause", 20, 220)
end

-- -------------------------------------------------------------------
-- DESSINS : MENU ET BOUTIQUE
-- -------------------------------------------------------------------

function drawMenu()
    drawBackground()

    local panelWidth = 520
    local panelHeight = 320
    local panelX = (WINDOW_WIDTH - panelWidth) / 2
    local panelY = WINDOW_HEIGHT * 0.17
    local titleY = panelY + 34
    local firstItemY = panelY + 120
    local helpY = panelY + 252
    local scoreY = panelY + 282

    drawSoftPanel(panelX, panelY, panelWidth, panelHeight, { 1, 0.86, 0.25, 0.55 })

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.printf("Flappy Bird", 2, titleY + 2, WINDOW_WIDTH, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Flappy Bird", 0, titleY, WINDOW_WIDTH, "center")

    local items = {
        "Jouer",
        "Boutique",
        "Reset",
        "Quitter"
    }

    love.graphics.setFont(fontUI)
    for i = 1, #items do
        if i == menuIndex then
            love.graphics.setColor(1, 0.9, 0.2)
        else
            love.graphics.setColor(1, 1, 1)
        end

        love.graphics.printf(items[i], 0, firstItemY + (i - 1) * 56, WINDOW_WIDTH, "center")
    end

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Haut / Bas pour choisir - Entrée pour valider", 0, helpY, WINDOW_WIDTH, "center")
    love.graphics.printf("Meilleur score : " .. bestScore .. "   Pièces : " .. coins, 0, scoreY, WINDOW_WIDTH, "center")
end

function drawDifficultyMenu()
    drawBackground()

    local panelWidth = 760
    local panelHeight = 360
    local panelX = (WINDOW_WIDTH - panelWidth) / 2
    local panelY = WINDOW_HEIGHT * 0.18
    local titleY = panelY + 28
    local firstItemY = panelY + 102
    local helpY = panelY + 314

    drawSoftPanel(panelX, panelY, panelWidth, panelHeight, { 0.55, 0.82, 1, 0.55 })

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.printf("Choix de la difficulté", 2, titleY + 2, WINDOW_WIDTH, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Choix de la difficulté", 0, titleY, WINDOW_WIDTH, "center")

    for i = 1, #difficultyOptions do
        local item = difficultyOptions[i]
        local cardX = panelX + 34
        local cardY = firstItemY + (i - 1) * 66
        local cardWidth = panelWidth - 68
        local isSelected = i == difficultyIndex

        if isSelected then
            drawSoftPanel(cardX, cardY, cardWidth, 56, { 1, 0.88, 0.24, 0.90 })
        else
            drawSoftPanel(cardX, cardY, cardWidth, 56, { 1, 1, 1, 0.10 })
        end

        love.graphics.setFont(fontUI)
        if isSelected then
            love.graphics.setColor(1, 0.9, 0.2)
        else
            love.graphics.setColor(1, 1, 1)
        end

        love.graphics.print(item.label, cardX + 18, cardY + 8)
        love.graphics.setFont(fontSmall)
        love.graphics.setColor(0.88, 0.92, 1)
        love.graphics.print(item.description, cardX + 18, cardY + 32)
    end

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Haut / Bas pour choisir - EntrÃ©e pour valider - Ã‰chap pour retour", 0, helpY, WINDOW_WIDTH, "center")
    love.graphics.printf("Haut / Bas pour choisir - Entrée pour valider - Échap pour retour", 0, helpY, WINDOW_WIDTH, "center")
end

function drawShopCard(category, index, item, unlocked, selected, x, y, w, h)
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.rectangle("fill", x + 4, y + 4, w, h, 10, 10)

    if selected then
        love.graphics.setColor(0.20, 0.60, 0.25, 0.95)
    elseif shopSection == category then
        love.graphics.setColor(0.18, 0.20, 0.28, 0.95)
    else
        love.graphics.setColor(0.14, 0.16, 0.22, 0.88)
    end
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    if selected then
        love.graphics.setColor(1, 0.92, 0.25)
    else
        love.graphics.setColor(0.32, 0.36, 0.48)
    end
    love.graphics.rectangle("line", x, y, w, h, 10, 10)

    if category == "bird" then
        drawBirdPreview(index, x + 18, y + 20)
    elseif category == "background" then
        drawBackgroundPreview(index, x + 8, y + 14, 66, 52)
    else
        drawPipePreview(index, x + 8, y + 10)
    end

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(index .. ". " .. item.name, x + 10, y + 88)

    local status = ""
    if selected then
        status = "Equipe"
    elseif unlocked then
        status = "Disponible"
    else
        status = item.cost .. " pièces"
    end

    if selected then
        love.graphics.setColor(1, 0.92, 0.25)
    elseif unlocked then
        love.graphics.setColor(0.75, 1, 0.75)
    else
        love.graphics.setColor(1, 0.75, 0.75)
    end
    love.graphics.print(status, x + 10, y + 108)
end

function drawShopSection(title, category, list, unlockedList, selected, x, y)
    love.graphics.setFont(fontUI)
    if shopSection == category then
        love.graphics.setColor(1, 0.92, 0.25)
    else
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.print(title, x, y)

    for i = 1, #list do
        local cardX = x + (i - 1) * 88
        drawShopCard(category, i, list[i], unlockedList[i] == true, selected == i, cardX, y + 42, 82, 132)
    end
end

function drawShop()
    drawBackground()

    local panelWidth = 904
    local panelHeight = 236
    local panelX = (WINDOW_WIDTH - panelWidth) / 2
    local panelY = WINDOW_HEIGHT * 0.36
    local sectionY = panelY + 18

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Boutique", 0, WINDOW_HEIGHT * 0.08, WINDOW_WIDTH, "center")

    love.graphics.setFont(fontUI)
    love.graphics.print("Pièces : " .. coins, panelX + 12, WINDOW_HEIGHT * 0.19)

    love.graphics.setFont(fontSmall)
    love.graphics.print("Tab = changer de catégorie", panelX + 12, WINDOW_HEIGHT * 0.24)
    love.graphics.print("1, 2, 3 = acheter ou équiper", panelX + 12, WINDOW_HEIGHT * 0.27)
    love.graphics.print("Échap = retour au menu", panelX + 12, WINDOW_HEIGHT * 0.30)

    love.graphics.setColor(0, 0, 0, 0.30)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 16, 16)

    drawShopSection("Oiseaux", "bird", birdSkins, unlockedBirds, selectedBird, panelX + 20, sectionY)
    drawShopSection("Décors", "background", backgroundSkins, unlockedBackgrounds, selectedBackground, panelX + 320, sectionY)
    drawShopSection("Tuyaux", "pipe", pipeSkins, unlockedPipes, selectedPipe, panelX + 620, sectionY)
end

function drawDifficultyMenu()
    drawBackground()

    local panelWidth = 760
    local panelHeight = 360
    local panelX = (WINDOW_WIDTH - panelWidth) / 2
    local panelY = WINDOW_HEIGHT * 0.18
    local titleY = panelY + 28
    local firstItemY = panelY + 102
    local helpY = panelY + 314

    drawSoftPanel(panelX, panelY, panelWidth, panelHeight, { 0.55, 0.82, 1, 0.55 })

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.printf("Choix de la difficulte", 2, titleY + 2, WINDOW_WIDTH, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Choix de la difficulté", 0, titleY, WINDOW_WIDTH, "center")

    for i = 1, #difficultyOptions do
        local item = difficultyOptions[i]
        local cardX = panelX + 34
        local cardY = firstItemY + (i - 1) * 66
        local cardWidth = panelWidth - 68
        local isSelected = i == difficultyIndex

        if isSelected then
            drawSoftPanel(cardX, cardY, cardWidth, 56, { 1, 0.88, 0.24, 0.90 })
        else
            drawSoftPanel(cardX, cardY, cardWidth, 56, { 1, 1, 1, 0.10 })
        end

        love.graphics.setFont(fontUI)
        if isSelected then
            love.graphics.setColor(1, 0.9, 0.2)
        else
            love.graphics.setColor(1, 1, 1)
        end

        love.graphics.print(item.label, cardX + 18, cardY + 8)
        love.graphics.setFont(fontSmall)
        love.graphics.setColor(0.88, 0.92, 1)
        love.graphics.print(item.description, cardX + 18, cardY + 32)
    end

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Haut / Bas pour choisir - Entrée pour valider - Échap pour retour", 0, helpY, WINDOW_WIDTH, "center")
end

function drawGameUI()
    drawSoftPanel(WINDOW_WIDTH - 290, 16, 262, 166, { 1, 1, 1, 0.18 })
    drawSoftPanel(16, GROUND_Y - 126, 430, 102, { 1, 1, 1, 0.18 })

    love.graphics.setFont(fontScore)
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.printf(tostring(score), 2, 16, WINDOW_WIDTH, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(tostring(score), 0, 14, WINDOW_WIDTH, "center")

    love.graphics.setFont(fontUI)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Meilleur : " .. bestScore, WINDOW_WIDTH - 270, 34)
    love.graphics.print("Pièces : " .. (coins + coinsRun), WINDOW_WIDTH - 270, 70)
    love.graphics.print("Mode : " .. getDifficultyLabel(difficultyMode), WINDOW_WIDTH - 270, 106)

    love.graphics.setFont(fontSmall)
    love.graphics.print("Poids : " .. math.floor(gravity), WINDOW_WIDTH - 270, 140)

    love.graphics.setFont(fontUI)
    drawLivesAt(34, GROUND_Y - 84)

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Vitesse : " .. math.floor(pipeSpeed), 156, GROUND_Y - 94)
    love.graphics.print("Espace tuyaux : " .. math.floor(pipeGap), 156, GROUND_Y - 68)
    love.graphics.print("P = pause", 156, GROUND_Y - 42)
end

function drawPaused()
    drawBackground()
    drawPipes()
    drawCoins()
    drawBird()
    drawGameUI()

    local boxWidth = 420
    local boxHeight = 130
    local boxX = (WINDOW_WIDTH - boxWidth) / 2
    local boxY = (WINDOW_HEIGHT - boxHeight) / 2

    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight)

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Pause", 0, boxY + 20, WINDOW_WIDTH, "center")

    love.graphics.setFont(fontSmall)
    love.graphics.printf("P pour reprendre - Échap pour le menu", 0, boxY + 76, WINDOW_WIDTH, "center")
end

function drawGameOver()
    drawBackground()
    drawPipes()
    drawCoins()
    drawBird()
    drawGameUI()

    local boxWidth = 520
    local boxHeight = 170
    local boxX = (WINDOW_WIDTH - boxWidth) / 2
    local boxY = (WINDOW_HEIGHT - boxHeight) / 2

    love.graphics.setColor(0, 0, 0, 0.48)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight)

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Game Over", 0, boxY + 18, WINDOW_WIDTH, "center")

    love.graphics.setFont(fontUI)
    love.graphics.printf("Score : " .. score .. "   Pièces gagnées : " .. coinsRun, 0, boxY + 72, WINDOW_WIDTH, "center")

    love.graphics.setFont(fontSmall)
    love.graphics.printf("Entrée = recommencer   Échap = menu", 0, boxY + 120, WINDOW_WIDTH, "center")
end

function drawGameOver()
    drawBackground()
    drawPipes()
    drawCoins()
    drawBird()
    drawGameUI()

    local boxWidth = 620
    local boxHeight = 280
    local boxX = (WINDOW_WIDTH - boxWidth) / 2
    local boxY = (WINDOW_HEIGHT - boxHeight) / 2

    drawSoftPanel(boxX, boxY, boxWidth, boxHeight, { 1, 0.35, 0.30, 0.80 })

    love.graphics.setColor(1, 0.30, 0.30, 0.12)
    love.graphics.rectangle("fill", boxX + 16, boxY + 18, boxWidth - 32, 60, 14, 14)

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Game Over", 0, boxY + 24, WINDOW_WIDTH, "center")

    love.graphics.setFont(fontUI)
    love.graphics.setColor(1, 0.92, 0.25)
    love.graphics.printf("Résultat de la partie", 0, boxY + 92, WINDOW_WIDTH, "center")

    drawSoftPanel(boxX + 42, boxY + 128, 160, 92, { 1, 1, 1, 0.12 })
    drawSoftPanel(boxX + 230, boxY + 128, 160, 92, { 1, 1, 1, 0.12 })
    drawSoftPanel(boxX + 418, boxY + 128, 160, 92, { 1, 1, 1, 0.12 })

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.85, 0.90, 1)
    love.graphics.printf("Score final", boxX + 42, boxY + 144, 160, "center")
    love.graphics.printf("Pièces gagnées", boxX + 230, boxY + 144, 160, "center")
    love.graphics.printf("Meilleur score", boxX + 418, boxY + 144, 160, "center")

    love.graphics.setFont(fontScore)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(tostring(score), boxX + 42, boxY + 166, 160, "center")
    love.graphics.printf(tostring(coinsRun), boxX + 230, boxY + 166, 160, "center")
    love.graphics.printf(tostring(bestScore), boxX + 418, boxY + 166, 160, "center")

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Entrée = recommencer   Échap = menu", 0, boxY + 240, WINDOW_WIDTH, "center")
end

function drawPlaying()
    drawBackground()
    drawPipes()
    drawCoins()
    drawBird()
    drawGameUI()
end

function drawBackground()
    local background = backgroundSkins[selectedBackground]
    local image = backgroundSprites[selectedBackground]

    if image ~= nil then
        love.graphics.clear(0.42, 0.75, 0.98)
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(image, 0, 0, 0, WINDOW_WIDTH / image:getWidth(), GROUND_Y / image:getHeight())
    else
        love.graphics.clear(0.42, 0.75, 0.98)
    end

    love.graphics.setColor(0, 0, 0, 0.08)
    love.graphics.rectangle("fill", 0, GROUND_Y - 26, WINDOW_WIDTH, 26)

    love.graphics.setColor(0.33, 0.33, 0.36)
    love.graphics.rectangle("fill", 0, GROUND_Y, WINDOW_WIDTH, GROUND_HEIGHT)
    love.graphics.setColor(0.46, 0.46, 0.50)
    love.graphics.rectangle("fill", 0, GROUND_Y, WINDOW_WIDTH, 10)

    for i = -1, math.ceil(WINDOW_WIDTH / 48) + 1 do
        local x = i * 48 - groundOffset
        love.graphics.setColor(0.48, 0.48, 0.52)
        love.graphics.rectangle("fill", x, GROUND_Y + 12, 42, 24, 4, 4)
        love.graphics.setColor(0.24, 0.24, 0.26)
        love.graphics.rectangle("fill", x, GROUND_Y + 42, 42, 32, 4, 4)
    end

    love.graphics.setColor(1, 1, 1, 0.86)
    love.graphics.setFont(fontSmall)
    love.graphics.print("Décor : " .. background.name, 20, GROUND_Y + 28)
end

function drawBird()
    local skin = birdSkins[selectedBird]
    local angle = math.max(-0.35, math.min(0.65, bird.speedY / 420))
    local cx = bird.x + bird.width / 2
    local cy = bird.y + bird.height / 2

    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.rotate(angle)

    love.graphics.setColor(0, 0, 0, 0.16)
    love.graphics.ellipse("fill", 2, bird.height / 2 + 8, 18, 8)

    if selectedBird == 1 and birdSprite ~= nil then
        local activeQuad = birdSpriteFrames[birdSpriteFrameIndex] or birdSpriteFrames[1]
        local frameWidth = math.floor(birdSprite:getWidth() / 2)
        local frameHeight = math.floor(birdSprite:getHeight() / 2)
        local scaleX = bird.width / frameWidth
        local scaleY = bird.height / frameHeight

        love.graphics.setColor(0, 0, 0, 0.95)
        love.graphics.draw(
            birdSprite,
            activeQuad,
            -bird.width / 2 - 2,
            -bird.height / 2,
            0,
            scaleX,
            scaleY
        )
        love.graphics.draw(
            birdSprite,
            activeQuad,
            -bird.width / 2 + 2,
            -bird.height / 2,
            0,
            scaleX,
            scaleY
        )
        love.graphics.draw(
            birdSprite,
            activeQuad,
            -bird.width / 2,
            -bird.height / 2 - 2,
            0,
            scaleX,
            scaleY
        )
        love.graphics.draw(
            birdSprite,
            activeQuad,
            -bird.width / 2,
            -bird.height / 2 + 2,
            0,
            scaleX,
            scaleY
        )

        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(
            birdSprite,
            activeQuad,
            -bird.width / 2,
            -bird.height / 2,
            0,
            scaleX,
            scaleY
        )
        love.graphics.pop()
        return
    end

    love.graphics.setColor(skin.body[1], skin.body[2], skin.body[3])
    love.graphics.ellipse("fill", 0, 0, 20, 15)

    love.graphics.setColor(math.min(1, skin.body[1] + 0.12), math.min(1, skin.body[2] + 0.12), math.min(1, skin.body[3] + 0.12))
    love.graphics.ellipse("fill", -5, -4, 11, 7)

    love.graphics.setColor(skin.wing[1], skin.wing[2], skin.wing[3])
    love.graphics.ellipse("fill", -3, 4, 10, 6)

    love.graphics.setColor(skin.beak[1], skin.beak[2], skin.beak[3])
    love.graphics.polygon("fill", 12, 0, 24, 4, 12, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", 5, -5, 5)
    love.graphics.setColor(0.05, 0.05, 0.05)
    love.graphics.circle("fill", 7, -5, 2)

    love.graphics.pop()
end

function drawPipes()
    local style = pipeSkins[selectedPipe]

    for i = 1, #pipes do
        local pipe = pipes[i]
        local bottomY = pipe.topHeight + pipeGap

        love.graphics.setColor(0, 0, 0, 0.14)
        love.graphics.rectangle("fill", pipe.x + 6, 0, pipeWidth, pipe.topHeight)
        love.graphics.rectangle("fill", pipe.x + 6, bottomY, pipeWidth, GROUND_Y - bottomY)

        love.graphics.setColor(style.main[1], style.main[2], style.main[3])
        love.graphics.rectangle("fill", pipe.x, 0, pipeWidth, pipe.topHeight)
        love.graphics.rectangle("fill", pipe.x, bottomY, pipeWidth, GROUND_Y - bottomY)

        love.graphics.setColor(math.min(1, style.main[1] + 0.12), math.min(1, style.main[2] + 0.12), math.min(1, style.main[3] + 0.12))
        love.graphics.rectangle("fill", pipe.x + 8, 0, 12, pipe.topHeight)
        love.graphics.rectangle("fill", pipe.x + 8, bottomY, 12, GROUND_Y - bottomY)

        love.graphics.setColor(style.main[1] * 0.85, style.main[2] * 0.85, style.main[3] * 0.85)
        love.graphics.rectangle("fill", pipe.x - 6, pipe.topHeight - 18, pipeWidth + 12, 18, 5, 5)
        love.graphics.rectangle("fill", pipe.x - 6, bottomY, pipeWidth + 12, 18, 5, 5)

        love.graphics.setColor(style.line[1], style.line[2], style.line[3])
        love.graphics.rectangle("line", pipe.x, 0, pipeWidth, pipe.topHeight)
        love.graphics.rectangle("line", pipe.x, bottomY, pipeWidth, GROUND_Y - bottomY)
    end
end

function drawCoins()
    for i = 1, #coinsOnMap do
        local item = coinsOnMap[i]
        local cx = item.x + item.size / 2
        local cy = item.y + item.size / 2

        love.graphics.setColor(1, 0.78, 0.10, 0.18)
        love.graphics.circle("fill", cx, cy, item.size)
        love.graphics.setColor(1, 0.88, 0.20)
        love.graphics.circle("fill", cx, cy, item.size / 2 + 2)
        love.graphics.setColor(0.88, 0.56, 0.04)
        love.graphics.circle("line", cx, cy, item.size / 2 + 2)
        love.graphics.line(cx, cy - 5, cx, cy + 5)
    end
end

function drawMenu()
    drawBackground()

    local panelWidth = 560
    local panelHeight = 430
    local panelX = (WINDOW_WIDTH - panelWidth) / 2
    local panelY = WINDOW_HEIGHT * 0.11
    local titleY = panelY + 34
    local subtitleY = panelY + 92
    local firstItemY = panelY + 150
    local footerY = panelY + 372

    drawSoftPanel(panelX, panelY, panelWidth, panelHeight, { 1, 0.86, 0.25, 0.60 })

    love.graphics.setColor(1, 0.92, 0.30, 0.16)
    love.graphics.circle("fill", panelX + 88, panelY + 74, 52)
    love.graphics.circle("fill", panelX + panelWidth - 92, panelY + 76, 40)

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.printf("Flappy Bird", 2, titleY + 2, WINDOW_WIDTH, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Flappy Bird", 0, titleY, WINDOW_WIDTH, "center")

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.86, 0.92, 1)
    love.graphics.printf("Boutique, difficultés et meilleur score à battre", 0, subtitleY, WINDOW_WIDTH, "center")

    local items = {
        "Jouer",
        "Boutique",
        "Reset",
        "Quitter"
    }

    for i = 1, #items do
        local y = firstItemY + (i - 1) * 56
        if i == menuIndex then
            drawSoftPanel(panelX + 86, y - 8, panelWidth - 172, 44, { 1, 0.88, 0.24, 0.90 })
            love.graphics.setColor(1, 0.92, 0.25)
        else
            love.graphics.setColor(1, 1, 1)
        end

        love.graphics.setFont(fontUI)
        love.graphics.printf(items[i], 0, y, WINDOW_WIDTH, "center")
    end

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Haut / Bas pour choisir - Entrée pour valider", 0, footerY, WINDOW_WIDTH, "center")
    love.graphics.printf("Meilleur score : " .. bestScore .. "   Pièces : " .. coins, 0, footerY + 24, WINDOW_WIDTH, "center")
end

function drawPlaying()
    drawBackground()

    love.graphics.setColor(1, 1, 1, 0.06)
    for i = 0, 7 do
        love.graphics.rectangle("fill", i * 180, 0, 2, GROUND_Y)
    end

    drawPipes()
    drawCoins()
    drawBird()
    drawGameUI()
end

function drawResetConfirm()
    drawBackground()

    local boxWidth = 620
    local boxHeight = 240
    local boxX = (WINDOW_WIDTH - boxWidth) / 2
    local boxY = (WINDOW_HEIGHT - boxHeight) / 2

    drawSoftPanel(boxX, boxY, boxWidth, boxHeight, { 1, 0.30, 0.30, 0.85 })

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Reset du jeu", 0, boxY + 28, WINDOW_WIDTH, "center")

    love.graphics.setFont(fontUI)
    love.graphics.setColor(1, 0.92, 0.25)
    love.graphics.printf("Cette action remet toute la progression à zéro.", 0, boxY + 94, WINDOW_WIDTH, "center")

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.90, 0.94, 1)
    love.graphics.printf("Scores, pièces, skins débloqués et sélections seront effacés.", 0, boxY + 132, WINDOW_WIDTH, "center")
    love.graphics.printf("Entrée = confirmer   Échap = annuler", 0, boxY + 178, WINDOW_WIDTH, "center")

end

-- -------------------------------------------------------------------
-- LOVE2D : DRAW
-- -------------------------------------------------------------------

function love.draw()
    if state == "menu" then
        drawMenu()
    elseif state == "reset_confirm" then
        drawResetConfirm()
    elseif state == "difficulty" then
        drawDifficultyMenu()
    elseif state == "shop" then
        drawShop()
    elseif state == "playing" then
        drawPlaying()
    elseif state == "paused" then
        drawPaused()
    elseif state == "gameover" then
        drawGameOver()
    end
end

