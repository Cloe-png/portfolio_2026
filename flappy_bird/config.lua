-- Configuration générale, état global et logique de jeu.

-- Taille de la fenêtre et zone de sol.
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

GROUND_HEIGHT = 90
GROUND_Y = WINDOW_HEIGHT - GROUND_HEIGHT

-- État courant du jeu.
state = "menu"
difficultyMode = "normal"

-- Objets de gameplay.
bird = {}
pipes = {}
coinsOnMap = {}

-- Progression de la partie et progression sauvegardée.
score = 0
bestScore = 0
coins = 0
coinsRun = 0
lives = 3
maxLives = 3

pipeTimer = 0
coinTimer = 0

baseGravity = 850
gravity = 850
jumpForce = -260

basePipeSpeed = 190
pipeSpeed = 190

pipeWidth = 96
basePipeGap = 175
pipeGap = 175

groundOffset = 0
menuIndex = 1
difficultyIndex = 1
shopSection = "bird"

-- Références de sprites chargées à l'exécution.
birdSprite = nil
birdSprites = {}
birdSpriteData = {}
birdSpriteFrames = {}
birdSpriteFrameIndex = 1
birdSpriteFrameTimer = 0
birdSpriteFrameDuration = 0.11

backgroundSprites = {}

coinSprite = nil
coinSpriteFrames = {}
coinSpriteFrameIndex = 1
coinSpriteFrameTimer = 0
coinSpriteFrameDuration = 0.12

heartsSprite = nil
heartFullQuad = nil
heartEmptyQuad = nil

pipeSprites = {}
pipeSpriteData = {}
rainbowPipeIndex = nil

stars = {}
clouds = {}

coinFrameWidth = 1
coinFrameHeight = 1
heartFrameWidth = 1
heartFrameHeight = 1

-- Données statiques visibles dans les menus.
difficultyOptions = {
    { key = "easy", label = "Facile" },
    { key = "normal", label = "Moyen" },
    { key = "hard", label = "Difficile" }
}

birdSkins = {
    { name = "Oiseau", cost = 0, file = "assets/birds/bird1.png", columns = 2, rows = 2, frameOrder = { 1, 2, 3 } },
    { name = "Cat", cost = 55, file = "assets/birds/cat.png", columns = 2, rows = 2, frameOrder = { 1, 2, 3, 4 } },
    { name = "Mario Tanuki", cost = 110, file = "assets/birds/mario_tanuki.png", columns = 2, rows = 2, frameOrder = { 1, 2, 3 } }
}

backgroundSkins = {
    { name = "Flappy Bird", cost = 0, file = "assets/background/flappy_bird.jpg" },
    { name = "Forêt", cost = 70, file = "assets/background/forest.jpg" },
    { name = "Maison", cost = 120, file = "assets/background/house.jpg" },
    { name = "Mario", cost = 170, file = "assets/background/mario.jpg" }
}

pipeSkins = {}

unlockedBirds = { [1] = true }
unlockedBackgrounds = { [1] = true }
unlockedPipes = { [1] = true }

selectedBird = 1
selectedBackground = 1
selectedPipe = 1

-- -------------------------------------------------------------------
-- SAUVEGARDE
-- -------------------------------------------------------------------

-- Transforme un booléen en texte pour la sauvegarde.
function boolToText(value)
    if value then
        return "1"
    end

    return "0"
end

function saveList(name, list, count)
    local parts = {}

    for i = 1, count do
        parts[i] = boolToText(list[i] == true)
    end

    return name .. "=" .. table.concat(parts, ",")
end

function parseList(text)
    local result = {}

    for value in string.gmatch(text, "[^,]+") do
        table.insert(result, value == "1")
    end

    return result
end

-- Ecrit la progression du joueur dans save.txt.
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

-- Recharge la progression si une sauvegarde existe déjà.
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

-- Corrige les sélections si la sauvegarde contient des index invalides.
function sanitizeSelections()
    if selectedBird < 1 or selectedBird > #birdSkins then
        selectedBird = 1
    end

    if selectedBackground < 1 or selectedBackground > #backgroundSkins then
        selectedBackground = 1
    end

    if selectedPipe < 1 or selectedPipe > #pipeSkins then
        selectedPipe = 1
    end

    if rainbowPipeIndex ~= nil and selectedPipe == rainbowPipeIndex then
        selectedPipe = 1
    end
end

-- Remet toute la progression à zéro.
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

-- Débloque les contenus liés au score global.
function syncSpecialUnlocks()
    for index, item in ipairs(pipeSkins) do
        if item.unlockScore ~= nil and bestScore >= item.unlockScore then
            unlockedPipes[index] = true

            if item.key == "rainbow" then
                rainbowPipeIndex = index
            end
        end
    end
end

-- -------------------------------------------------------------------
-- ÉTAT DE PARTIE
-- -------------------------------------------------------------------

-- Replace l'oiseau à sa position de départ.
function resetBird()
    bird.x = WINDOW_WIDTH * 0.18
    bird.y = WINDOW_HEIGHT * 0.40
    bird.width = 74
    bird.height = 62
    bird.speedY = 0
end

-- Vide les objets actifs de la partie.
function clearRunObjects()
    pipes = {}
    coinsOnMap = {}
end

-- Retourne les valeurs de base pour la difficulté choisie.
function getDifficultySettings(mode)
    if mode == "easy" then
        return {
            gravityBase = 620,
            speedBase = 130,
            gapBase = 280,
            pipeInterval = 2.80,
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
            pipeInterval = 1.40,
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
        pipeInterval = 1.80,
        coinInterval = 4.00,
        minGap = 118,
        speedPerScore = 9,
        gravityPerScore = 38,
        gapPerScore = 4
    }
end

-- Demarre une nouvelle partie.
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

-- Termine la partie et persiste les gains.
function finishRun()
    if score > bestScore then
        bestScore = score
    end

    coins = coins + coinsRun
    syncSpecialUnlocks()
    saveData()
    state = "gameover"
end

-- Retire une vie puis replace le joueur si besoin.
function loseLife()
    lives = lives - 1

    if lives <= 0 then
        playSound("gameover")
        finishRun()
        return
    end

    playSound("hit")
    clearRunObjects()
    resetBird()
end

-- -------------------------------------------------------------------
-- GAMEPLAY
-- -------------------------------------------------------------------

-- Crée un tuyau avec une hauteur adaptée à la difficulté.
function spawnPipe()
    local pipe = { x = WINDOW_WIDTH + 60, passed = false }

    if difficultyMode == "easy" then
        pipe.topHeight = love.math.random(95, 230)
    elseif difficultyMode == "hard" then
        pipe.topHeight = love.math.random(55, 300)
    else
        pipe.topHeight = love.math.random(75, 265)
    end

    table.insert(pipes, pipe)
end

-- Crée une pièce à ramasser.
function spawnCoin()
    local item = {}
    item.x = WINDOW_WIDTH + 40
    item.y = love.math.random(120, GROUND_Y - 120)
    item.size = 16
    table.insert(coinsOnMap, item)
end

-- Collision rectangle / rectangle.
function overlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and
        bx < ax + aw and
        ay < by + bh and
        by < ay + ah
end

-- Vérifie si l'oiseau touche un tuyau.
function birdHitsPipe(pipe)
    local bottomY = pipe.topHeight + pipeGap

    local hitTop = overlap(bird.x, bird.y, bird.width, bird.height, pipe.x, 0, pipeWidth, pipe.topHeight)
    local hitBottom = overlap(bird.x, bird.y, bird.width, bird.height, pipe.x, bottomY, pipeWidth, GROUND_Y - bottomY)

    return hitTop or hitBottom
end

-- Vérifie si l'oiseau ramasse une pièce.
function birdHitsCoin(item)
    return overlap(bird.x, bird.y, bird.width, bird.height, item.x, item.y, item.size, item.size)
end

-- Ajuste vitesse, gravité et taille de gap selon le score.
function updateDifficulty()
    local settings = getDifficultySettings(difficultyMode)
    pipeSpeed = basePipeSpeed + score * settings.speedPerScore
    gravity = baseGravity + score * settings.gravityPerScore
    pipeGap = basePipeGap - score * settings.gapPerScore

    if pipeGap < settings.minGap then
        pipeGap = settings.minGap
    end
end

-- Fait avancer les tuyaux, gère les collisions et le score.
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
            playSound("score")

            if score > bestScore then
                bestScore = score
                syncSpecialUnlocks()
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

-- Fait avancer les pièces et gère leur collecte.
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
            playSound("coin")
            table.remove(coinsOnMap, i)
        elseif item.x < -50 then
            table.remove(coinsOnMap, i)
        end
    end
end

-- -------------------------------------------------------------------
-- BOUTIQUE
-- -------------------------------------------------------------------

-- Achète ou équipe un oiseau.
function buyOrSelectBird(index)
    local item = birdSkins[index]
    if item == nil then
        return
    end

    if unlockedBirds[index] then
        selectedBird = index
        playSound("shop")
        saveData()
        return
    end

    if coins >= item.cost then
        coins = coins - item.cost
        unlockedBirds[index] = true
        selectedBird = index
        playSound("shop")
        saveData()
    end
end

-- Achète ou équipe un décor.
function buyOrSelectBackground(index)
    local item = backgroundSkins[index]
    if item == nil then
        return
    end

    if unlockedBackgrounds[index] then
        selectedBackground = index
        playSound("shop")
        saveData()
        return
    end

    if coins >= item.cost then
        coins = coins - item.cost
        unlockedBackgrounds[index] = true
        selectedBackground = index
        playSound("shop")
        saveData()
    end
end

-- Achète ou équipe un skin de tuyau.
-- Le rainbow est exclu car il s'active automatiquement à 100 points.
function buyOrSelectPipe(index)
    local item = pipeSkins[index]
    if item == nil then
        return
    end

    if item.key == "rainbow" then
        return
    end

    if item.unlockScore ~= nil and bestScore < item.unlockScore then
        return
    end

    if unlockedPipes[index] then
        selectedPipe = index
        playSound("shop")
        saveData()
        return
    end

    if coins >= item.cost then
        coins = coins - item.cost
        unlockedPipes[index] = true
        selectedPipe = index
        playSound("shop")
        saveData()
    end
end

-- Choisit le skin de tuyau réellement affiché.
-- À 100 points, le rainbow prend automatiquement la main.
function getActivePipeIndex()
    if rainbowPipeIndex ~= nil and score >= 100 then
        return rainbowPipeIndex
    end

    return selectedPipe
end
