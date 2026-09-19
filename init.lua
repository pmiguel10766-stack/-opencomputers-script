-- ===================================================
--   NITRO OS v6.5 - SPECIAL SECRETS & CMD EDITION
-- ===================================================

local component = require("component")
local computer = require("computer")
local event = require("event")
local filesystem = require("filesystem")

local function analyzeHardware()
  return component.isAvailable("gpu")
end

if not analyzeHardware() then
  return
end

local gpu = component.gpu
local isInstalled = filesystem.exists("/.nitro_installed")
local installStep = 2
local selectedLang = "PT-BR"
local userName = "Admin"

-- URL PADRAO DO REPOSITORIO
local rawUpdateUrl = "https://raw.githubusercontent.com/pmiguel10766-stack/Atualizar_Nitro_OS/main/init.lua"

-- Carrega usuario e URL salva se instalado
if isInstalled then
  local file = filesystem.open("/.nitro_installed", "r")
  if file then
    local content = file:read(500) or ""
    file:close()
    for line in string.gmatch(content, "[^\r\n]+") do
      local k, v = string.match(line, "^(%w+)=(.*)$")
      if k == "user" and v and #v > 0 then userName = v end
      if k == "url" and v and #v > 0 then rawUpdateUrl = v end
    end
  end
end

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
local webUrlInput = "https://raw.githubusercontent.com/..."
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

-- Prompt de Comando (CMD)
local cmdInput = ""
local cmdHistory = {
  "Nitro OS v6.5 [Prompt de Comando]",
  "Digite 'help' ou 'ajuda' para listar os comandos.",
  ""
}

-- LOGO "CO" MINIMALISTA
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

-- TELA DE BOOT
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

  for pct = 0, 100, 10 do
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

-- INSTALACAO COM INTERNET CORRIGIDA E URL SALVA
local function wipeOpenOSAndInstall()
  showOfficialBootScreen("Baixando Nitro OS do GitHub...")
  local downloadedContent = ""
  
  if component.isAvailable("internet") then
    local internet = require("internet")
    for chunk in internet.request(rawUpdateUrl) do
      downloadedContent = downloadedContent .. chunk
    end
  end

  if #downloadedContent == 0 then
    showOfficialBootScreen("ERRO: Falha ao baixar atualizacao!")
    os.sleep(2)
    return
  end

  showOfficialBootScreen("Gravando sistema...")
  
  local file = filesystem.open("/init.lua", "w")
  file:write(downloadedContent)
  file:close()

  local marker = filesystem.open("/.nitro_installed", "w")
  marker:write("installed=true\nlang=" .. selectedLang .. "\nuser=" .. userName .. "\nurl=" .. rawUpdateUrl)
  marker:close()

  showOfficialBootScreen("Reiniciando...")
  computer.shutdown(true)
end

-- SEGREDOS: MATRIX, ALARME, TELEMETRIA, SNAKE, SYNTH
local function runMatrixEffect()
  gpu.setBackground(0x000000)
  gpu.fill(1, 1, maxW, maxH, " ")
  local chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ#@$%&*<>"
  local drops = {}
  for c = 1, maxW do drops[c] = math.random(-15, 0) end

  while true do
    for c = 1, maxW do
      if math.random(1, 3) == 1 then
        local headY = drops[c]
        if headY >= 1 and headY <= maxH then
          local charIndex = math.random(1, #chars)
          gpu.setBackground(0x000000)
          gpu.setForeground(0xFFFFFF)
          gpu.set(c, headY, string.sub(chars, charIndex, charIndex))

          if headY - 1 >= 1 then
            gpu.setForeground(COLOR_ACCENT)
            gpu.set(c, headY - 1, string.sub(chars, math.random(1, #chars), math.random(1, #chars)))
          end
          if headY - 12 >= 1 then gpu.set(c, headY - 12, " ") end
        end
        drops[c] = drops[c] + 1
        if drops[c] > maxH + 12 then drops[c] = math.random(-5, 0) end
      end
    end
    local ev = event.pull(0.04)
    if ev == "touch" or ev == "key_down" then break end
  end
end

local function runMeltdownAlarm()
  for countdown = 5, 1, -1 do
    gpu.setBackground(COLOR_RED)
    gpu.fill(1, 1, maxW, maxH, " ")
    gpu.setForeground(0xFFFFFF)
    gpu.set(15, 9,  "   !!! ALERTA CRITICO: DERRETIMENTO DE NUCLEO !!!  ")
    gpu.set(20, 13, string.format("CONTAMINACAO POR RADIACAO EM: %d SEGUNDOS", countdown))
    computer.beep(1200, 0.15)
    os.sleep(0.3)

    gpu.setBackground(0x220000)
    gpu.fill(1, 1, maxW, maxH, " ")
    gpu.setForeground(COLOR_RED)
    gpu.set(15, 9,  "   !!! ALERTA CRITICO: DERRETIMENTO DE NUCLEO !!!  ")
    gpu.set(20, 13, string.format("CONTAMINACAO POR RADIACAO EM: %d SEGUNDOS", countdown))
    computer.beep(600, 0.15)
    os.sleep(0.3)
  end

  computer.beep(2000, 0.4)
  gpu.setBackground(COLOR_ACCENT)
  gpu.fill(1, 1, maxW, maxH, " ")
  gpu.setForeground(0x000000)
  gpu.set(20, 12, "    SISTEMA SEGURO - APENAS UM TESTE    ")
  gpu.set(22, 16, " [ Clique em qualquer lugar para sair ] ")
  while true do if event.pull("touch") then break end end
end

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
  gpu.set(25, 12, os.date("!%H:%M:%S", math.floor(computer.uptime())))

  gpu.setBackground(COLOR_RED)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(maxW - 7, 2, " X ")
end

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
    gpu.set(6, 2, string.format("SNAKE ASCII - PONTOS: %d", score))

    gpu.setBackground(0x08080A)
    gpu.fill(offsetX - 1, offsetY - 1, gW + 2, gH + 2, " ")

    gpu.setBackground(COLOR_RED)
    gpu.set(offsetX + food.x - 1, offsetY + food.y - 1, " ")

    for i, p in ipairs(snake) do
      gpu.setBackground(i == 1 and COLOR_ACCENT or 0x00AA44)
      gpu.set(offsetX + p.x - 1, offsetY + p.y - 1, " ")
    end

    local ev, _, char, code = event.pull(0.15)
    if ev == "touch" and char >= maxW - 7 and char <= maxW - 3 and code == 2 then break end
    if ev == "key_down" then
      if (code == 200 or char == 119) and dirY ~= 1 then dirX, dirY = 0, -1
      elseif (code == 208 or char == 115) and dirY ~= -1 then dirX, dirY = 0, 1
      elseif (code == 203 or char == 97) and dirX ~= 1 then dirX, dirY = -1, 0
      elseif (code == 205 or char == 100) and dirX ~= -1 then dirX, dirY = 1, 0 end
    end

    local head = {x = snake[1].x + dirX, y = snake[1].y + dirY}
    if head.x < 1 or head.x > gW or head.y < 1 or head.y > gH then gameOver = true end
    for i = 1, #snake do if snake[i].x == head.x and snake[i].y == head.y then gameOver = true end end

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
end

local notes = {{name="Do",freq=261},{name="Re",freq=293},{name="Mi",freq=329},{name="Fa",freq=349},{name="Sol",freq=392},{name="La",freq=440},{name="Si",freq=493}}
local function drawSynthesizerApp()
  gpu.setBackground(COLOR_CARD)
  gpu.fill(4, 2, maxW - 8, maxH - 4, " ")
  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.fill(4, 2, maxW - 8, 1, " ")
  gpu.set(6, 2, "SINTETIZADOR DE SOM 8-BITS")
  gpu.setBackground(0x101016)
  gpu.fill(6, 4, maxW - 12, maxH - 7, " ")
  gpu.setForeground(COLOR_TEXT)
  gpu.set(8, 5, "Clique nas teclas musicais:")

  for i, n in ipairs(notes) do
    local bx = 8 + (i - 1) * 8
    gpu.setBackground(0x252530)
    gpu.setForeground(COLOR_ACCENT)
    gpu.fill(bx, 8, 6, 5, " ")
    gpu.set(bx + 1, 10, n.name)
  end

  gpu.setBackground(COLOR_RED)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(maxW - 7, 2, " X ")
end

local function drawSecretsApp()
  gpu.setBackground(COLOR_CARD)
  gpu.fill(4, 2, maxW - 8, maxH - 4, " ")
  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.fill(4, 2, maxW - 8, 1, " ")
  gpu.set(6, 2, "NITRO OS - AREA SECRETAS / EXTRA")

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

-- PROMPT DE COMANDO (CMD APP) COM SUPORTE A ALTERAR URL
local function processCMDCommand(rawCmd)
  local cmd = string.match(rawCmd, "^%s*(.-)%s*$")
  if cmd == "" then return end

  table.insert(cmdHistory, "> " .. cmd)
  local args = {}
  for word in string.gmatch(cmd, "%S+") do table.insert(args, word) end
  local action = string.lower(args[1] or "")

  if action == "help" or action == "ajuda" then
    table.insert(cmdHistory, "Comandos disponiveis:")
    table.insert(cmdHistory, "  cls / clear  - Limpa a tela")
    table.insert(cmdHistory, "  dir / ls     - Lista os arquivos do disco")
    table.insert(cmdHistory, "  cat <arq>    - Exibe o conteudo de um arquivo")
    table.insert(cmdHistory, "  ver          - Exibe a versao do Nitro OS")
    table.insert(cmdHistory, "  whoami       - Exibe o usuario ativo")
    table.insert(cmdHistory, "  url [link]   - Exibe ou altera a URL HTTP de update")
    table.insert(cmdHistory, "  beep         - Emite um som de teste")
    table.insert(cmdHistory, "  echo <texto> - Exibe o texto digitado")
    table.insert(cmdHistory, "  matrix       - Inicia o efeito Matrix")
    table.insert(cmdHistory, "  reboot / off - Reinicia ou desliga o PC")
    table.insert(cmdHistory, "  exit / sair  - Fecha o terminal")

  elseif action == "cls" or action == "clear" then
    cmdHistory = {}

  elseif action == "ver" then
    table.insert(cmdHistory, "Nitro OS v6.5 (Kernel OpenComputers)")

  elseif action == "whoami" then
    table.insert(cmdHistory, userName)

  elseif action == "url" then
    local newUrl = args[2]
    if newUrl then
      rawUpdateUrl = newUrl
      if isInstalled then
        local marker = filesystem.open("/.nitro_installed", "w")
        marker:write("installed=true\nlang=" .. selectedLang .. "\nuser=" .. userName .. "\nurl=" .. rawUpdateUrl)
        marker:close()
      end
      table.insert(cmdHistory, "URL de atualizacao atualizada com sucesso!")
    else
      table.insert(cmdHistory, "URL Atual: " .. rawUpdateUrl)
      table.insert(cmdHistory, "Uso: url <novo_link_raw>")
    end

  elseif action == "beep" then
    computer.beep(1000, 0.2)
    table.insert(cmdHistory, "BEEP enviado para o alto-falante.")

  elseif action == "echo" then
    table.insert(cmdHistory, string.sub(cmd, 6))

  elseif action == "dir" or action == "ls" then
    if filesystem.exists("/") then
      for item in filesystem.list("/") do
        table.insert(cmdHistory, "  " .. item)
      end
    end

  elseif action == "cat" then
    local filename = args[2]
    if filename then
      local path = string.sub(filename, 1, 1) == "/" and filename or ("/" .. filename)
      if filesystem.exists(path) and not filesystem.isDirectory(path) then
        local file = filesystem.open(path, "r")
        if file then
          local content = file:read(200) or ""
          file:close()
          for line in string.gmatch(content, "[^\r\n]+") do
            table.insert(cmdHistory, line)
          end
        end
      else
        table.insert(cmdHistory, "Erro: Arquivo nao encontrado.")
      end
    else
      table.insert(cmdHistory, "Uso: cat <nome_do_arquivo>")
    end

  elseif action == "matrix" then
    runMatrixEffect()

  elseif action == "reboot" or action == "restart" then
    computer.shutdown(true)

  elseif action == "shutdown" or action == "off" then
    computer.shutdown(false)

  elseif action == "exit" or action == "sair" then
    currentApp = nil

  else
    table.insert(cmdHistory, "'" .. action .. "' nao e reconhecido como comando.")
  end

  while #cmdHistory > 14 do
    table.remove(cmdHistory, 1)
  end
end

local function drawCMDApp()
  gpu.setBackground(COLOR_CARD)
  gpu.fill(4, 2, maxW - 8, maxH - 4, " ")

  gpu.setBackground(0x000000)
  gpu.setForeground(COLOR_ACCENT)
  gpu.fill(4, 2, maxW - 8, 1, " ")
  gpu.set(6, 2, "PROMPT DE COMANDO (CMD) - NITRO OS")

  gpu.setBackground(0x000000)
  gpu.fill(6, 4, maxW - 12, maxH - 7, " ")
  gpu.setForeground(COLOR_ACCENT)

  local startY = 5
  for i, line in ipairs(cmdHistory) do
    if startY > maxH - 5 then break end
    gpu.set(8, startY, string.sub(line, 1, maxW - 16))
    startY = startY + 1
  end

  gpu.setForeground(COLOR_TEXT)
  gpu.set(8, maxH - 4, userName .. "@nitro:~# " .. string.sub(cmdInput, 1, 45) .. "_")

  gpu.setBackground(COLOR_RED)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(maxW - 7, 2, " X ")
end

-- APPS: ARQUIVOS, EDITOR, IMPRESSORA 3D, WEB
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
        gpu.set(startX + (c * 3) - 2, startY + r, "   ")
      else
        gpu.setBackground(0x22222E)
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

  gpu.setBackground(COLOR_RED)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(maxW - 7, 2, " X ")
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

-- DESKTOP & MENU INICIAR
local function drawStartMenu()
  gpu.setBackground(COLOR_MENU_BG)
  gpu.fill(2, maxH - 20, 28, 19, " ")

  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.fill(2, maxH - 20, 28, 1, " ")
  gpu.set(4, maxH - 20, "USUARIO: " .. string.upper(userName))

  gpu.setBackground(COLOR_MENU_BG)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(4, maxH - 18, "1. Meus Arquivos (HDD)")
  gpu.set(4, maxH - 16, "2. Prompt de Comando (CMD)")
  gpu.set(4, maxH - 14, "3. Navegador Web")
  gpu.set(4, maxH - 12, "4. Impressora 3D")
  gpu.set(4, maxH - 10, "5. Segredos & Extras")
  gpu.set(4, maxH - 8,  "6. Atualizar Sistema")
  gpu.set(4, maxH - 6,  "7. Configuracoes")
  gpu.set(4, maxH - 4,  "8. Reiniciar Sistema")
  gpu.set(4, maxH - 2,  "9. Desligar Computador")
end

local function drawDesktop()
  gpu.setBackground(COLOR_BG)
  gpu.fill(1, 1, maxW, maxH, " ")

  local cx, cy = math.floor(maxW / 2) - 2, 6
  drawCOLogo(cx, cy)

  if currentApp == "WEB" then drawWebApp()
  elseif currentApp == "FILES" then drawFilesApp()
  elseif currentApp == "EDITOR" then drawEditorApp()
  elseif currentApp == "MODEL3D" then draw3DApp()
  elseif currentApp == "SECRETS" then drawSecretsApp()
  elseif currentApp == "TELEMETRY" then drawTelemetryApp()
  elseif currentApp == "SYNTH" then drawSynthesizerApp()
  elseif currentApp == "CMD" then drawCMDApp()
  end

  gpu.setBackground(COLOR_CARD)
  gpu.fill(1, maxH, maxW, 1, " ")

  gpu.setBackground(isStartMenuOpen and 0x2A2A38 or COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.set(2, maxH, " Menu ")

  gpu.setBackground(COLOR_CARD)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(10, maxH, "Arquivos | CMD | Web | App 3D | Segredos")

  if isStartMenuOpen then
    drawStartMenu()
  end
end

-- WIZARD DE INSTALACAO
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
  drawWindow("IDIOMA (2/4)", function(rx, ry)
    gpu.set(rx, ry, "Selecione o idioma padrao:")
    gpu.setBackground(selectedLang == "PT-BR" and COLOR_ACCENT or 0x2A2A38)
    gpu.setForeground(selectedLang == "PT-BR" and 0x000000 or COLOR_TEXT)
    gpu.set(rx + 2, ry + 4, "   Portugues (Brasil)   ")
    gpu.setBackground(COLOR_ACCENT)
    gpu.setForeground(0x000000)
    gpu.set(rx + 42, ry + 10, "   Avancar ->   ")
  end)
end

local function showUserStep()
  drawWindow("PERFIL DE USUARIO (3/4)", function(rx, ry)
    gpu.set(rx, ry, "Nome do Usuario (Digite no teclado):")
    gpu.setBackground(0x252530)
    gpu.setForeground(COLOR_TEXT)
    gpu.fill(rx, ry + 2, 30, 1, " ")
    gpu.set(rx + 1, ry + 2, userName .. "_")

    gpu.setBackground(COLOR_CARD)
    gpu.setForeground(COLOR_SUBTEXT)
    gpu.set(rx, ry + 5, "Senha: Desativada (Boot Instantaneo)")

    gpu.setBackground(COLOR_ACCENT)
    gpu.setForeground(0x000000)
    gpu.set(rx + 42, ry + 10, "   Avancar ->   ")
  end)
end

local function showInstallStep()
  drawWindow("INSTALACAO (4/4)", function(rx, ry)
    gpu.set(rx, ry,     "Usuario: " .. userName)
    gpu.set(rx, ry + 1, "Destino: Disco Rigido OpenComputers")
    gpu.set(rx, ry + 2, "Origem: " .. rawUpdateUrl)
    gpu.setBackground(COLOR_ACCENT)
    gpu.setForeground(0x000000)
    gpu.set(rx + 2, ry + 7, "   Instalar Nitro OS   ")
  end)
end

-- CICLO PRINCIPAL
if not isInstalled then
  showOfficialBootScreen("Iniciando Setup...")
  showLanguageStep()
else
  showOfficialBootScreen("Iniciando Nitro OS v6.5...")
  drawDesktop()
end

while true do
  local eventType, arg1, arg2, arg3 = event.pull(0.1)

  -- TECLADO (INSTALADOR & CMD)
  if eventType == "key_down" then
    local charCode = arg2

    -- Digitação do nome de usuário no Instalador
    if not isInstalled and installStep == 3 then
      if charCode == 13 then
        installStep = 4
        showInstallStep()
      elseif charCode == 8 then
        if #userName > 0 then
          userName = string.sub(userName, 1, #userName - 1)
          showUserStep()
        end
      elseif charCode >= 32 and charCode <= 126 then
        if #userName < 15 then
          userName = userName .. string.char(charCode)
          showUserStep()
        end
      end

    -- Digitação no App CMD
    elseif currentApp == "CMD" then
      if charCode == 13 then
        processCMDCommand(cmdInput)
        cmdInput = ""
        drawDesktop()
      elseif charCode == 8 then
        if #cmdInput > 0 then
          cmdInput = string.sub(cmdInput, 1, #cmdInput - 1)
          drawDesktop()
        end
      elseif charCode >= 32 and charCode <= 126 then
        if #cmdInput < 50 then
          cmdInput = cmdInput .. string.char(charCode)
          drawDesktop()
        end
      end
    end

  -- TOQUE NA TELA
  elseif eventType == "touch" then
    local x, y = arg2, arg3

    if not isInstalled then
      if installStep == 2 and x >= 54 and x <= 66 and y == 16 then 
        installStep = 3 
        showUserStep()
      elseif installStep == 3 and x >= 54 and x <= 66 and y == 16 then
        if #userName == 0 then userName = "Admin" end
        installStep = 4
        showInstallStep()
      elseif installStep == 4 and x >= 14 and x <= 36 and y == 13 then 
        wipeOpenOSAndInstall() 
      end
    else
      local logoCX, logoCY = math.floor(maxW / 2) - 2, 6
      if currentApp == nil and not isStartMenuOpen and x >= (logoCX - 15) and x <= (logoCX + 9) and y >= (logoCY - 3) and y <= (logoCY + 7) then
        currentApp = "SECRETS"
        drawDesktop()

      -- BARRA DE TAREFAS
      elseif y == maxH and x >= 2 and x <= 8 then
        isStartMenuOpen = not isStartMenuOpen
        drawDesktop()
      elseif y == maxH and x >= 10 and x <= 17 then
        currentApp = "FILES"
        currentPath = "/"
        isStartMenuOpen = false
        drawDesktop()
      elseif y == maxH and x >= 19 and x <= 22 then
        currentApp = "CMD"
        isStartMenuOpen = false
        drawDesktop()
      elseif y == maxH and x >= 24 and x <= 27 then
        currentApp = "WEB"
        isStartMenuOpen = false
        drawDesktop()
      elseif y == maxH and x >= 30 and x <= 37 then
        currentApp = "MODEL3D"
        isStartMenuOpen = false
        drawDesktop()
      elseif y == maxH and x >= 40 and x <= 48 then
        currentApp = "SECRETS"
        isStartMenuOpen = false
        drawDesktop()

      -- MENU INICIAR
      elseif isStartMenuOpen and x >= 2 and x <= 30 then
        if y == maxH - 18 then currentApp = "FILES" currentPath = "/" isStartMenuOpen = false drawDesktop()
        elseif y == maxH - 16 then currentApp = "CMD" isStartMenuOpen = false drawDesktop()
        elseif y == maxH - 14 then currentApp = "WEB" isStartMenuOpen = false drawDesktop()
        elseif y == maxH - 12 then currentApp = "MODEL3D" isStartMenuOpen = false drawDesktop()
        elseif y == maxH - 10 then currentApp = "SECRETS" isStartMenuOpen = false drawDesktop()
        elseif y == maxH - 8 then isStartMenuOpen = false wipeOpenOSAndInstall()
        elseif y == maxH - 6 then currentApp = "TELEMETRY" isStartMenuOpen = false drawDesktop()
        elseif y == maxH - 4 then showOfficialBootScreen("Reiniciando...") computer.shutdown(true)
        elseif y == maxH - 2 then showOfficialBootScreen("Desligando...") computer.shutdown(false) end

      -- FECHAR APPS
      elseif currentApp and y == 2 and x >= maxW - 7 and x <= maxW - 3 then
        currentApp = nil
        drawDesktop()

      -- ARQUIVOS (FILES)
      elseif currentApp == "FILES" then
        if y == 3 and x >= 68 and x <= 73 then -- Botao Voltar [<-]
          if currentPath ~= "/" then
            currentPath = string.match(currentPath, "^(.*)/[^/]+$") or "/"
            if currentPath == "" then currentPath = "/" end
            drawDesktop()
          end
        elseif y >= 5 and y < 5 + #fileListCache then
          local idx = y - 4
          local item = fileListCache[idx]
          if item then
            local fullPath = currentPath == "/" and ("/" .. item) or (currentPath .. "/" .. item)
            if filesystem.isDirectory(fullPath) then
              currentPath = fullPath
              drawDesktop()
            else
              local f = filesystem.open(fullPath, "r")
              if f then
                editFileContent = f:read(8192) or ""
                f:close()
                editFilePath = fullPath
                currentApp = "EDITOR"
                drawDesktop()
              end
            end
          end
        end

      -- NAVEGADOR WEB (WEB) COM INTERNET CORRIGIDA
      elseif currentApp == "WEB" then
        if y == 3 and x >= 68 and x <= 73 then -- Botao IR
          webContent = "Baixando da rede..."
          drawDesktop()
          if component.isAvailable("internet") then
            local internet = require("internet")
            local responseData = ""
            for chunk in internet.request(webUrlInput) do
              responseData = responseData .. chunk
              if #responseData > 1500 then break end
            end
            if #responseData > 0 then
              webContent = string.sub(responseData, 1, 1500)
            else
              webContent = "Erro: Sem conteudo ou site offline."
            end
          else
            webContent = "Erro: Placa de Internet necessaria."
          end
          drawDesktop()
        elseif y == 3 and x >= 12 and x <= 66 then -- Digitar na URL
          webUrlInput = ""
          webContent = ">> MODO DE DIGITACAO <<\nDigite a URL usando seu teclado e aperte ENTER."
          drawDesktop()
          while true do
            local ev, _, char, code = event.pull()
            if ev == "key_down" then
              if code == 13 then break -- Enter
              elseif code == 8 and #webUrlInput > 0 then 
                webUrlInput = string.sub(webUrlInput, 1, -2) 
                drawDesktop()
              elseif char >= 32 and char <= 126 and #webUrlInput < 50 then
                webUrlInput = webUrlInput .. string.char(char)
                drawDesktop()
              end
            end
          end
        end

      -- IMPRESSORA 3D (MODEL3D)
      elseif currentApp == "MODEL3D" then
        if y >= 8 and y <= 15 then -- Grade Clicável
          local r = y - 7
          if x >= 11 and x <= 34 then
            local c = math.floor((x - 8) / 3)
            if c >= 1 and c <= 8 then
              modelGrid[r][c] = (modelGrid[r][c] == 1) and 0 or 1
              drawDesktop()
            end
          end
        elseif x >= 38 and x <= 53 then -- Botoes Laterais
          if y == 10 then -- Salvar
            local f = filesystem.open("/" .. modelName, "w")
            if f then f:write("MODELO3D_SALVO") f:close() end
            computer.beep(1200, 0.1)
          elseif y == 13 then -- Imprimir
            computer.beep(600, 0.2)
            computer.beep(800, 0.2)
            computer.beep(1000, 0.4)
          elseif y == 16 then -- Limpar
            for gridR = 1, 8 do for gridC = 1, 8 do modelGrid[gridR][gridC] = 0 end end
            drawDesktop()
          end
        end

      -- SEGREDOS E SYNTH
      elseif currentApp == "SECRETS" and x >= 8 and x <= 42 then
        if y == 6 then runMatrixEffect() drawDesktop()
        elseif y == 9 then runMeltdownAlarm() drawDesktop()
        elseif y == 12 then currentApp = "TELEMETRY" drawDesktop()
        elseif y == 15 then runSnakeGame() drawDesktop()
        elseif y == 18 then currentApp = "SYNTH" drawDesktop() end
      elseif currentApp == "SYNTH" and y >= 8 and y <= 12 then
        for i, n in ipairs(notes) do
          local bx = 8 + (i - 1) * 8
          if x >= bx and x <= bx + 5 then computer.beep(n.freq, 0.15) break end
        end
      end

    end
  end
end
