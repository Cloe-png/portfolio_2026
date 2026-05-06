-- Chargement des images, polices et helpers de sprites.
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

-- Variante spritesheet :
-- on retire le noir connecte au bord de chaque case,
-- pas seulement au bord global de l'image.
function makeGridBorderBlackTransparent(imageData, columns, rows)
    local width, height = imageData:getDimensions()
    local cellWidth = math.floor(width / columns)
    local cellHeight = math.floor(height / rows)

    local function clearCell(startX, startY, endX, endY)
        local visited = {}
        local stack = {}

        local function isNearBlack(x, y)
            local r, g, b, a = imageData:getPixel(x, y)
            return a > 0.02 and r < 0.05 and g < 0.05 and b < 0.05
        end

        local function push(x, y)
            if x < startX or y < startY or x > endX or y > endY then
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

        for x = startX, endX do
            push(x, startY)
            push(x, endY)
        end

        for y = startY, endY do
            push(startX, y)
            push(endX, y)
        end

        while #stack > 0 do
            local point = table.remove(stack)
            local r, g, b = imageData:getPixel(point.x, point.y)
            imageData:setPixel(point.x, point.y, r, g, b, 0)

            push(point.x + 1, point.y)
            push(point.x - 1, point.y)
            push(point.x, point.y + 1)
            push(point.x, point.y - 1)
        end
    end

    for row = 0, rows - 1 do
        for column = 0, columns - 1 do
            local startX = column * cellWidth
            local startY = row * cellHeight
            local endX = startX + cellWidth - 1
            local endY = startY + cellHeight - 1
            clearCell(startX, startY, endX, endY)
        end
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

function loadImageRaw(path)
    if love.filesystem.getInfo(path) == nil then
        return nil
    end

    local ok, image = pcall(love.graphics.newImage, path)
    if not ok then
        return nil
    end

    image:setFilter("nearest", "nearest")
    return image
end

function buildGridFrameImages(path, columns, rows, frameOrder, keepBlackOutline)
    if love.filesystem.getInfo(path) == nil then
        return nil, nil, nil
    end

    local ok, sourceData = pcall(love.image.newImageData, path)
    if not ok then
        return nil, nil, nil
    end

    local sourceWidth, sourceHeight = sourceData:getDimensions()
    local cellWidth = math.floor(sourceWidth / columns)
    local cellHeight = math.floor(sourceHeight / rows)
    local frames = {}
    local frameWidths = {}
    local frameHeights = {}

    local function findLargestOpaqueBounds(imageData)
        local width, height = imageData:getDimensions()
        local visited = {}
        local largestBounds = nil
        local largestCount = 0

        local function makeKey(x, y)
            return y * width + x
        end

        for y = 0, height - 1 do
            for x = 0, width - 1 do
                local key = makeKey(x, y)
                if not visited[key] then
                    visited[key] = true
                    local _, _, _, alpha = imageData:getPixel(x, y)

                    if alpha > 0.02 then
                        local stack = { { x = x, y = y } }
                        local count = 0
                        local minX, minY = x, y
                        local maxX, maxY = x, y

                        while #stack > 0 do
                            local point = table.remove(stack)
                            local px = point.x
                            local py = point.y
                            count = count + 1

                            if px < minX then minX = px end
                            if py < minY then minY = py end
                            if px > maxX then maxX = px end
                            if py > maxY then maxY = py end

                            local neighbours = {
                                { x = px + 1, y = py },
                                { x = px - 1, y = py },
                                { x = px, y = py + 1 },
                                { x = px, y = py - 1 }
                            }

                            for i = 1, #neighbours do
                                local nx = neighbours[i].x
                                local ny = neighbours[i].y

                                if nx >= 0 and ny >= 0 and nx < width and ny < height then
                                    local neighbourKey = makeKey(nx, ny)
                                    if not visited[neighbourKey] then
                                        visited[neighbourKey] = true
                                        local _, _, _, neighbourAlpha = imageData:getPixel(nx, ny)
                                        if neighbourAlpha > 0.02 then
                                            table.insert(stack, { x = nx, y = ny })
                                        end
                                    end
                                end
                            end
                        end

                        if count > largestCount then
                            largestCount = count
                            largestBounds = {
                                minX = minX,
                                minY = minY,
                                maxX = maxX,
                                maxY = maxY
                            }
                        end
                    end
                end
            end
        end

        return largestBounds
    end

    for _, frameIndex in ipairs(frameOrder) do
        local zeroIndex = frameIndex - 1
        local column = zeroIndex % columns
        local row = math.floor(zeroIndex / columns)
        local startX = column * cellWidth
        local startY = row * cellHeight
        local frameData = love.image.newImageData(cellWidth, cellHeight)

        for y = 0, cellHeight - 1 do
            for x = 0, cellWidth - 1 do
                frameData:setPixel(x, y, sourceData:getPixel(startX + x, startY + y))
            end
        end

        if keepBlackOutline then
            makeBorderBlackTransparent(frameData)
        else
            removeNearBlackPixels(frameData)
        end

        local bounds = findLargestOpaqueBounds(frameData)
        local finalData = frameData
        local finalWidth = cellWidth
        local finalHeight = cellHeight

        if bounds ~= nil then
            finalWidth = bounds.maxX - bounds.minX + 1
            finalHeight = bounds.maxY - bounds.minY + 1
            finalData = love.image.newImageData(finalWidth, finalHeight)

            for y = 0, finalHeight - 1 do
                for x = 0, finalWidth - 1 do
                    finalData:setPixel(x, y, frameData:getPixel(bounds.minX + x, bounds.minY + y))
                end
            end
        end

        local frameImage = love.graphics.newImage(finalData)
        frameImage:setFilter("nearest", "nearest")
        table.insert(frames, frameImage)
        table.insert(frameWidths, finalWidth)
        table.insert(frameHeights, finalHeight)
    end

    return frames, frameWidths, frameHeights
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

function stopRainbowMusic()
    if rainbowMusic ~= nil then
        rainbowMusic:stop()
    end
end

function updateRainbowMusic()
    if rainbowMusic == nil then
        return
    end

    if isRainbowPresentationActive() then
        if not rainbowMusic:isPlaying() then
            rainbowMusic:play()
        end
        return
    end

    if rainbowMusic:isPlaying() then
        rainbowMusic:stop()
    end
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
    local frameOrigins = {}
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
        table.insert(frameOrigins, {
            x = (cellWidth / 2) - (minX - startX),
            y = (cellHeight / 2) - (minY - startY)
        })

        if frameWidth > maxFrameWidth then
            maxFrameWidth = frameWidth
        end

        if frameHeight > maxFrameHeight then
            maxFrameHeight = frameHeight
        end
    end

    return quads, maxFrameWidth, maxFrameHeight, frameOrigins
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
    local data = birdSpriteData[index]
    local image = birdSprites[index]

    if image == nil or data == nil or data.frames == nil or #data.frames == 0 then
        return nil, nil, nil, nil
    end

    if data.frameImages ~= nil then
        local activeImage = data.frameImages[birdSpriteFrameIndex] or data.frameImages[1]
        local activeWidth = data.frameWidths and (data.frameWidths[birdSpriteFrameIndex] or data.frameWidths[1]) or data.frameWidth
        local activeHeight = data.frameHeights and (data.frameHeights[birdSpriteFrameIndex] or data.frameHeights[1]) or data.frameHeight
        return activeImage, nil, activeWidth, activeHeight
    end

    local activeQuad = data.frames[birdSpriteFrameIndex] or data.frames[1]
    return image, activeQuad, data.frameWidth, data.frameHeight
end

function getCoinSpriteVisual(coinTypeKey)
    local data = getCoinDrawData(coinTypeKey)

    if data == nil or data.frames == nil or #data.frames == 0 then
        return nil, nil, nil, nil
    end

    local frameIndex = coinSpriteFrameIndex
    local activeFrame = data.frames[frameIndex] or data.frames[1]
    local activeWidth = data.frameWidths and (data.frameWidths[frameIndex] or data.frameWidths[1]) or data.frameWidth
    local activeHeight = data.frameHeights and (data.frameHeights[frameIndex] or data.frameHeights[1]) or data.frameHeight
    return activeFrame, nil, activeWidth, activeHeight
end

function getPickupSpriteVisual(pickupTypeKey)
    if pickupTypeKey == healPickupType.key then
        if healPickupSprite == nil then
            return nil, nil, nil, nil
        end

        return healPickupSprite, nil, healPickupWidth, healPickupHeight
    end

    return getCoinSpriteVisual(pickupTypeKey)
end

function getShopBackgroundVisual(section, page)
    if shopBackgroundSprites == nil or shopBackgroundSprites[section] == nil then
        return nil
    end

    local entry = shopBackgroundSprites[section]
    local index = page or 1
    if index < 1 then
        index = 1
    elseif index > #entry then
        index = #entry
    end

    return entry[index] or entry[1]
end

function getDifficultyBackgroundVisual(mode)
    if difficultyBackgroundSprites ~= nil then
        return difficultyBackgroundSprites[mode]
    end

    return nil
end

function getGameOverBackgroundVisual(mode)
    if gameOverBackgroundSprites ~= nil then
        return gameOverBackgroundSprites[mode]
    end

    return nil
end

function getResetBackgroundVisual()
    return resetBackgroundSprite
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
        jump = loadSound("assets/sound/jump.wav", 0.28),
        score = createToneSound(880, 0.08, 0.14),
        hit = createNoiseBurst(0.14, 0.18),
        gameover = createToneSound(180, 0.34, 0.18),
        shop = createToneSound(520, 0.10, 0.13)
    }
    rainbowMusic = loadSound("assets/sound/NyanCat.mp3", 0.42, "stream")
    if rainbowMusic ~= nil then
        rainbowMusic:setLooping(true)
    end

    -- Oiseaux du joueur.
    for index, skin in ipairs(birdSkins) do
        if skin.key == "cat" then
            local frames, frameWidths, frameHeights = buildGridFrameImages(
                skin.file,
                skin.columns or 1,
                skin.rows or 1,
                skin.frameOrder or { 1 },
                true
            )

            if frames ~= nil and #frames > 0 then
                birdSprites[index] = frames[1]
                birdSpriteData[index] = {
                    frames = frames,
                    frameImages = frames,
                    frameWidth = frameWidths[1],
                    frameHeight = frameHeights[1],
                    frameWidths = frameWidths,
                    frameHeights = frameHeights
                }
            end
        else
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

        if birdSpriteData[index] ~= nil and skin.key == "nyancat" then
            specialBirdIndex = index
        end
    end

    -- On garde aussi une référence simple vers l'oiseau de base.
    if birdSpriteData[1] ~= nil then
        birdSpriteFrames = birdSpriteData[1].frames
    end

    -- Pièce ramassable.
    coinAnimationFramesByType = {}

    for i = 1, #coinTypes do
        local coinType = coinTypes[i]
        local frames = nil
        local frameWidths = nil
        local frameHeights = nil
        frames, frameWidths, frameHeights = buildGridFrameImages(coinType.file, 2, 2, { 1, 2, 3, 4 }, true)

        if frames ~= nil and #frames > 0 then
            coinAnimationFramesByType[coinType.key] = {
                frames = frames,
                frameWidth = frameWidths[1],
                frameHeight = frameHeights[1],
                frameWidths = frameWidths,
                frameHeights = frameHeights
            }

        end
    end

    -- Cœurs pour les vies.
    healPickupSprite = loadImageRaw(healPickupType.file)
    healPickupWidth = 1
    healPickupHeight = 1

    if healPickupSprite ~= nil then
        healPickupWidth = healPickupSprite:getWidth()
        healPickupHeight = healPickupSprite:getHeight()
    end

    heartsSprite = loadImageWithTransparency("assets/hearts.png", true)
    heartFullQuad = nil
    heartEmptyQuad = nil
    heartFrameWidth = 1
    heartFrameHeight = 1

    if heartsSprite ~= nil then
        local heartQuads = nil
        heartQuads, heartFrameWidth, heartFrameHeight = buildTrimmedFrameSet("assets/hearts.png", 6, 2, { 1, 6 }, true)

        -- Si le decoupage precis echoue, on garde un fallback simple
        -- pour eviter de bloquer tout le chargement du jeu.
        if heartQuads == nil or #heartQuads < 2 then
            heartQuads, heartFrameWidth, heartFrameHeight = buildFrameQuads(heartsSprite, 6, 2, { 1, 6 })
        end

        if heartQuads ~= nil then
            heartFullQuad = heartQuads[1]
            heartEmptyQuad = heartQuads[2]
        end
    end

    nyanBackgroundIndex = nil

    -- Images de fond de la partie.
    for index, background in ipairs(backgroundSkins) do
        if background.file and love.filesystem.getInfo(background.file) ~= nil then
            local ok, image = pcall(love.graphics.newImage, background.file)
            if ok then
                image:setFilter("linear", "linear")
                backgroundSprites[index] = image

                if background.key == "nyancat" then
                    nyanBackgroundIndex = index
                end
            end
        end
    end

    menuBackgroundSprite = nil
    local menuBackgroundPath = "assets/background_screen/menu_background.png"
    if love.filesystem.getInfo(menuBackgroundPath) ~= nil then
        local ok, image = pcall(love.graphics.newImage, menuBackgroundPath)
        if ok then
            image:setFilter("linear", "linear")
            menuBackgroundSprite = image
        end
    end

    difficultyBackgroundSprites = {}
    local difficultyBackgroundFiles = {
        easy = "assets/background_difficulty/Difficulty_Facile.png",
        normal = "assets/background_difficulty/Difficulty_Moyen.png",
        hard = "assets/background_difficulty/Difficulty_Difficile.png"
    }

    for key, path in pairs(difficultyBackgroundFiles) do
        if love.filesystem.getInfo(path) ~= nil then
            local ok, image = pcall(love.graphics.newImage, path)
            if ok and image ~= nil then
                image:setFilter("nearest", "nearest")
                difficultyBackgroundSprites[key] = image
            end
        end
    end

    gameOverBackgroundSprites = {}
    local gameOverBackgroundFiles = {
        easy = "assets/background_game_over/Easy.png",
        normal = "assets/background_game_over/Moyen.png",
        hard = "assets/background_game_over/Difficult.png"
    }

    for key, path in pairs(gameOverBackgroundFiles) do
        if love.filesystem.getInfo(path) ~= nil then
            local ok, image = pcall(love.graphics.newImage, path)
            if ok and image ~= nil then
                image:setFilter("nearest", "nearest")
                gameOverBackgroundSprites[key] = image
            end
        end
    end

    resetBackgroundSprite = nil
    local resetBackgroundPath = "assets/Reset_background.png"
    if love.filesystem.getInfo(resetBackgroundPath) ~= nil then
        local ok, image = pcall(love.graphics.newImage, resetBackgroundPath)
        if ok and image ~= nil then
            image:setFilter("nearest", "nearest")
            resetBackgroundSprite = image
        end
    end

    menuButtonSprites = {}
    local menuButtonFiles = {
        play = "assets/buttons_menu/play.png",
        shop = "assets/buttons_menu/shop.png",
        reset = "assets/buttons_menu/reset.png",
        out = "assets/buttons_menu/out.png"
    }

    for key, path in pairs(menuButtonFiles) do
        local image = loadImageWithTransparency(path, true)
        menuButtonSprites[key] = image
    end

    shopBackgroundSprites = {}

    local shopBackgroundFiles = {
        bird = {
            "assets/background_shop/Skin1.png",
            "assets/background_shop/Skin2.png",
            "assets/background_shop/Skin3.png"
        },
        background = {
            "assets/background_shop/Background1.png",
            "assets/background_shop/Background2.png",
            "assets/background_shop/Background3.png"
        },
        pipe = {
            "assets/background_shop/Pipes1.png",
            "assets/background_shop/Pipes2.png",
            "assets/background_shop/Pipes3.png"
        }
    }

    for key, paths in pairs(shopBackgroundFiles) do
        shopBackgroundSprites[key] = {}

        for i = 1, #paths do
            local path = paths[i]
            if love.filesystem.getInfo(path) ~= nil then
                local ok, image = pcall(love.graphics.newImage, path)
                if ok and image ~= nil then
                    image:setFilter("nearest", "nearest")
                    table.insert(shopBackgroundSprites[key], image)
                end
            end
        end

        if #shopBackgroundSprites[key] == 0 then
            shopBackgroundSprites[key] = nil
        end
    end

    shopSkinStateSprites = {}
    local shopSkinStateFiles = {
        lock = "assets/skin_shop/lock_skin.png",
        unlock = "assets/skin_shop/unlock_skin.png",
        use = "assets/skin_shop/use_skin.png"
    }

    for key, path in pairs(shopSkinStateFiles) do
        if love.filesystem.getInfo(path) ~= nil then
            local ok, image = pcall(love.graphics.newImage, path)
            if ok and image ~= nil then
                image:setFilter("nearest", "nearest")
                shopSkinStateSprites[key] = image
            end
        end
    end

    stopRainbowMusic()

    -- Métadonnées de boutique pour les tuyaux.
    local pipeMeta = {}

    for i = 1, #pipeSkins do
        local item = pipeSkins[i]
        pipeMeta[item.key] = {
            label = item.name,
            cost = item.cost,
            unlockScore = item.unlockScore,
            order = item.order,
            hidden = item.hidden,
            file = item.file
        }
    end

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
                file = meta.file or filepath,
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

