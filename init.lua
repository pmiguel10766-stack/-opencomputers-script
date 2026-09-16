-- ===================================================
--    NITRO OS v7.0 - GUI AVANÇADA & ÍCONES DE DESKTOP
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

-- Cores do Sistema (Tema Moderno Dark/Nitro)
local COLOR_BG       = 0x12121A
local COLOR_CARD     = 0x1E1E28
local COLOR_ACCENT   = 0x00E676  -- Verde Nitro
local COLOR_TEXT     = 0xFFFFFF
local COLOR_SUBTEXT  = 0x8E8E9E
local COLOR_MENU_BG  = 0x181822
local COLOR_RED      = 0xCF6679
local COLOR_C_STRIPE = 0x2A2A38
local COLOR_SHADOW   = 0x0A0A0E

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
printStatusMsg = "Pronto para projetar."

-- ===================================================
-- LOGO "CO" MINIMALISTA
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

  local cx, cy = math.floor(maxW / 2) - 2, 5
  drawCOLogo(cx, cy)

  local barX, barY, barWidth = cx - 18, cy + 10, 40

  gpu.setBackground(COLOR_BG)
  gpu.setForeground(COLOR_SUBTEXT)
  gpu.set(barX, barY - 1, string.format("%-36s", statusMsg or "Carregando..."))

  gpu.setBackground(0x0A0A0E)
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

-- ===================================================
-- INSTALAÇÃO / WIPE DO SISTEMA
-- ===================================================
local function wipeOpenOSAndInstall()
  showOfficialBootScreen("Removendo arquivos antigos...")
  
  if filesystem.exists("/bin") then filesystem.remove("/bin") end
  if filesystem.exists("/lib") then filesystem.remove("/lib") end
  if filesystem.exists("/boot") then filesystem.remove("/boot") end

  showOfficialBootScreen("Baixando Nitro OS v7.0 do GitHub...")
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

  showOfficialBootScreen("Gravando sistema operacional...")
  local file = filesystem.open("/init.lua", "w")
  if #downloadedContent > 0 then
    file:write(downloadedContent)
  end
  file:close()

  local marker = filesystem.open("/.nitro_installed", "w")
  marker:write("installed=true\nlang=" .. selectedLang)
  marker:close()

  showOfficialBootScreen("Reiniciando computador...")
  computer.shutdown(true)
end

-- ===================================================
-- APLICATIVOS (MODO JANELA GUI)
-- ===================================================
local function drawFilesApp()
  gpu.setBackground(COLOR_SHADOW)
  gpu.fill(5, 3, maxW - 8, maxH - 5, " ")
  gpu.setBackground(COLOR_CARD)
  gpu.fill(4, 2, maxW - 8, maxH - 5, " ")

  gpu.setBackground(0x181822)
  gpu.setForeground(COLOR_ACCENT)
  gpu.set(6, 3, " [ ARQUIVOS ] ")
  gpu.setForeground(COLOR_TEXT)
  gpu.set(20, 3, "DIR: " .. string.sub(currentPath, 1, 40))

  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.set(68, 3, " [<-] ")

  gpu.setBackground(0x15151C)
  gpu.fill(6, 5, maxW - 12, maxH - 9, " ")

  fileListCache = {}
  local lineY = 5
  if filesystem.exists(currentPath) then
    for item in filesystem.list(currentPath) do
      if lineY > maxH - 6 then break end
      table.insert(fileListCache, item)
      
      local fullPath = currentPath == "/" and ("/" .. item) or (currentPath .. "/" .. item)
      local isDir = filesystem.isDirectory(fullPath)
      local sizeStr = isDir and "<PASTA>" or string.format("%d B", filesystem.size(fullPath) or 0)

      gpu.setForeground(isDir and COLOR_ACCENT or COLOR_TEXT)
      gpu.set(8, lineY, string.format(" > %-32s %15s", item, sizeStr))
      lineY = lineY + 1
    end
  end

  gpu.setBackground(COLOR_RED)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(maxW - 7, 2, " X ")
end

local function loadFileToEditor(path)
  editFilePath = path
  editFileContent = ""
  if filesystem.exists(path) and not filesystem.isDirectory(path) then
    local file = filesystem.open(path, "r")
    if file then
      while true do
        local line = file:read("*l")
        if not line then break end
        editFileContent = editFileContent .. line .. "\n"
      end
      file:close()
    end
  else
    editFileContent = "-- Novo Arquivo de Texto\n"
  end
end

local function drawEditorApp()
  gpu.setBackground(COLOR_SHADOW)
  gpu.fill(5, 3, maxW - 8, maxH - 5, " ")
  gpu.setBackground(COLOR_CARD)
  gpu.fill(4, 2, maxW - 8, maxH - 5, " ")

  gpu.setBackground(0x181822)
  gpu.setForeground(COLOR_ACCENT)
  gpu.set(6, 3, " [ EDITOR DE TEXTO ] ")
  gpu.setForeground(COLOR_TEXT)
  gpu.set(25, 3, string.sub(editFilePath, 1, 40))

  gpu.setBackground(0x15151C)
  gpu.fill(6, 5, maxW - 12, maxH - 9, " ")
  gpu.setForeground(COLOR_TEXT)

  local lineY = 6
  for line in string.gmatch(editFileContent .. "\n", "([^\r\n]*)\r?\n") do
    if lineY > maxH - 6 then break end
    gpu.set(8, lineY, string.sub(line, 1, maxW - 16))
    lineY = lineY + 1
  end

  gpu.setBackground(COLOR_RED)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(maxW - 7, 2, " X ")
end

local function save3DModel()
  local fullPath = "/" .. modelName
  local file = filesystem.open(fullPath, "w")
  if file then
    file:write("-- NitroOS 3D Model\n")
    for r = 1, 8 do
      for c = 1, 8 do
        if modelGrid[r][c] == 1 then
          file:write(string.format("voxel(%d,%d,1)\n", r, c))
        end
      end
    end
    file:close()
    printStatusMsg = "Salvo: " .. fullPath
  else
    printStatusMsg = "Erro ao salvar."
  end
end

local function print3DModelHardware()
  if not component.isAvailable("print3d") then
    printStatusMsg = "Erro: Impressora nao conectada!"
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
  printStatusMsg = success and "Impressao iniciada!" or ("Erro: " .. tostring(reason))
end

local function draw3DApp()
  gpu.setBackground(COLOR_SHADOW)
  gpu.fill(5, 3, maxW - 8, maxH - 5, " ")
  gpu.setBackground(COLOR_CARD)
  gpu.fill(4, 2, maxW - 8, maxH - 5, " ")

  gpu.setBackground(0x181822)
  gpu.setForeground(COLOR_ACCENT)
  gpu.set(6, 3, " [ IMPRESSORA 3D ] ")

  gpu.setBackground(0x15151C)
  gpu.fill(6, 5, maxW - 12, maxH - 9, " ")

  local startX, startY = 10, 7
  for r = 1, 8 do
    for c = 1, 8 do
      if modelGrid[r][c] == 1 then
        gpu.setBackground(COLOR_ACCENT)
        gpu.setForeground(0x000000)
        gpu.set(startX + (c * 3) - 2, startY + r, "   ")
      else
        gpu.setBackground(0x2A2A38)
        gpu.setForeground(COLOR_SUBTEXT)
        gpu.set(startX + (c * 3) - 2, startY + r, " . ")
      end
    end
  end

  gpu.setBackground(COLOR_CARD)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(38, 7, "Painel de Acoes:")
  
  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.set(38, 10, " Salvar Modelo  ")
  gpu.set(38, 13, " Imprimir Físico")
  gpu.set(38, 16, " Limpar Tela    ")

  gpu.setForeground(COLOR_SUBTEXT)
  gpu.set(6, maxH - 6, "Status: " .. printStatusMsg)

  gpu.setBackground(COLOR_RED)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(maxW - 7, 2, " X ")
end

local function fetchWebUrl(url)
  if not component.isAvailable("internet") then
    return "ERRO: Placa de Internet ausente."
  end
  local handle = component.internet.request(url)
  if not handle then return "ERRO: Falha na conexao." end
  local data = ""
  while true do
    local chunk = handle.read(math.huge)
    if not chunk then break end
    data = data .. chunk
    if #data > 2000 then break end
  end
  handle.close()
  return #data > 0 and data or "Pagina vazia."
end

local function drawWebApp()
  gpu.setBackground(COLOR_SHADOW)
  gpu.fill(5, 3, maxW - 8, maxH - 5, " ")
  gpu.setBackground(COLOR_CARD)
  gpu.fill(4, 2, maxW - 8, maxH - 5, " ")

  gpu.setBackground(0x181822)
  gpu.setForeground(COLOR_ACCENT)
  gpu.set(6, 3, " [ NAVEGADOR WEB ] ")
  gpu.setForeground(COLOR_TEXT)
  gpu.set(24, 3, string.sub(webUrlInput, 1, 42))

  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.set(68, 3, "  IR  ")

  gpu.setBackground(0x15151C)
  gpu.fill(6, 5, maxW - 12, maxH - 9, " ")
  gpu.setForeground(COLOR_TEXT)

  local lineY = 6
  for line in string.gmatch(webContent, "[^\r\n]+") do
    if lineY > maxH - 6 then break end
    gpu.set(8, lineY, string.sub(line, 1, maxW - 16))
    lineY = lineY + 1
  end

  gpu.setBackground(COLOR_RED)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(maxW - 7, 2, " X ")
end

-- ===================================================
-- MENU INICIAR & DESKTOP COM ÍCONES VISUAIS
-- ===================================================
local function drawStartMenu()
  gpu.setBackground(COLOR_MENU_BG)
  gpu.fill(2, maxH - 16, 28, 15, " ")

  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.fill(2, maxH - 16, 28, 1, " ")
  gpu.set(4, maxH - 16, "NITRO OS v7.0")

  gpu.setBackground(COLOR_MENU_BG)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(4, maxH - 14, "📂 Meus Arquivos")
  gpu.set(4, maxH - 12, "🌐 Navegador Web")
  gpu.set(4, maxH - 10, "🖨️ Impressora 3D")
  gpu.set(4, maxH - 8,  "🔄 Atualizar Sistema")
  gpu.set(4, maxH - 6,  "⚙️ Configurações")
  gpu.set(4, maxH - 4,  "♻️ Reiniciar")
  gpu.set(4, maxH - 2,  "🔌 Desligar")
end

local function drawDesktop()
  gpu.setBackground(COLOR_BG)
  gpu.fill(1, 1, maxW, maxH, " ")

  -- Renderiza ícones visuais interativos no Desktop
  local iconBg = 0x1A1A26
  
  -- Ícone 1: Arquivos
  gpu.setBackground(iconBg)
  gpu.fill(6, 4, 16, 4, " ")
  gpu.setForeground(COLOR_ACCENT)
  gpu.set(8, 5, "[📁]")
  gpu.setForeground(COLOR_TEXT)
  gpu.set(12, 5, "Arquivos")

  -- Ícone 2: Web
  gpu.setBackground(iconBg)
  gpu.fill(26, 4, 16, 4, " ")
  gpu.setForeground(COLOR_ACCENT)
  gpu.set(28, 5, "[🌐]")
  gpu.setForeground(COLOR_TEXT)
  gpu.set(32, 5, "Navegador")

  -- Ícone 3: Impressora 3D
  gpu.setBackground(iconBg)
  gpu.fill(46, 4, 16, 4, " ")
  gpu.setForeground(COLOR_ACCENT)
  gpu.set(48, 5, "[🖨️]")
  gpu.setForeground(COLOR_TEXT)
  gpu.set(52, 5, "App 3D")

  -- Renderiza aplicativos abertos em cima se houver
  if currentApp == "WEB" then
    drawWebApp()
  elseif currentApp == "FILES" then
    drawFilesApp()
  elseif currentApp == "EDITOR" then
    drawEditorApp()
  elseif currentApp == "MODEL3D" then
    draw3DApp()
  end

  -- Barra de Tarefas Inferior
  gpu.setBackground(COLOR_CARD)
  gpu.fill(1, maxH, maxW, 1, " ")

  gpu.setBackground(isStartMenuOpen and 0x2A2A38 or COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.set(2, maxH, " Menu ")

  gpu.setBackground(COLOR_CARD)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(12, maxH, "Arquivos  |  Web  |  App 3D  |  Atualizar")

  if isStartMenuOpen then
    drawStartMenu()
  end
end

-- ===================================================
-- WIZARD DE INSTALAÇÃO
-- ===================================================
local function drawWindowSetup(title, renderContent)
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
  drawWindowSetup("IDIOMA (2/3)", function(rx, ry)
    gpu.set(rx, ry,     "Selecione o idioma padrão:")

    gpu.setBackground(selectedLang == "PT-BR" and COLOR_ACCENT or 0x2A2A38)
    gpu.setForeground(selectedLang == "PT-BR" and 0x000000 or COLOR_TEXT)
    gpu.set(rx + 2, ry + 4, "  Português (Brasil)  ")

    gpu.setBackground(COLOR_ACCENT)
    gpu.setForeground(0x000000)
    gpu.set(rx + 42, ry + 10, "  Avançar ->  ")
  end)
end

local function showInstallStep()
  drawWindowSetup("INSTALAÇÃO (3/3)", function(rx, ry)
    gpu.set(rx, ry,     "Destino: HDD OpenComputers")
    gpu.set(rx, ry + 1, "Origem: GitHub Oficial Nitro OS")
    gpu.set(rx, ry + 3, "O OpenOS padrão será substituído.")

    gpu.setBackground(COLOR_ACCENT)
    gpu.setForeground(0x000000)
    gpu.set(rx + 2, ry + 7, "  Instalar Nitro OS  ")
  end)
end

-- ===================================================
-- LOOP PRINCIPAL DE EVENTOS
-- ===================================================
if not isInstalled then
  showOfficialBootScreen("Iniciando Setup v7.0...")
  showLanguageStep()
else
  showOfficialBootScreen("Iniciando Nitro OS v7.0...")
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
      -- Cliques na barra de tarefas inferior
      if y == maxH and x >= 2 and x <= 8 then
        isStartMenuOpen = not isStartMenuOpen
        drawDesktop()
      elseif y == maxH and x >= 12 and x <= 20 then
        currentApp = "FILES"
        currentPath = "/"
        isStartMenuOpen = false
        drawDesktop()
      elseif y == maxH and x >= 23 and x <= 26 then
        currentApp = "WEB"
        isStartMenuOpen = false
        drawDesktop()
      elseif y == maxH and x >= 29 and x <= 37 then
        currentApp = "MODEL3D"
        isStartMenuOpen = false
        drawDesktop()
      elseif y == maxH and x >= 40 and x <= 49 then
        isStartMenuOpen = false
        wipeOpenOSAndInstall()
      -- Cliques nos Ícones da Área de Trabalho (Desktop)
      elseif not currentApp and not isStartMenuOpen and y >= 4 and y <= 7 then
        if x >= 6 and x <= 21 then
          currentApp = "FILES"
          currentPath = "/"
          drawDesktop()
        elseif x >= 26 and x <= 41 then
          currentApp = "WEB"
          drawDesktop()
        elseif x >= 46 and x <= 61 then
          currentApp = "MODEL3D"
          drawDesktop()
        end
      -- Cliques no Menu Iniciar
      elseif isStartMenuOpen and x >= 2 and x <= 30 then
        if y == maxH - 14 then
          currentApp = "FILES"
          currentPath = "/"
          isStartMenuOpen = false
          drawDesktop()
        elseif y == maxH - 12 then
          currentApp = "WEB"
          isStartMenuOpen = false
          drawDesktop()
        elseif y == maxH - 10 then
          currentApp = "MODEL3D"
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
      -- Comportamentos dentro dos Aplicativos abertos
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
      elseif currentApp == "EDITOR" then
        if y == 2 and x >= maxW - 7 and x <= maxW - 3 then
          currentApp = "FILES"
          drawDesktop()
        end
      elseif currentApp == "MODEL3D" then
        if y == 2 and x >= maxW - 7 and x <= maxW - 3 then
          currentApp = nil
          drawDesktop()
        elseif x >= 10 and x <= 33 and y >= 8 and y <= 15 then
          local gridR = y - 7
          local gridC = math.floor((x - 10) / 3) + 1
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
