-- ===================================================
--    NITRO OS v6.5 - SPECIAL SECRETS EDITION
-- ===================================================

local component = require("component")
local computer = require("computer")
local event = require("event")
local filesystem = require("filesystem")

local function analyzeHardware()
  local gpuOk = component.isAvailable("gpu")
  if not gpuOk then
    return false
  end
  return true
end

if not analyzeHardware() then
  return
end

local gpu = component.gpu
local isInstalled = filesystem.exists("/.nitro_installed")
local installStep = 1
local selectedLang = "PT-BR"

local rawUpdateUrl = "https://raw.githubusercontent.com/pmiguel10766-stack/-opencomputers-script/main/init.lua"

gpu.setResolution(80, 25)
local maxW, maxH = 80, 25

-- Cores do Sistema
local COLOR_BG       = 0x101014
local COLOR_CARD     = 0x1B1B22
local COLOR_ACCENT   = 0x00E676  -- Verde Nitro
local COLOR_TEXT     = 0xFFFFFF
local COLOR_SUBTEXT  = 0x6E6E7E
local COLOR_MENU_BG  = 0x15151C
local COLOR_RED      = 0xB71C1C
local COLOR_C_STRIPE = 0x22222E

local isStartMenuOpen = false
local currentApp = nil
local webUrlInput = rawUpdateUrl
local webContent = "Digite uma URL HTTP/HTTPS para navegar."

local currentPath = "/"
local fileListCache = {}

-- Editor de Texto
local editFilePath = ""
local editFileContent = ""

-- App Impressora 3D
local modelName = "modelo1.3d"
local modelGrid = {}
for r = 1, 8 do
  modelGrid[r] = {}
  for c = 1, 8 do
    modelGrid[r][c] = 0
  end
end
local printStatusMsg = "Pronto para projetar."

-- ===================================================
-- LOGO "CO" MINIMALISTA (COM SUPORTE A GATILHO OCULTO)
-- ===================================================
local function drawCOLogo(cx, cy)
  gpu.setBackground(COLOR_BG)
  gpu.setForeground(COLOR_C_STRIPE)

  gpu.set(cx - 15, cy - 3, "------------------------")
  gpu.set(cx - 15, cy - 2, "|                      |")
  gpu.set(cx - 15, cy - 1, "|  ||||||||||||||||||  |")
  gpu.set(cx - 15, cy,     "|  ||")
  gpu.set(cx - 15, cy + 1, "|  ||")
  gpu.set(cx - 15, cy + 2, "|  ||")
  gpu.set(cx - 15, cy + 3, "|  ||")
  gpu.set(cx - 15, cy + 4, "|  ||")
  gpu.set(cx - 15, cy + 5, "|  ||||||||||||||||||  |")
  gpu.set(cx - 15, cy + 6, "|                      |")
  gpu.set(cx - 15, cy + 7, "------------------------")

  gpu.setBackground(COLOR_RED)
  gpu.setForeground(COLOR_TEXT)
  gpu.fill(cx + 1, cy, 9, 5, " ")
  gpu.set(cx + 3, cy + 1, ">  <")
  gpu.set(cx + 3, cy + 3, "\\__/")
end

-- ===================================================
-- TELA DE BOOT
-- ===================================================
local function showOfficialBootScreen(statusMsg)
  gpu.setBackground(COLOR_BG)
  gpu.fill(1, 1, maxW, maxH, " ")

  local cx, cy = math.floor(maxW / 2) - 2, 6
  drawCOLogo(cx, cy)

  local barX, barY, barWidth = cx - 18, cy + 10, 40

  gpu.setBackground(COLOR_BG)
  gpu.setForeground(COLOR_SUBTEXT)
  gpu.set(barX, barY - 1, string.format("%-36s", statusMsg or "Carregando..."))

  gpu.setBackground(0x08080A)
  gpu.fill(barX, barY, barWidth, 1, " ")

  for pct = 0, 100, 5 do
    local filled = math.floor((barWidth * pct) / 100)
    if filled > 0 then
      gpu.setBackground(COLOR_ACCENT)
      gpu.fill(barX, barY, filled, 1, " ")
    end
    gpu.setBackground(COLOR_BG)
    gpu.setForeground(COLOR_ACCENT)
    gpu.set(barX + barWidth + 2, barY, string.format("%3d%%", pct))
    os.sleep(0.01)
  end
  os.sleep(0.1)
end

-- ===================================================
-- REMOVER OPENOS E INSTALAR NITRO OS
-- ===================================================
local function wipeOpenOSAndInstall()
  showOfficialBootScreen("Removendo arquivos antigos...")
  
  if filesystem.exists("/bin") then filesystem.remove("/bin") end
  if filesystem.exists("/lib") then filesystem.remove("/lib") end
  if filesystem.exists("/boot") then filesystem.remove("/boot") end

  showOfficialBootScreen("Baixando Nitro OS do GitHub...")
  local downloadedContent = ""
  if component.isAvailable("internet") then
    local handle = component.internet.request(rawUpdateUrl)
    if handle then
      while true do
        local chunk = handle.read(math.huge)
        if not chunk then break end
        downloadedContent = downloadedContent .. chunk
      end
      handle.close()
    end
  end

  showOfficialBootScreen("Gravando sistema...")
  local file = filesystem.open("/init.lua", "w")
  if #downloadedContent > 0 then
    file:write(downloadedContent)
  end
  file:close()

  local marker = filesystem.open("/.nitro_installed", "w")
  marker:write("installed=true\nlang=" .. selectedLang)
  marker:close()

  showOfficialBootScreen("Reiniciando...")
  computer.shutdown(true)
end

-- ===================================================
-- SEGREDOS: 1. EFEITO MATRIX RAIN
-- ===================================================
local function runMatrixEffect()
  gpu.setBackground(0x000000)
  gpu.fill(1, 1, maxW, maxH, " ")

  local chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ#@$%&*<>"
  local drops = {}
  for c = 1, maxW do
    drops[c] = math.random(-15, 0)
  end

  while true do
    for c = 1, maxW do
      if math.random(1, 3) == 1 then
        local headY = drops[c]
        if headY >= 1 and headY <= maxH then
          local charIndex = math.random(1, #chars)
          local randomChar = string.sub(chars, charIndex, charIndex)
          
          gpu.setBackground(0x000000)
          gpu.setForeground(0xFFFFFF)
          gpu.set(c, headY, randomChar)

          if headY - 1 >= 1 then
            gpu.setForeground(COLOR_ACCENT)
            gpu.set(c, headY - 1, string.sub(chars, math.random(1, #chars), math.random(1, #chars)))
          end
          if headY - 8 >= 1 then
            gpu.setForeground(0x003300)
            gpu.set(c, headY - 8, string.sub(chars, math.random(1, #chars), math.random(1, #chars)))
          end
          if headY - 12 >= 1 then
            gpu.set(c, headY - 12, " ")
          end
        end

        drops[c] = drops[c] + 1
        if drops[c] > maxH + 12 then
          drops[c] = math.random(-5, 0)
        end
      end
    end

    local ev = event.pull(0.04)
    if ev == "touch" or ev == "key_down" then
      break
    end
  end
end

-- ===================================================
-- SEGREDOS: 2. ALARME KERNEL PANIC / RADIAÇÃO
-- ===================================================
local function runMeltdownAlarm()
  for countdown = 5, 1, -1 do
    gpu.setBackground(COLOR_RED)
    gpu.fill(1, 1, maxW, maxH, " ")
    gpu.setForeground(0xFFFFFF)
    gpu.set(15, 8,  "==================================================")
    gpu.set(15, 9,  "   !!! ALERTA CRITICO: DERRETIMENTO DE NUCLEO !!!  ")
    gpu.set(15, 10, "==================================================")
    gpu.set(20, 13, string.format("CONTAMINACAO POR RADIACAO EM: %d SEGUNDOS", countdown))
    gpu.set(22, 15, "EVACUACAO DO COMPUTADOR RECOMENDADA")
    computer.beep(1200, 0.15)
    os.sleep(0.3)

    gpu.setBackground(0x220000)
    gpu.fill(1, 1, maxW, maxH, " ")
    gpu.setForeground(COLOR_RED)
    gpu.set(15, 8,  "==================================================")
    gpu.set(15, 9,  "   !!! ALERTA CRITICO: DERRETIMENTO DE NUCLEO !!!  ")
    gpu.set(15, 10, "==================================================")
    gpu.set(20, 13, string.format("CONTAMINACAO POR RADIACAO EM: %d SEGUNDOS", countdown))
    computer.beep(600, 0.15)
    os.sleep(0.3)
  end

  computer.beep(2000, 0.4)
  gpu.setBackground(COLOR_ACCENT)
  gpu.fill(1, 1, maxW, maxH, " ")
  gpu.setForeground(0x000000)
  gpu.set(20, 11, "========================================")
  gpu.set(20, 12, "    SISTEMA SEGURO - APENAS UM TESTE    ")
  gpu.set(20, 13, "========================================")
  gpu.set(22, 16, " [ Clique em qualquer lugar para sair ] ")

  while true do
    local ev = event.pull("touch")
    if ev then break end
  end
end

-- ===================================================
-- SEGREDOS: 3. TELEMETRIA AVANÇADA DO HARDWARE
-- ===================================================
local function drawTelemetryApp()
  gpu.setBackground(COLOR_CARD)
  gpu.fill(4, 2, maxW - 8, maxH - 4, " ")

  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.fill(4, 2, maxW - 8, 1, " ")
  gpu.set(6, 2, "TELEMETRIA DE HARDWARE NITRO OS")

  gpu.setBackground(0x101016)
  gpu.fill(6, 4, maxW - 12, maxH - 7, " ")

  local freeMem = math.floor(computer.freeMemory() / 1024)
  local totalMem = math.floor(computer.totalMemory() / 1024)
  local usedMem = totalMem - freeMem
  local memPct = math.floor((usedMem / totalMem) * 100)

  local curEnergy = math.floor(computer.energy())
  local maxEnergy = math.floor(computer.maxEnergy())
  local energyPct = maxEnergy > 0 and math.floor((curEnergy / maxEnergy) * 100) or 0

  local uptimeSecs = math.floor(computer.uptime())
  local uptimeFormatted = os.date("!%H:%M:%S", uptimeSecs)

  gpu.setForeground(COLOR_ACCENT)
  gpu.set(8, 6,  "-> MEMORIA RAM:")
  gpu.setForeground(COLOR_TEXT)
  gpu.set(25, 6, string.format("%d KB / %d KB (%d%% Usado)", usedMem, totalMem, memPct))

  gpu.setForeground(COLOR_ACCENT)
  gpu.set(8, 9,  "-> ENERGIA BUFFER:")
  gpu.setForeground(COLOR_TEXT)
  gpu.set(25, 9, string.format("%d EU/RF / %d EU/RF (%d%%)", curEnergy, maxEnergy, energyPct))

  gpu.setForeground(COLOR_ACCENT)
  gpu.set(8, 12, "-> TEMPO LIGADO:")
  gpu.setForeground(COLOR_TEXT)
  gpu.set(25, 12, uptimeFormatted .. " (HH:MM:SS)")

  gpu.setForeground(COLOR_ACCENT)
  gpu.set(8, 15, "-> PLACA GRAFICA:")
  gpu.setForeground(COLOR_TEXT)
  local gw, gh = gpu.maxResolution()
  gpu.set(25, 15, string.format("Res Max %dx%d | Cores: 8-bit", gw, gh))

  gpu.setBackground(COLOR_RED)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(maxW - 7, 2, " X ")
end

-- ===================================================
-- SEGREDOS: 4. MINIGAME ASCII SNAKE
-- ===================================================
local function runSnakeGame()
  local gW, gH = 15, 15
  local offsetX, offsetY = 32, 6

  local snake = {{x = 8, y = 8}, {x = 7, y = 8}, {x = 6, y = 8}}
  local dirX, dirY = 1, 0
  local food = {x = math.random(1, gW), y = math.random(1, gH)}
  local score = 0
  local gameOver = false

  while not gameOver do
    gpu.setBackground(COLOR_CARD)
    gpu.fill(4, 2, maxW - 8, maxH - 4, " ")
    
    gpu.setBackground(COLOR_ACCENT)
    gpu.setForeground(0x000000)
    gpu.fill(4, 2, maxW - 8, 1, " ")
    gpu.set(6, 2, string.format("SNAKE ASCII - PONTOS: %d | (Use as Setas / WASD)", score))

    gpu.setBackground(COLOR_RED)
    gpu.setForeground(COLOR_TEXT)
    gpu.set(maxW - 7, 2, " X ")

    -- Renderiza campo do jogo
    gpu.setBackground(0x08080A)
    gpu.fill(offsetX - 1, offsetY - 1, gW + 2, gH + 2, " ")

    -- Renderiza Comida
    gpu.setBackground(COLOR_RED)
    gpu.set(offsetX + food.x - 1, offsetY + food.y - 1, " ")

    -- Renderiza Cobrinha
    for i, p in ipairs(snake) do
      gpu.setBackground(i == 1 and COLOR_ACCENT or 0x00AA44)
      gpu.set(offsetX + p.x - 1, offsetY + p.y - 1, " ")
    end

    -- Controles na tela
    gpu.setBackground(COLOR_CARD)
    gpu.setForeground(COLOR_TEXT)
    gpu.set(8, 8,  " Controles: ")
    gpu.set(8, 10, "   [W/^]    ")
    gpu.set(8, 11, "[A/<] [S/v] [D/>]")

    local ev, _, char, code = event.pull(0.15)
    if ev == "touch" then
      if char >= maxW - 7 and char <= maxW - 3 and code == 2 then
        break
      end
    elseif ev == "key_down" then
      -- 200: Up, 208: Down, 203: Left, 205: Right
      if (code == 200 or char == 119) and dirY ~= 1 then dirX, dirY = 0, -1
      elseif (code == 208 or char == 115) and dirY ~= -1 then dirX, dirY = 0, 1
      elseif (code == 203 or char == 97) and dirX ~= 1 then dirX, dirY = -1, 0
      elseif (code == 205 or char == 100) and dirX ~= -1 then dirX, dirY = 1, 0
      end
    end

    -- Movimento
    local head = {x = snake[1].x + dirX, y = snake[1].y + dirY}

    -- Colisao com paredes
    if head.x < 1 or head.x > gW or head.y < 1 or head.y > gH then
      gameOver = true
    end

    -- Colisao com corpo
    for i = 1, #snake do
      if snake[i].x == head.x and snake[i].y == head.y then
        gameOver = true
      end
    end

    if not gameOver then
      table.insert(snake, 1, head)
      if head.x == food.x and head.y == food.y then
        score = score + 10
        computer.beep(1000, 0.05)
        food = {x = math.random(1, gW), y = math.random(1, gH)}
      else
        table.remove(snake)
      end
    end
  end

  if gameOver then
    computer.beep(300, 0.3)
    gpu.setBackground(COLOR_RED)
    gpu.setForeground(COLOR_TEXT)
    gpu.set(offsetX - 2, offsetY + 6, " GAME OVER! ")
    os.sleep(1.5)
  end
end

-- ===================================================
-- SEGREDOS: 5. SINTETIZADOR DE SOM 8-BITS
-- ===================================================
local notes = {
  {name = "Do",  freq = 261},
  {name = "Re",  freq = 293},
  {name = "Mi",  freq = 329},
  {name = "Fa",  freq = 349},
  {name = "Sol", freq = 392},
  {name = "La",  freq = 440},
  {name = "Si",  freq = 493},
  {name = "Do+", freq = 523}
}

local function drawSynthesizerApp()
  gpu.setBackground(COLOR_CARD)
  gpu.fill(4, 2, maxW - 8, maxH - 4, " ")

  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.fill(4, 2, maxW - 8, 1, " ")
  gpu.set(6, 2, "SINTETIZADOR DE SOM 8-BITS (BUZZER)")

  gpu.setBackground(0x101016)
  gpu.fill(6, 4, maxW - 12, maxH - 7, " ")

  gpu.setForeground(COLOR_TEXT)
  gpu.set(8, 5, "Clique nas teclas musicais para tocar:")

  -- Desenha as teclas
  for i, n in ipairs(notes) do
    local bx = 8 + (i - 1) * 8
    gpu.setBackground(0x252530)
    gpu.setForeground(COLOR_ACCENT)
    gpu.fill(bx, 8, 6, 5, " ")
    gpu.set(bx + 1, 10, n.name)
  end

  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.set(8, 16, " Tocar Melodia Demo ")

  gpu.setBackground(COLOR_RED)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(maxW - 7, 2, " X ")
end

local function playMelodyDemo()
  local melody = {261, 261, 392, 392, 440, 440, 392, 349, 349, 329, 329, 293, 293, 261}
  for _, f in ipairs(melody) do
    computer.beep(f, 0.12)
    os.sleep(0.05)
  end
end

-- ===================================================
-- SEGREDOS: PAINEL HUB DOS SEGREDOS
-- ===================================================
local function drawSecretsApp()
  gpu.setBackground(COLOR_CARD)
  gpu.fill(4, 2, maxW - 8, maxH - 4, " ")

  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.fill(4, 2, maxW - 8, 1, " ")
  gpu.set(6, 2, "NITRO OS - AREA SECRETAS / EASTER EGGS")

  gpu.setBackground(0x101016)
  gpu.fill(6, 4, maxW - 12, maxH - 7, " ")

  gpu.setBackground(0x252530)
  gpu.setForeground(COLOR_TEXT)
  
  gpu.set(8, 6,  " 1. Efeito Matrix Rain            ")
  gpu.set(8, 9,  " 2. Alarme Kernel Panic (Fake)    ")
  gpu.set(8, 12, " 3. Telemetria do Hardware        ")
  gpu.set(8, 15, " 4. Jogo da Cobrinha (Snake ASCII)")
  gpu.set(8, 18, " 5. Sintetizador de Som 8-Bits    ")

  gpu.setBackground(COLOR_RED)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(maxW - 7, 2, " X ")
end

-- ===================================================
-- EXPLORADOR DE ARQUIVOS
-- ===================================================
local function drawFilesApp()
  gpu.setBackground(COLOR_CARD)
  gpu.fill(4, 2, maxW - 8, maxH - 4, " ")

  gpu.setBackground(0x121218)
  gpu.setForeground(COLOR_ACCENT)
  gpu.set(6, 3, "DIR:")
  gpu.setBackground(0x252530)
  gpu.setForeground(COLOR_TEXT)
  gpu.fill(11, 3, 55, 1, " ")
  gpu.set(12, 3, string.sub(currentPath, 1, 53))

  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.set(68, 3, " [<-] ")

  gpu.setBackground(0x101016)
  gpu.fill(6, 5, maxW - 12, maxH - 8, " ")

  fileListCache = {}
  local lineY = 5
  if filesystem.exists(currentPath) then
    for item in filesystem.list(currentPath) do
      if lineY > maxH - 5 then break end
      table.insert(fileListCache, item)
      
      local fullPath = currentPath == "/" and ("/" .. item) or (currentPath .. "/" .. item)
      local isDir = filesystem.isDirectory(fullPath)
      local sizeStr = isDir and "<DIR>" or string.format("%d B", filesystem.size(fullPath) or 0)

      gpu.setForeground(isDir and COLOR_ACCENT or COLOR_TEXT)
      gpu.set(8, lineY, string.format("%-35s %15s", item, sizeStr))
      lineY = lineY + 1
    end
  end

  gpu.setBackground(COLOR_RED)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(maxW - 7, 2, " X ")
end

-- ===================================================
-- EDITOR DE TEXTO
-- ===================================================
local function loadFileToEditor(path)
  editFilePath = path
  editFileContent = ""
  if filesystem.exists(path) and not filesystem.isDirectory(path) then
    local file, reason = filesystem.open(path, "r")
    if file then
      while true do
        local line = file:read("*l")
        if not line then break end
        editFileContent = editFileContent .. line .. "\n"
      end
      file:close()
    else
      editFileContent = "Erro ao abrir arquivo: " .. tostring(reason)
    end
  else
    editFileContent = "-- Novo Arquivo\n"
  end
end

local function drawEditorApp()
  gpu.setBackground(COLOR_CARD)
  gpu.fill(4, 2, maxW - 8, maxH - 4, " ")

  gpu.setBackground(0x121218)
  gpu.setForeground(COLOR_ACCENT)
  gpu.set(6, 3, "EDIT:")
  gpu.setBackground(0x252530)
  gpu.setForeground(COLOR_TEXT)
  gpu.fill(12, 3, 54, 1, " ")
  gpu.set(13, 3, string.sub(editFilePath, 1, 52))

  gpu.setBackground(0x101016)
  gpu.fill(6, 5, maxW - 12, maxH - 8, " ")
  gpu.setForeground(COLOR_TEXT)

  local lineY = 6
  for line in string.gmatch(editFileContent .. "\n", "([^\r\n]*)\r?\n") do
    if lineY > maxH - 4 then break end
    gpu.set(8, lineY, string.sub(line, 1, maxW - 16))
    lineY = lineY + 1
  end

  gpu.setBackground(COLOR_RED)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(maxW - 7, 2, " X ")
end

-- ===================================================
-- APP DE IMPRESSORA 3D
-- ===================================================
local function save3DModel()
  local fullPath = "/" .. modelName
  local file = filesystem.open(fullPath, "w")
  if file then
    file:write("-- NitroOS 3D Print Model\n")
    for r = 1, 8 do
      for c = 1, 8 do
        if modelGrid[r][c] == 1 then
          file:write(string.format("voxel(%d,%d,1)\n", r, c))
        end
      end
    end
    file:close()
    printStatusMsg = "Salvo em: " .. fullPath
  else
    printStatusMsg = "Erro ao salvar arquivo."
  end
end

local function print3DModelHardware()
  if not component.isAvailable("print3d") then
    printStatusMsg = "Erro: Impressora 3D nao conectada!"
    return
  end
  
  local printer = component.print3d
  local success, reason = pcall(function()
    printer.reset()
    for r = 1, 8 do
      for c = 1, 8 do
        if modelGrid[r][c] == 1 then
          printer.addShape(r - 1, 0, c - 1, r, 1, c, 0)
        end
      end
    end
    printer.print()
  end)

  if success then
    printStatusMsg = "Impressao iniciada com sucesso!"
  else
    printStatusMsg = "Falha: " .. tostring(reason)
  end
end

local function draw3DApp()
  gpu.setBackground(COLOR_CARD)
  gpu.fill(4, 2, maxW - 8, maxH - 4, " ")

  gpu.setBackground(0x121218)
  gpu.setForeground(COLOR_ACCENT)
  gpu.set(6, 3, "MAQUINA 3D:")
  gpu.setBackground(0x252530)
  gpu.setForeground(COLOR_TEXT)
  gpu.fill(18, 3, 48, 1, " ")
  gpu.set(19, 3, modelName)

  gpu.setBackground(0x101016)
  gpu.fill(6, 5, maxW - 12, maxH - 8, " ")

  local startX, startY = 10, 7
  for r = 1, 8 do
    for c = 1, 8 do
      if modelGrid[r][c] == 1 then
        gpu.setBackground(COLOR_ACCENT)
        gpu.setForeground(0x000000)
        gpu.set(startX + (c * 3) - 2, startY + r, "   ")
      else
        gpu.setBackground(0x22222E)
        gpu.setForeground(COLOR_SUBTEXT)
        gpu.set(startX + (c * 3) - 2, startY + r, " . ")
      end
    end
  end

  gpu.setBackground(COLOR_CARD)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(38, 7, "Acoes do Modelo:")
  
  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.set(38, 10, " Salvar Arquivo ")
  gpu.set(38, 13, " Imprimir (3D)  ")
  gpu.set(38, 16, " Limpar Grade   ")

  gpu.setForeground(COLOR_SUBTEXT)
  gpu.set(6, maxH - 6, "Status: " .. printStatusMsg)

  gpu.setBackground(COLOR_RED)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(maxW - 7, 2, " X ")
end

-- ===================================================
-- NAVEGADOR WEB
-- ===================================================
local function fetchWebUrl(url)
  if not component.isAvailable("internet") then
    return "ERRO: Placa de Internet nao encontrada."
  end

  local handle = component.internet.request(url)
  if not handle then return "ERRO: Impossivel conectar." end

  local data = ""
  while true do
    local chunk = handle.read(math.huge)
    if not chunk then break end
    data = data .. chunk
    if #data > 2000 then break end
  end
  handle.close()

  return #data > 0 and data or "Pagina sem conteudo."
end

local function drawWebApp()
  gpu.setBackground(COLOR_CARD)
  gpu.fill(4, 2, maxW - 8, maxH - 4, " ")

  gpu.setBackground(0x121218)
  gpu.setForeground(COLOR_ACCENT)
  gpu.set(6, 3, "URL:")
  gpu.setBackground(0x252530)
  gpu.setForeground(COLOR_TEXT)
  gpu.fill(12, 3, 54, 1, " ")
  gpu.set(13, 3, string.sub(webUrlInput, 1, 52))

  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.set(68, 3, "  IR  ")

  gpu.setBackground(0x101016)
  gpu.fill(6, 5, maxW - 12, maxH - 8, " ")
  gpu.setForeground(COLOR_TEXT)

  local lineY = 6
  for line in string.gmatch(webContent, "[^\r\n]+") do
    if lineY > maxH - 4 then break end
    gpu.set(8, lineY, string.sub(line, 1, maxW - 16))
    lineY = lineY + 1
  end

  gpu.setBackground(COLOR_RED)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(maxW - 7, 2, " X ")
end

-- ===================================================
-- MENU INICIAR & DESKTOP
-- ===================================================
local function drawStartMenu()
  gpu.setBackground(COLOR_MENU_BG)
  gpu.fill(2, maxH - 18, 28, 17, " ")

  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.fill(2, maxH - 18, 28, 1, " ")
  gpu.set(4, maxH - 18, "NITRO OS - MENU")

  gpu.setBackground(COLOR_MENU_BG)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(4, maxH - 16, "1. Meus Arquivos (HDD)")
  gpu.set(4, maxH - 14, "2. Navegador Web")
  gpu.set(4, maxH - 12, "3. Impressora 3D")
  gpu.set(4, maxH - 10, "4. Segredos & Extras")
  gpu.set(4, maxH - 8,  "5. Atualizar Sistema")
  gpu.set(4, maxH - 6,  "6. Configuracoes")
  gpu.set(4, maxH - 4,  "7. Reiniciar Sistema")
  gpu.set(4, maxH - 2,  "8. Desligar Computador")
end

local function drawDesktop()
  gpu.setBackground(COLOR_BG)
  gpu.fill(1, 1, maxW, maxH, " ")

  local cx, cy = math.floor(maxW / 2) - 2, 6
  drawCOLogo(cx, cy)

  if currentApp == "WEB" then
    drawWebApp()
  elseif currentApp == "FILES" then
    drawFilesApp()
  elseif currentApp == "EDITOR" then
    drawEditorApp()
  elseif currentApp == "MODEL3D" then
    draw3DApp()
  elseif currentApp == "SECRETS" then
    drawSecretsApp()
  elseif currentApp == "TELEMETRY" then
    drawTelemetryApp()
  elseif currentApp == "SYNTH" then
    drawSynthesizerApp()
  end

  gpu.setBackground(COLOR_CARD)
  gpu.fill(1, maxH, maxW, 1, " ")

  gpu.setBackground(isStartMenuOpen and 0x2A2A38 or COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.set(2, maxH, " Menu ")

  gpu.setBackground(COLOR_CARD)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(12, maxH, "Arquivos | Web | App 3D | Segredos | Atualizar")

  if isStartMenuOpen then
    drawStartMenu()
  end
end

-- ===================================================
-- WIZARD DE INSTALACAO
-- ===================================================
local function drawWindow(title, renderContent)
  gpu.setBackground(COLOR_BG)
  gpu.fill(1, 1, maxW, maxH, " ")

  gpu.setBackground(COLOR_CARD)
  gpu.fill(8, 3, maxW - 16, maxH - 5, " ")

  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.fill(8, 3, maxW - 16, 1, " ")
  gpu.set(10, 3, "NITRO OS SETUP - " .. title)

  gpu.setBackground(COLOR_CARD)
  gpu.setForeground(COLOR_TEXT)
  renderContent(12, 6)
end

local function showLanguageStep()
  drawWindow("IDIOMA (2/3)", function(rx, ry)
    gpu.set(rx, ry,     "Selecione o idioma padrao:")

    gpu.setBackground(selectedLang == "PT-BR" and COLOR_ACCENT or 0x2A2A38)
    gpu.setForeground(selectedLang == "PT-BR" and 0x000000 or COLOR_TEXT)
    gpu.set(rx + 2, ry + 4, "  Portugues (Brasil)  ")

    gpu.setBackground(COLOR_ACCENT)
    gpu.setForeground(0x000000)
    gpu.set(rx + 42, ry + 10, "  Avancar ->  ")
  end)
end

local function showInstallStep()
  drawWindow("INSTALACAO (3/3)", function(rx, ry)
    gpu.set(rx, ry,     "Destino: Disco Rigido OpenComputers")
    gpu.set(rx, ry + 1, "Origem: github.com/pmiguel10766-stack/-opencomputers-script")
    gpu.set(rx, ry + 3, "O OpenOS sera removido para a instalacao do Nitro OS.")

    gpu.setBackground(COLOR_ACCENT)
    gpu.setForeground(0x000000)
    gpu.set(rx + 2, ry + 7, "  Instalar Nitro OS  ")
  end)
end

-- ===================================================
-- CICLO PRINCIPAL DO SISTEMA
-- ===================================================
if not isInstalled then
  showOfficialBootScreen("Iniciando Setup...")
  showLanguageStep()
else
  showOfficialBootScreen("Iniciando Nitro OS v6.5...")
  drawDesktop()
end

while true do
  local eventType, _, x, y = event.pull(0.5, "touch")

  if eventType == "touch" and x and y then
    if not isInstalled then
      if installStep == 1 then
        installStep = 2
        showLanguageStep()
      elseif installStep == 2 then
        if x >= 54 and x <= 66 and y == 16 then
          installStep = 3
          showInstallStep()
        end
      elseif installStep == 3 then
        if x >= 14 and x <= 36 and y == 13 then
          wipeOpenOSAndInstall()
        end
      end
    else
      -- ===================================================
      -- GATILHO OCULTO: CLIQUE NA LOGO "CO" NO DESKTOP
      -- ===================================================
      local logoCX, logoCY = math.floor(maxW / 2) - 2, 6
      if currentApp == nil and not isStartMenuOpen and
         x >= (logoCX - 15) and x <= (logoCX + 9) and
         y >= (logoCY - 3) and y <= (logoCY + 7) then
        currentApp = "SECRETS"
        drawDesktop()

      -- Barra de tarefas (Menu Iniciar)
      elseif y == maxH and x >= 2 and x <= 8 then
        isStartMenuOpen = not isStartMenuOpen
        drawDesktop()
      elseif y == maxH and x >= 12 and x <= 19 then
        currentApp = "FILES"
        currentPath = "/"
        isStartMenuOpen = false
        drawDesktop()
      elseif y == maxH and x >= 22 and x <= 25 then
        currentApp = "WEB"
        isStartMenuOpen = false
        drawDesktop()
      elseif y == maxH and x >= 28 and x <= 35 then
        currentApp = "MODEL3D"
        isStartMenuOpen = false
        drawDesktop()
      elseif y == maxH and x >= 38 and x <= 46 then
        currentApp = "SECRETS"
        isStartMenuOpen = false
        drawDesktop()

      -- Opções do Menu Iniciar
      elseif isStartMenuOpen and x >= 2 and x <= 30 then
        if y == maxH - 16 then
          currentApp = "FILES"
          currentPath = "/"
          isStartMenuOpen = false
          drawDesktop()
        elseif y == maxH - 14 then
          currentApp = "WEB"
          isStartMenuOpen = false
          drawDesktop()
        elseif y == maxH - 12 then
          currentApp = "MODEL3D"
          isStartMenuOpen = false
          drawDesktop()
        elseif y == maxH - 10 then
          currentApp = "SECRETS"
          isStartMenuOpen = false
          drawDesktop()
        elseif y == maxH - 8 then
          isStartMenuOpen = false
          wipeOpenOSAndInstall()
        elseif y == maxH - 4 then
          showOfficialBootScreen("Reiniciando...")
          computer.shutdown(true)
        elseif y == maxH - 2 then
          showOfficialBootScreen("Desligando...")
          computer.shutdown(false)
        end

      -- APP: SEGREDOS / EASTER EGGS
      elseif currentApp == "SECRETS" then
        if y == 2 and x >= maxW - 7 and x <= maxW - 3 then
          currentApp = nil
          drawDesktop()
        elseif x >= 8 and x <= 42 then
          if y == 6 then
            runMatrixEffect()
            drawDesktop()
          elseif y == 9 then
            runMeltdownAlarm()
            drawDesktop()
          elseif y == 12 then
            currentApp = "TELEMETRY"
            drawDesktop()
          elseif y == 15 then
            runSnakeGame()
            drawDesktop()
          elseif y == 18 then
            currentApp = "SYNTH"
            drawDesktop()
          end
        end

      -- APP: TELEMETRIA DA MÁQUINA
      elseif currentApp == "TELEMETRY" then
        if y == 2 and x >= maxW - 7 and x <= maxW - 3 then
          currentApp = "SECRETS"
          drawDesktop()
        end

      -- APP: SINTETIZADOR 8-BITS
      elseif currentApp == "SYNTH" then
        if y == 2 and x >= maxW - 7 and x <= maxW - 3 then
          currentApp = "SECRETS"
          drawDesktop()
        elseif y >= 8 and y <= 12 then
          for i, n in ipairs(notes) do
            local bx = 8 + (i - 1) * 8
            if x >= bx and x <= bx + 5 then
              computer.beep(n.freq, 0.15)
              break
            end
          end
        elseif y == 16 and x >= 8 and x <= 28 then
          playMelodyDemo()
        end

      -- APP: MEUS ARQUIVOS
      elseif currentApp == "FILES" then
        if y == 2 and x >= maxW - 7 and x <= maxW - 3 then
          currentApp = nil
          drawDesktop()
        elseif y == 3 and x >= 68 and x <= 74 then
          if currentPath ~= "/" then
            local parent = filesystem.path(currentPath)
            currentPath = (parent == "" or parent == nil) and "/" or parent
          else
            currentPath = "/"
          end
          drawDesktop()
        elseif y >= 5 and y < 5 + #fileListCache then
          local clickedIndex = y - 4
          local itemName = fileListCache[clickedIndex]
          if itemName then
            local fullPath = currentPath == "/" and ("/" .. itemName) or (currentPath .. "/" .. itemName)
            if filesystem.isDirectory(fullPath) then
              currentPath = fullPath
              drawDesktop()
            else
              loadFileToEditor(fullPath)
              currentApp = "EDITOR"
              drawDesktop()
            end
          end
        end

      -- APP: EDITOR DE TEXTO
      elseif currentApp == "EDITOR" then
        if y == 2 and x >= maxW - 7 and x <= maxW - 3 then
          currentApp = "FILES"
          drawDesktop()
        end

      -- APP: IMPRESSORA 3D
      elseif currentApp == "MODEL3D" then
        if y == 2 and x >= maxW - 7 and x <= maxW - 3 then
          currentApp = nil
          drawDesktop()
        elseif x >= 11 and x <= 34 and y >= 8 and y <= 15 then
          local gridR = y - 7
          local gridC = math.floor((x - 11) / 3) + 1
          if gridR >= 1 and gridR <= 8 and gridC >= 1 and gridC <= 8 then
            modelGrid[gridR][gridC] = modelGrid[gridR][gridC] == 1 and 0 or 1
            drawDesktop()
          end
        elseif x >= 38 and x <= 53 then
          if y == 10 then
            save3DModel()
            drawDesktop()
          elseif y == 13 then
            print3DModelHardware()
            drawDesktop()
          elseif y == 16 then
            for r = 1, 8 do
              for c = 1, 8 do
                modelGrid[r][c] = 0
              end
            end
            printStatusMsg = "Grade limpa."
            drawDesktop()
          end
        end

      -- APP: NAVEGADOR WEB
      elseif currentApp == "WEB" then
        if y == 2 and x >= maxW - 7 and x <= maxW - 3 then
          currentApp = nil
          drawDesktop()
        elseif y == 3 and x >= 68 and x <= 75 then
          webContent = fetchWebUrl(webUrlInput)
          drawDesktop()
        end
      else
        if isStartMenuOpen then
          isStartMenuOpen = false
          drawDesktop()
        end
      end
    end
  end
end
