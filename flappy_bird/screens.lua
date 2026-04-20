-- Rendu de l'interface et des écrans.
-- Lis ce fichier comme ca :
-- 1. outils de dessin
-- 2. rendu de la partie
-- 3. menus
-- 4. boutique
-- 5. game over

-- -------------------------------------------------------------------
-- OUTILS DE RENDU
-- -------------------------------------------------------------------

-- Traduit une clé de difficulté en texte lisible.
function getDifficultyLabel(mode)
    for i = 1, #difficultyOptions do
        if difficultyOptions[i].key == mode then
            return difficultyOptions[i].label
        end
    end

    return "Moyen"
end

-- Dessine un panneau réutilisable pour les menus et overlays.
function drawSoftPanel(x, y, w, h, borderColor)
    love.graphics.setColor(0, 0, 0, 0.22)
    love.graphics.rectangle("fill", x + 5, y + 6, w, h, 18, 18)
    love.graphics.setColor(0.08, 0.10, 0.16, 0.82)
    love.graphics.rectangle("fill", x, y, w, h, 18, 18)
    love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
    love.graphics.rectangle("line", x, y, w, h, 18, 18)
end

-- Petit helper pour dessiner une frame de sprite.
function drawSprite(image, quad, x, y, rotation, scaleX, scaleY, ox, oy)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(image, quad, x, y, rotation, scaleX, scaleY, ox, oy)
end

-- Dessine un tuyau dans le bon sens sans le retourner.
function drawPipeUpright(image, data, x, y, width, height)
    if image == nil or data == nil or height <= 0 then
        return
    end

    local capHeight = data.capHeight
    local bodyHeight = math.max(0, height - capHeight)
    local scaleX = width / data.width
    local capScaleY = capHeight > 0 and (capHeight / data.capHeight) or 1
    local bodyScaleY = data.bodyHeight > 0 and (bodyHeight / data.bodyHeight) or 1

    love.graphics.draw(image, data.capQuad, x, y, 0, scaleX, capScaleY)

    if bodyHeight > 0 then
        love.graphics.draw(image, data.bodyQuad, x, y + capHeight, 0, scaleX, bodyScaleY)
    end
end

-- Dessine un tuyau en haut ou en bas.
function drawPipe(image, data, x, y, width, height, flipped)
    if flipped then
        love.graphics.push()
        love.graphics.translate(0, y + height)
        love.graphics.scale(1, -1)
        drawPipeUpright(image, data, x, 0, width, height)
        love.graphics.pop()
    else
        drawPipeUpright(image, data, x, y, width, height)
    end
end

-- Ajoute un contour noir pour que les tuyaux ressortent mieux.
function drawPipeWithOutline(image, data, x, y, width, height, flipped)
    love.graphics.setColor(0, 0, 0, 1)
    drawPipe(image, data, x - 1, y, width, height, flipped)
    drawPipe(image, data, x + 1, y, width, height, flipped)
    drawPipe(image, data, x, y - 1, width, height, flipped)
    drawPipe(image, data, x, y + 1, width, height, flipped)

    love.graphics.setColor(1, 1, 1, 1)
    drawPipe(image, data, x, y, width, height, flipped)
end

-- -------------------------------------------------------------------
-- PREVIEWS DE BOUTIQUE
-- -------------------------------------------------------------------

function drawBirdPreview(index, x, y)
    local image, quad, frameWidth, frameHeight = getBirdSpriteVisual(index)

    if image ~= nil then
        local scale = math.min(44 / frameWidth, 32 / frameHeight)
        drawSprite(image, quad, x + 22, y + 16, 0, scale, scale, frameWidth / 2, frameHeight / 2)
        return
    end

    love.graphics.setColor(1, 0.82, 0.18)
    love.graphics.rectangle("fill", x, y, 44, 32)
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
    local image, data = getPipeSpriteVisual(index)
    if image == nil or data == nil then
        return
    end

    drawPipeWithOutline(image, data, x + 8, y, 24, 70, true)
    drawPipeWithOutline(image, data, x + 40, y + 30, 24, 70, false)
end

-- -------------------------------------------------------------------
-- RENDU DE LA PARTIE
-- -------------------------------------------------------------------

-- Dessine le fond puis le sol.
function drawBackground()
    -- On affiche d'abord le decor choisi.
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

    -- Puis on dessine le sol qui defile en petits blocs.
    for i = -1, math.ceil(WINDOW_WIDTH / 48) + 1 do
        local x = i * 48 - groundOffset
        love.graphics.setColor(0.48, 0.48, 0.52)
        love.graphics.rectangle("fill", x, GROUND_Y + 12, 42, 24, 4, 4)
        love.graphics.setColor(0.24, 0.24, 0.26)
        love.graphics.rectangle("fill", x, GROUND_Y + 42, 42, 32, 4, 4)
    end
end

-- Dessine le joueur avec un angle base sur sa vitesse verticale.
function drawBird()
    -- L'oiseau se penche vers le haut ou le bas selon sa vitesse.
    local angle = math.max(-0.35, math.min(0.65, bird.speedY / 420))
    local cx = bird.x + bird.width / 2
    local cy = bird.y + bird.height / 2
    local image, quad, frameWidth, frameHeight = getBirdSpriteVisual(selectedBird)

    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.rotate(angle)

    if image ~= nil then
        local scale = math.min(bird.width / frameWidth, bird.height / frameHeight)
        drawSprite(image, quad, 0, 0, 0, scale, scale, frameWidth / 2, frameHeight / 2)
        love.graphics.pop()
        return
    end

    love.graphics.setColor(1, 0.82, 0.18)
    love.graphics.ellipse("fill", 0, 0, 20, 15)
    love.graphics.pop()
end

-- Dessine tous les tuyaux actifs.
function drawPipes()
    local activePipeIndex = getActivePipeIndex()
    local image, data = getPipeSpriteVisual(activePipeIndex)
    local overscan = 6

    for i = 1, #pipes do
        local pipe = pipes[i]
        local bottomY = pipe.topHeight + pipeGap
        local bottomHeight = GROUND_Y - bottomY

        if image ~= nil and data ~= nil then
            drawPipeWithOutline(image, data, pipe.x, -overscan, pipeWidth, pipe.topHeight + overscan, true)
            drawPipeWithOutline(image, data, pipe.x, bottomY, pipeWidth, bottomHeight + overscan, false)
        end
    end
end

-- Dessine les pieces ramassables.
function drawCoins()
    local activeQuad = coinSpriteFrames[coinSpriteFrameIndex] or coinSpriteFrames[1]

    for i = 1, #coinsOnMap do
        local item = coinsOnMap[i]
        local cx = item.x + item.size / 2
        local cy = item.y + item.size / 2

        if coinSprite ~= nil and activeQuad ~= nil then
            local scale = math.min(40 / coinFrameWidth, 40 / coinFrameHeight)
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(coinSprite, activeQuad, cx, cy, 0, scale, scale, coinFrameWidth / 2, coinFrameHeight / 2)
        else
            love.graphics.setColor(1, 0.88, 0.20)
            love.graphics.circle("fill", cx, cy, item.size / 2 + 2)
        end
    end
end

-- Dessine les vies restantes.
function drawLivesAt(startX, startY)
    for i = 1, maxLives do
        local x = startX + (i - 1) * 42

        if heartsSprite ~= nil and heartFullQuad ~= nil and heartEmptyQuad ~= nil then
            local quad = i <= lives and heartFullQuad or heartEmptyQuad
            local scale = math.min(36 / heartFrameWidth, 34 / heartFrameHeight)
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(heartsSprite, quad, x, startY, 0, scale, scale)
        else
            if i <= lives then
                love.graphics.setColor(1, 0.3, 0.3)
            else
                love.graphics.setColor(0.4, 0.2, 0.2)
            end
            love.graphics.rectangle("fill", x, startY, 20, 18)
        end
    end
end

-- Dessine les informations de HUD pendant la partie.
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
    love.graphics.print("Vitesse : " .. math.floor(pipeSpeed), 176, GROUND_Y - 94)
    love.graphics.print("Espace tuyaux : " .. math.floor(pipeGap), 176, GROUND_Y - 68)
    love.graphics.print("P = pause", 176, GROUND_Y - 42)
end

-- Ecran principal d'une partie en cours.
function drawPlaying()
    drawBackground()

    -- Petites lignes décoratives pour donner un peu de profondeur.
    love.graphics.setColor(1, 1, 1, 0.06)
    for i = 0, 7 do
        love.graphics.rectangle("fill", i * 180, 0, 2, GROUND_Y)
    end

    drawPipes()
    drawCoins()
    drawBird()
    drawGameUI()
end

-- Overlay de pause.
function drawPaused()
    drawPlaying()

    local boxWidth = 420
    local boxHeight = 130
    local boxX = (WINDOW_WIDTH - boxWidth) / 2
    local boxY = (WINDOW_HEIGHT - boxHeight) / 2

    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 12, 12)

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Pause", 0, boxY + 20, WINDOW_WIDTH, "center")

    love.graphics.setFont(fontSmall)
    love.graphics.printf("P pour reprendre - Échap pour le menu", 0, boxY + 76, WINDOW_WIDTH, "center")
end

-- -------------------------------------------------------------------
-- MENUS
-- -------------------------------------------------------------------

function drawMenu()
    drawBackground()

    local panelWidth = 560
    local panelHeight = 430
    local panelX = (WINDOW_WIDTH - panelWidth) / 2
    local panelY = WINDOW_HEIGHT * 0.11
    local titleY = panelY + 34
    local footerY = panelY + 372
    local firstItemY = panelY + 150

    drawSoftPanel(panelX, panelY, panelWidth, panelHeight, { 1, 0.86, 0.25, 0.60 })

    love.graphics.setColor(1, 0.92, 0.30, 0.16)
    love.graphics.circle("fill", panelX + 88, panelY + 74, 52)
    love.graphics.circle("fill", panelX + panelWidth - 92, panelY + 76, 40)

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.printf("Flappy Bird", 2, titleY + 2, WINDOW_WIDTH, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Flappy Bird", 0, titleY, WINDOW_WIDTH, "center")

    local items = { "Jouer", "Boutique", "Reset", "Quitter" }
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
    end

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Haut / Bas pour choisir - Entrée pour valider - Échap pour retour", 0, helpY, WINDOW_WIDTH, "center")
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
-- BOUTIQUE
-- -------------------------------------------------------------------

function getShopAccent(category)
    if category == "bird" then
        return 1, 0.66, 0.24
    elseif category == "background" then
        return 0.34, 0.82, 0.74
    end

    return 0.44, 0.76, 1
end

-- Retourne le texte principal et secondaire d'une carte boutique.
function getShopStatus(item, unlocked, selected)
    -- Le rainbow n'est jamais achete manuellement.
    if item.key == "rainbow" then
        if bestScore >= 100 then
            return "Spécial", "S'active automatiquement à 100 points"
        end

        return "Vitrine fermée", "Atteins 100 points pour le voir en jeu"
    end

    if selected then
        return "Équipé", "Prêt à jouer"
    end

    if unlocked then
        return "Disponible", "Touche " .. tostring(item.shopIndex) .. " pour équiper"
    end

    return "À vendre", tostring(item.cost) .. " pièces"
end

-- Dessine une carte produit.
function drawShopCard(category, index, item, unlocked, selected, x, y, w, h)
    local accentR, accentG, accentB = getShopAccent(category)
    local statusTitle, statusText = getShopStatus(item, unlocked, selected)

    love.graphics.setColor(0, 0, 0, 0.20)
    love.graphics.rectangle("fill", x + 7, y + 8, w, h, 18, 18)

    love.graphics.setColor(0.13, 0.09, 0.06, 0.98)
    love.graphics.rectangle("fill", x, y, w, h, 18, 18)
    love.graphics.setColor(0.50, 0.33, 0.18, 0.95)
    love.graphics.rectangle("line", x, y, w, h, 18, 18)

    love.graphics.setColor(accentR * 0.16, accentG * 0.16, accentB * 0.16, 1)
    love.graphics.rectangle("fill", x + 8, y + 16, w - 16, 34, 12, 12)
    love.graphics.setColor(0.36, 0.22, 0.12, 0.96)
    love.graphics.rectangle("fill", x + 8, y + 56, w - 16, 78, 12, 12)

    if selected then
        love.graphics.setColor(accentR, accentG, accentB, 0.95)
        love.graphics.rectangle("line", x + 1, y + 1, w - 2, h - 2, 18, 18)
    end

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 0.96, 0.88)
    love.graphics.printf("ARTICLE " .. index, x + 8, y + 27, w - 16, "center")

    -- La miniature depend de ce qu'on vend.
    if category == "bird" then
        drawBirdPreview(index, x + (w - 44) / 2, y + 80)
    elseif category == "background" then
        drawBackgroundPreview(index, x + (w - 88) / 2, y + 68, 88, 58)
    else
        drawPipePreview(index, x + (w - 64) / 2, y + 60)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(item.name, x + 12, y + 146, w - 24, "center")

    love.graphics.setColor(0.95, 0.83, 0.64)
    love.graphics.printf(statusTitle, x + 12, y + 172, w - 24, "center")

    love.graphics.setColor(0.84, 0.88, 0.93)
    love.graphics.printf(statusText, x + 12, y + 194, w - 24, "center")

    -- Couleur du bouton du bas.
    local tagR, tagG, tagB = 0.92, 0.77, 0.34
    if item.key == "rainbow" then
        tagR, tagG, tagB = 0.79, 0.66, 0.98
    elseif unlocked and not selected then
        tagR, tagG, tagB = 0.42, 0.82, 0.52
    elseif selected then
        tagR, tagG, tagB = accentR, accentG, accentB
    end

    love.graphics.setColor(tagR, tagG, tagB, 1)
    love.graphics.rectangle("fill", x + 20, y + h - 38, w - 40, 24, 8, 8)

    love.graphics.setColor(0.12, 0.09, 0.06, 0.98)
    if item.key == "rainbow" then
        love.graphics.printf("Auto 100 pts", x + 22, y + h - 33, w - 44, "center")
    elseif selected then
        love.graphics.printf("Equipe", x + 22, y + h - 33, w - 44, "center")
    elseif unlocked then
    love.graphics.printf("Choisir", x + 22, y + h - 33, w - 44, "center")
    else
        love.graphics.printf(tostring(item.cost) .. " pièces", x + 22, y + h - 33, w - 44, "center")
    end
end

-- Dessine une rangée complète de cartes.
function drawShopShelf(category, list, unlockedList, selected, x, y, cardW, cardH, spacing)
    local visibleIndex = 0

    for i, item in ipairs(list) do
        if not item.hidden then
            visibleIndex = visibleIndex + 1
            item.shopIndex = visibleIndex

            local cardX = x + (visibleIndex - 1) * (cardW + spacing)
            drawShopCard(category, visibleIndex, item, unlockedList[i] == true, selected == i, cardX, y, cardW, cardH)
        end
    end
end

-- Regroupe les données du rayon actif pour simplifier drawShop.
function getActiveShopData()
    if shopSection == "background" then
        return "Décors", backgroundSkins, unlockedBackgrounds, selectedBackground
    elseif shopSection == "pipe" then
        return "Tuyaux", pipeSkins, unlockedPipes, selectedPipe
    end

    return "Oiseaux", birdSkins, unlockedBirds, selectedBird
end

function countVisibleShopItems(list)
    local count = 0

    for i = 1, #list do
        if not list[i].hidden then
            count = count + 1
        end
    end

    return count
end

function drawShop()
    drawBackground()

    -- Grande facade de boutique.
    local panelWidth = 1180
    local panelHeight = 380
    local panelX = (WINDOW_WIDTH - panelWidth) / 2
    local panelY = WINDOW_HEIGHT * 0.22
    local cardW = 170
    local cardH = 250
    local cardGap = 20
    local awningY = panelY - 34

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(0, 0, 0, 0.28)
    love.graphics.printf("Boutique", 0, WINDOW_HEIGHT * 0.08 + 3, WINDOW_WIDTH, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Boutique", 0, WINDOW_HEIGHT * 0.08, WINDOW_WIDTH, "center")

    -- Les rayures du store.
    for i = 0, 5 do
        local stripeX = panelX + i * (panelWidth / 6)
        if i % 2 == 0 then
            love.graphics.setColor(0.89, 0.24, 0.20, 0.96)
        else
            love.graphics.setColor(0.98, 0.88, 0.64, 0.96)
        end
        love.graphics.rectangle("fill", stripeX, awningY, panelWidth / 6, 42)
    end

    love.graphics.setColor(0.45, 0.28, 0.16, 0.98)
    love.graphics.rectangle("fill", panelX, awningY + 34, panelWidth, 14, 8, 8)

    love.graphics.setColor(0.25, 0.16, 0.10, 0.98)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 20, 20)
    love.graphics.setColor(0.50, 0.33, 0.18, 0.95)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 20, 20)

    love.graphics.setColor(0.87, 0.72, 0.49, 1)
    love.graphics.rectangle("fill", panelX + 26, panelY + 20, 250, 40, 12, 12)
    love.graphics.setColor(0.17, 0.10, 0.06, 1)
    love.graphics.setFont(fontUI)
    love.graphics.printf("Caisse : " .. coins .. " pièces", panelX + 36, panelY + 30, 230, "center")

    love.graphics.setColor(0.96, 0.90, 0.76)
    love.graphics.setFont(fontSmall)
    love.graphics.print("Tab change le rayon", panelX + 306, panelY + 24)
    love.graphics.print("1 à 9 pour acheter ou équiper", panelX + 306, panelY + 46)

    love.graphics.setColor(0.23, 0.14, 0.09, 0.98)
    love.graphics.rectangle("fill", panelX + 730, panelY + 18, 424, 46, 14, 14)

    -- Les onglets de la boutique.
    local categories = {
        { label = "Oiseaux", key = "bird" },
        { label = "Décors", key = "background" },
        { label = "Tuyaux", key = "pipe" }
    }

    local tabX = panelX + 744
    for i = 1, #categories do
        local item = categories[i]
        local tabWidth = 126

        if shopSection == item.key then
            local accentR, accentG, accentB = getShopAccent(item.key)
            love.graphics.setColor(accentR, accentG, accentB, 0.98)
            love.graphics.rectangle("fill", tabX, panelY + 22, tabWidth, 38, 10, 10)
            love.graphics.setColor(0.12, 0.08, 0.05, 0.98)
        else
            love.graphics.setColor(0.78, 0.69, 0.58, 0.45)
            love.graphics.rectangle("fill", tabX, panelY + 22, tabWidth, 38, 10, 10)
            love.graphics.setColor(0.96, 0.90, 0.76)
        end

        love.graphics.printf(item.label, tabX, panelY + 34, tabWidth, "center")
        tabX = tabX + 132
    end

    -- Données du rayon actuellement sélectionné.
    local activeTitle, activeList, activeUnlocked, activeSelected = getActiveShopData()

    local visibleItemCount = countVisibleShopItems(activeList)
    local rowWidth = (visibleItemCount * cardW) + math.max(0, visibleItemCount - 1) * cardGap
    local rowX = panelX + (panelWidth - rowWidth) / 2

    love.graphics.setFont(fontUI)
    love.graphics.setColor(0.96, 0.90, 0.76)
    love.graphics.printf("Rayon : " .. activeTitle, panelX, panelY + 78, panelWidth, "center")

    drawShopShelf(shopSection, activeList, activeUnlocked, activeSelected, rowX, panelY + 108, cardW, cardH, cardGap)
end

-- -------------------------------------------------------------------
-- GAME OVER
-- -------------------------------------------------------------------

-- Écran de fin de partie plus lisible avec récapitulatif.
function drawGameOver()
    -- On garde la partie visible dessous, puis on pose un panneau sombre dessus.
    drawBackground()
    drawPipes()
    drawCoins()
    drawBird()

    love.graphics.setColor(0, 0, 0, 0.52)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    local boxWidth = 760
    local boxHeight = 360
    local boxX = (WINDOW_WIDTH - boxWidth) / 2
    local boxY = (WINDOW_HEIGHT - boxHeight) / 2

    drawSoftPanel(boxX, boxY, boxWidth, boxHeight, { 1, 0.35, 0.30, 0.90 })

    love.graphics.setColor(1, 0.34, 0.30, 0.16)
    love.graphics.rectangle("fill", boxX + 18, boxY + 18, boxWidth - 36, 72, 18, 18)

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Game Over", boxX, boxY + 28, boxWidth, "center")

    love.graphics.setFont(fontUI)
    love.graphics.setColor(1, 0.92, 0.25)
    love.graphics.printf("La course est terminée", boxX, boxY + 90, boxWidth, "center")

    local cards = {
        { title = "Score final", value = tostring(score), x = boxX + 34 },
        { title = "Meilleur score", value = tostring(bestScore), x = boxX + 218 },
        { title = "Pièces gagnées", value = tostring(coinsRun), x = boxX + 402 },
        { title = "Mode", value = getDifficultyLabel(difficultyMode), x = boxX + 586 }
    }

    for i = 1, #cards do
        local item = cards[i]
        drawSoftPanel(item.x, boxY + 138, 140, 104, { 1, 1, 1, 0.12 })
        love.graphics.setFont(fontSmall)
        love.graphics.setColor(0.85, 0.90, 1)
        love.graphics.printf(item.title, item.x, boxY + 154, 140, "center")
        love.graphics.setFont(fontUI)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(item.value, item.x, boxY + 188, 140, "center")
    end

    local rainbowText = "Le tuyau rainbow s'active automatiquement à 100 points."
    if score >= 100 then
        rainbowText = "Le tuyau rainbow s'est activé pendant cette partie."
    elseif bestScore >= 100 then
        rainbowText = "Tu as déjà atteint 100 points au moins une fois."
    end

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.94, 0.88, 1)
    love.graphics.printf(rainbowText, boxX + 34, boxY + 266, boxWidth - 68, "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Entrée = recommencer   Échap = menu", boxX, boxY + 310, boxWidth, "center")
end

-- -------------------------------------------------------------------
-- ROUTEUR D'ECRAN
-- -------------------------------------------------------------------

-- Choisit quoi dessiner selon l'état global du jeu.
function drawCurrentScreen()
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
