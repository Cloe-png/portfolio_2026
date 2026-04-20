-- Chargement des images, polices et helpers de sprites.
-- Ce fichier est le plus "technique" du projet.
-- Si tu debutes, retiens surtout ceci :
-- 1. on charge les images
-- 2. on coupe les spritesheets en morceaux
-- 3. on prépare les tuyaux pour pouvoir les étirer proprement

-- Rend transparents les pixels presque noirs.
function removeNearBlackPixels(imageData)
    imageData:mapPixel(function(x, y, r, g, b, a)
        if r < 0.05 and g < 0.05 and b < 0.05 then
            return r, g, b, 0
        end

        return r, g, b, a
    end)
end

-- Supprime le fond noir uniquement sur les bords du sprite.
-- C'est pratique pour garder les détails internes noirs.
function makeBorderBlackTransparent(imageData)
    local width, height = imageData:getDimensions()
    local visited = {}
    local stack = {}

    local function isNearBlack(x, y)
        local r, g, b, a = imageData:getPixel(x, y)
        return a > 0.02 and r < 0.05 and g < 0.05 and b < 0.05
    end

    local function push(x, y)
        if x < 0 or y < 0 or x >= width or y >= height then
            return
        end

        local key = y * width + x
        if visited[key] then
            return
        end

        visited[key] = true
        if isNearBlack(x, y) then
            table.insert(stack, { x = x, y = y })
        end
    end

    for x = 0, width - 1 do
        push(x, 0)
        push(x, height - 1)
    end

    for y = 0, height - 1 do
        push(0, y)
        push(width - 1, y)
    end

    while #stack > 0 do
        local point = table.remove(stack)
        local r, g, b, a = imageData:getPixel(point.x, point.y)
        imageData:setPixel(point.x, point.y, r, g, b, 0)

        push(point.x + 1, point.y)
        push(point.x - 1, point.y)
        push(point.x, point.y + 1)
        push(point.x, point.y - 1)
    end
end

-- Charge une image puis nettoie son fond.
function loadImageWithTransparency(path, keepBlackOutline)
    if love.filesystem.getInfo(path) == nil then
        return nil
    end

    local ok, imageData = pcall(love.image.newImageData, path)
    if not ok then
        return nil
    end

    if keepBlackOutline then
        makeBorderBlackTransparent(imageData)
    else
        removeNearBlackPixels(imageData)
    end

    local image = love.graphics.newImage(imageData)
    image:setFilter("nearest", "nearest")
    return image
end

-- Charge un son s'il existe, puis applique un volume cohérent.
function loadSound(path, volume, sourceType)
    if love.filesystem.getInfo(path) == nil then
        return nil
    end

    local ok, source = pcall(love.audio.newSource, path, sourceType or "static")
    if not ok then
        return nil
    end

    source:setVolume(volume or 1)
    return source
end

-- Génère un son simple à partir d'une sinusoïde.
function createToneSound(frequency, duration, volume)
    local sampleRate = 44100
    local sampleCount = math.floor(sampleRate * duration)
    local soundData = love.sound.newSoundData(sampleCount, sampleRate, 16, 1)

    for i = 0, sampleCount - 1 do
        local time = i / sampleRate
        local fade = 1 - (i / sampleCount)
        local sample = math.sin(2 * math.pi * frequency * time) * fade * (volume or 0.25)
        soundData:setSample(i, sample)
    end

    return love.audio.newSource(soundData, "static")
end

-- Génère un petit bruit rétro plus nerveux pour les collisions.
function createNoiseBurst(duration, volume)
    local sampleRate = 44100
    local sampleCount = math.floor(sampleRate * duration)
    local soundData = love.sound.newSoundData(sampleCount, sampleRate, 16, 1)

    for i = 0, sampleCount - 1 do
        local fade = 1 - (i / sampleCount)
        local sample = (love.math.random() * 2 - 1) * fade * (volume or 0.18)
        soundData:setSample(i, sample)
    end

    return love.audio.newSource(soundData, "static")
end

-- Joue un effet sonore en réutilisant sa source.
function playSound(name)
    local source = soundEffects[name]
    if source == nil then
        return
    end

    source:stop()
    source:play()
end

-- Découpe un spritesheet régulier en frames.
function buildFrameQuads(image, columns, rows, frameOrder)
    local quads = {}
    local frameWidth = math.floor(image:getWidth() / columns)
    local frameHeight = math.floor(image:getHeight() / rows)
    local imageWidth, imageHeight = image:getDimensions()

    for _, frameIndex in ipairs(frameOrder) do
        local zeroIndex = frameIndex - 1
        local column = zeroIndex % columns
        local row = math.floor(zeroIndex / columns)

        table.insert(
            quads,
            love.graphics.newQuad(column * frameWidth, row * frameHeight, frameWidth, frameHeight, imageWidth, imageHeight)
        )
    end

    return quads, frameWidth, frameHeight
end

-- Découpe un spritesheet en gardant seulement la zone utile de chaque frame.
function buildTrimmedFrameSet(path, columns, rows, frameOrder, keepBlackOutline)
    if love.filesystem.getInfo(path) == nil then
        return nil, 1, 1
    end

    local ok, imageData = pcall(love.image.newImageData, path)
    if not ok then
        return nil, 1, 1
    end

    if keepBlackOutline then
        makeBorderBlackTransparent(imageData)
    else
        removeNearBlackPixels(imageData)
    end

    local fullWidth, fullHeight = imageData:getDimensions()
    local cellWidth = math.floor(fullWidth / columns)
    local cellHeight = math.floor(fullHeight / rows)
    local quads = {}
    local maxFrameWidth = 1
    local maxFrameHeight = 1

    -- On répète la même logique pour chaque frame demandée.
    for _, frameIndex in ipairs(frameOrder) do
        local zeroIndex = frameIndex - 1
        local column = zeroIndex % columns
        local row = math.floor(zeroIndex / columns)
        local startX = column * cellWidth
        local startY = row * cellHeight
        local minX = startX + cellWidth - 1
        local minY = startY + cellHeight - 1
        local maxX = startX
        local maxY = startY
        local foundPixel = false

        for y = startY, startY + cellHeight - 1 do
            for x = startX, startX + cellWidth - 1 do
                local _, _, _, a = imageData:getPixel(x, y)
                if a > 0.02 then
                    foundPixel = true
                    if x < minX then minX = x end
                    if y < minY then minY = y end
                    if x > maxX then maxX = x end
                    if y > maxY then maxY = y end
                end
            end
        end

        if not foundPixel then
            minX = startX
            minY = startY
            maxX = startX + cellWidth - 1
            maxY = startY + cellHeight - 1
        end

        local frameWidth = maxX - minX + 1
        local frameHeight = maxY - minY + 1
        table.insert(quads, love.graphics.newQuad(minX, minY, frameWidth, frameHeight, fullWidth, fullHeight))

        if frameWidth > maxFrameWidth then
            maxFrameWidth = frameWidth
        end

        if frameHeight > maxFrameHeight then
            maxFrameHeight = frameHeight
        end
    end

    return quads, maxFrameWidth, maxFrameHeight
end

-- Cherche la zone opaque réelle d'un sprite de tuyau.
function findPipeBounds(imageData, startX, startY, width, height)
    -- On balaie la zone pixel par pixel pour connaitre
    -- le vrai rectangle du tuyau.
    local minX = startX + width
    local minY = startY + height
    local maxX = startX - 1
    local maxY = startY - 1
    local foundPixel = false

    for y = startY, startY + height - 1 do
        for x = startX, startX + width - 1 do
            local _, _, _, a = imageData:getPixel(x, y)
            if a > 0.02 then
                foundPixel = true
                if x < minX then minX = x end
                if y < minY then minY = y end
                if x > maxX then maxX = x end
                if y > maxY then maxY = y end
            end
        end
    end

    if not foundPixel then
        return nil
    end

    return minX, minY, maxX, maxY
end

-- Sépare un tuyau en deux parties :
-- la tête et le corps extensible.
function buildPipeVariantData(imageData, startX, startY, width, height)
    local minX, minY, maxX, maxY = findPipeBounds(imageData, startX, startY, width, height)
    if minX == nil then
        return nil
    end

    local spriteWidth = maxX - minX + 1
    local capEndY = nil
    local bodyStartY = nil
    local sawOpaqueRow = false
    local gapDetected = false

    -- On cherche d'abord ou finit la tete du tuyau,
    -- puis ou commence le corps qu'on pourra etirer.
    for y = minY, maxY do
        local rowHasPixel = false

        for x = minX, maxX do
            local _, _, _, a = imageData:getPixel(x, y)
            if a > 0.02 then
                rowHasPixel = true
                break
            end
        end

        if rowHasPixel then
            if not sawOpaqueRow then
                sawOpaqueRow = true
                capEndY = y
            elseif gapDetected then
                bodyStartY = y
                break
            else
                capEndY = y
            end
        elseif sawOpaqueRow then
            gapDetected = true
        end
    end

    -- Si on n'a pas trouve de separation nette,
    -- on prend une valeur simple par défaut.
    if bodyStartY == nil then
        local fallbackCapHeight = math.max(1, math.floor((maxY - minY + 1) * 0.18))
        capEndY = minY + fallbackCapHeight - 1
        bodyStartY = math.min(maxY, capEndY + 1)
    end

    local capHeight = math.max(1, capEndY - minY + 1)
    local bodyHeight = math.max(1, maxY - bodyStartY + 1)
    local imageWidth, imageHeight = imageData:getDimensions()

    return {
        width = spriteWidth,
        capHeight = capHeight,
        bodyHeight = bodyHeight,
        capQuad = love.graphics.newQuad(minX, minY, spriteWidth, capHeight, imageWidth, imageHeight),
        bodyQuad = love.graphics.newQuad(minX, bodyStartY, spriteWidth, bodyHeight, imageWidth, imageHeight)
    }
end

-- Charge un sprite de tuyau.
-- Le rainbow peut contenir plusieurs variantes dans un seul atlas.
function buildPipeVisual(path)
    if love.filesystem.getInfo(path) == nil then
        return nil, nil
    end

    local ok, imageData = pcall(love.image.newImageData, path)
    if not ok then
        return nil, nil
    end

    removeNearBlackPixels(imageData)

    local image = love.graphics.newImage(imageData)
    image:setFilter("nearest", "nearest")

    local width, height = imageData:getDimensions()
    local variants = {}

    -- Cas spécial : le sprite rainbow contient plusieurs tuyaux.
    if width == 1236 and height == 1854 then
        local tileWidth = math.floor(width / 2)
        local tileHeight = math.floor(height / 3)

        for row = 0, 2 do
            for column = 0, 1 do
                local variant = buildPipeVariantData(imageData, column * tileWidth, row * tileHeight, tileWidth, tileHeight)
                if variant ~= nil then
                    table.insert(variants, variant)
                end
            end
        end
    else
        -- Cas simple : un seul tuyau dans l'image.
        local variant = buildPipeVariantData(imageData, 0, 0, width, height)
        if variant ~= nil then
            table.insert(variants, variant)
        end
    end

    if #variants == 0 then
        return image, nil
    end

    return image, { variants = variants }
end

-- Retourne l'image de tuyau et la variante a afficher.
function getPipeSpriteVisual(index)
    local image = pipeSprites[index]
    local data = pipeSpriteData[index]

    if image == nil or data == nil or data.variants == nil or #data.variants == 0 then
        return nil, nil
    end

    -- Par défaut on prend la première variante.
    local variantIndex = 1

    -- Si un fichier contient plusieurs variantes,
    -- on alterne doucement entre elles.
    if #data.variants > 1 then
        variantIndex = math.floor(love.timer.getTime() * 8) % #data.variants + 1
    end

    return image, data.variants[variantIndex]
end

-- Retourne l'image active de l'oiseau et sa frame courante.
function getBirdSpriteVisual(index)
    local image = birdSprites[index]
    local data = birdSpriteData[index]

    if image == nil or data == nil or data.frames == nil or #data.frames == 0 then
        return nil, nil, nil, nil
    end

    local activeQuad = data.frames[birdSpriteFrameIndex] or data.frames[1]
    return image, activeQuad, data.frameWidth, data.frameHeight
end

-- Charge toutes les ressources du jeu :
-- polices, oiseaux, pièces, cœurs, décors et tuyaux.
function initializeAssets()
    love.window.setTitle("Flappy Bird")

    fontSmall = love.graphics.newFont(16)
    fontUI = love.graphics.newFont(24)
    fontTitle = love.graphics.newFont(42)
    fontScore = love.graphics.newFont(48)

    soundEffects = {
        coin = loadSound("assets/sound/coin.wav", 0.35),
        jump = createToneSound(640, 0.09, 0.16),
        score = createToneSound(880, 0.08, 0.14),
        hit = createNoiseBurst(0.14, 0.18),
        gameover = createToneSound(180, 0.34, 0.18),
        shop = createToneSound(520, 0.10, 0.13)
    }

    -- Oiseaux du joueur.
    for index, skin in ipairs(birdSkins) do
        local image = loadImageWithTransparency(skin.file, true)
        if image ~= nil then
            birdSprites[index] = image

            local quads, frameWidth, frameHeight = buildFrameQuads(
                image,
                skin.columns or 1,
                skin.rows or 1,
                skin.frameOrder or { 1 }
            )

            birdSpriteData[index] = {
                frames = quads,
                frameWidth = frameWidth,
                frameHeight = frameHeight
            }
        end
    end

    -- On garde aussi une référence simple vers l'oiseau de base.
    birdSprite = birdSprites[1]
    if birdSpriteData[1] ~= nil then
        birdSpriteFrames = birdSpriteData[1].frames
    end

    -- Pièce ramassable.
    coinSprite = loadImageWithTransparency("assets/coin.png", true)
    if coinSprite ~= nil then
        coinSpriteFrames, coinFrameWidth, coinFrameHeight = buildTrimmedFrameSet("assets/coin.png", 2, 2, { 1, 2, 3, 4 }, true)
    end

    -- Cœurs pour les vies.
    heartsSprite = loadImageWithTransparency("assets/hearts.png", true)
    if heartsSprite ~= nil then
        local heartQuads = nil
        heartQuads, heartFrameWidth, heartFrameHeight = buildTrimmedFrameSet("assets/hearts.png", 6, 2, { 1, 6 }, true)
        heartFullQuad = heartQuads[1]
        heartEmptyQuad = heartQuads[2]
    end

    -- Images de fond de la partie.
    for index, background in ipairs(backgroundSkins) do
        if background.file and love.filesystem.getInfo(background.file) ~= nil then
            local ok, image = pcall(love.graphics.newImage, background.file)
            if ok then
                image:setFilter("linear", "linear")
                backgroundSprites[index] = image
            end
        end
    end

    -- Métadonnées de boutique pour les tuyaux.
    local pipeMeta = {
        green = { label = "Vert", cost = 0, order = 1 },
        red = { label = "Rouge", cost = 70, order = 2 },
        blue = { label = "Bleu", cost = 45, order = 3 },
        pink = { label = "Rose", cost = 95, order = 4 },
        yellow = { label = "Jaune", cost = 120, order = 5 },
        rainbow = { label = "Rainbow", cost = 0, unlockScore = 100, order = 99, hidden = true }
    }

    -- On lit tous les PNG des tuyaux puis on les remet dans l'ordre voulu.
    local pipeFiles = love.filesystem.getDirectoryItems("assets/pipes")
    local loadedPipes = {}

    for _, filename in ipairs(pipeFiles) do
        if string.match(filename, "%.png$") then
            local filepath = "assets/pipes/" .. filename
            local key = string.match(filename, "^pipes_(%w+)%.png$") or filename
            local meta = pipeMeta[key] or {}
            local image, data = buildPipeVisual(filepath)

            table.insert(loadedPipes, {
                key = key,
                name = meta.label or key,
                cost = meta.cost or 0,
                unlockScore = meta.unlockScore,
                hidden = meta.hidden == true,
                order = meta.order or 999,
                file = filepath,
                image = image,
                data = data
            })
        end
    end

    table.sort(loadedPipes, function(a, b)
        if a.order ~= b.order then
            return a.order < b.order
        end

        return a.name < b.name
    end)

    pipeSkins = {}
    pipeSprites = {}
    pipeSpriteData = {}
    rainbowPipeIndex = nil

    for i = 1, #loadedPipes do
        local pipe = loadedPipes[i]

        table.insert(pipeSkins, {
            key = pipe.key,
            name = pipe.name,
            cost = pipe.cost,
            unlockScore = pipe.unlockScore,
            hidden = pipe.hidden,
            order = pipe.order,
            file = pipe.file
        })

        table.insert(pipeSprites, pipe.image)
        table.insert(pipeSpriteData, pipe.data)

        if pipe.key == "rainbow" then
            rainbowPipeIndex = i
        end
    end

    -- Petits éléments de décor.
    stars = {}
    for i = 1, 70 do
        table.insert(stars, {
            x = love.math.random(0, WINDOW_WIDTH),
            y = love.math.random(0, GROUND_Y - 20)
        })
    end

    clouds = {}
    for i = 1, 7 do
        table.insert(clouds, {
            x = love.math.random(-80, WINDOW_WIDTH),
            y = love.math.random(45, 220),
            w = love.math.random(90, 170),
            h = love.math.random(36, 62),
            speed = love.math.random(12, 24)
        })
    end
end
