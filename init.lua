-- ===================================================
--    NITRO OS v5.4 - EXPLORADOR DE ARQUIVOS INCLUSO
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
-- EXPLORADOR DE ARQUIVOS (MEU COMPUTADOR)
-- ===================================================
local function drawFilesApp()
  gpu.setBackground(COLOR_CARD)
  gpu.fill(4, 2, maxW - 8, maxH - 4, " ")

  gpu.setBackground(0x121218)
  gpu.setForeground(COLOR_ACCENT)
  gpu.set(6, 3, "DIRETORIO:")
  gpu.setBackground(0x252530)
  gpu.setForeground(COLOR_TEXT)
  gpu.fill(17, 3, 50, 1, " ")
  gpu.set(18, 3, string.sub(currentPath, 1, 48))

  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.set(68, 3, " [<-] ")

  gpu.setBackground(0x101016)
  gpu.fill(6, 5, maxW - 12, maxH - 8, " ")

  local totalSpace = filesystem.spaceTotal() or 0
  local usedSpace = filesystem.spaceUsed() or 0
  local freeSpace = totalSpace - usedSpace

  gpu.setForeground(COLOR_SUBTEXT)
  gpu.set(8, 6, string.format("Disco Rigido (HDD): %d KB Livres / %d KB Total", math.floor(freeSpace/1024), math.floor(totalSpace/1024)))
  gpu.set(8, 7, "------------------------------------------------------------")

  local lineY = 8
  if filesystem.exists(currentPath) then
    for item in filesystem.list(currentPath) do
      if lineY > maxH - 5 then break end
      local isDir = filesystem.isDirectory(currentPath .. item)
      local fullItemPath = currentPath .. item
      local sizeStr = isDir and "<DIR>" or string.format("%d B", filesystem.size(fullItemPath) or 0)

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
  gpu.fill(2, maxH - 14, 28, 13, " ")

  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.fill(2, maxH - 14, 28, 1, " ")
  gpu.set(4, maxH - 14, "NITRO OS - MENU")

  gpu.setBackground(COLOR_MENU_BG)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(4, maxH - 12, "1. Meus Arquivos (HDD)")
  gpu.set(4, maxH - 10, "2. Navegador Web")
  gpu.set(4, maxH - 8,  "3. Atualizar Sistema")
  gpu.set(4, maxH - 6,  "4. Configuracoes")
  gpu.set(4, maxH - 4,  "5. Reiniciar Sistema")
  gpu.set(4, maxH - 2,  "6. Desligar Computador")
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
  end

  gpu.setBackground(COLOR_CARD)
  gpu.fill(1, maxH, maxW, 1, " ")

  gpu.setBackground(isStartMenuOpen and 0x2A2A38 or COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.set(2, maxH, " Menu ")

  gpu.setBackground(COLOR_CARD)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(12, maxH, "Arquivos  |  Web  |  Atualizar")

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
-- CICLO PRINCIPAL
-- ===================================================
if not isInstalled then
  showOfficialBootScreen("Iniciando Setup...")
  showLanguageStep()
else
  showOfficialBootScreen("Iniciando Nitro OS...")
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
      if y == maxH and x >= 2 and x <= 8 then
        isStartMenuOpen = not isStartMenuOpen
        drawDesktop()
      elseif y == maxH and x >= 12 and x <= 20 then
        currentApp = "FILES"
        isStartMenuOpen = false
        drawDesktop()
      elseif isStartMenuOpen and x >= 2 and x <= 30 then
        if y == maxH - 12 then
          currentApp = "FILES"
          isStartMenuOpen = false
          drawDesktop()
        elseif y == maxH - 10 then
          currentApp = "WEB"
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
      elseif currentApp == "FILES" then
        if y == 2 and x >= maxW - 7 and x <= maxW - 3 then
          currentApp = nil
          drawDesktop()
        elseif y == 3 and x >= 68 and x <= 74 then
          currentPath = "/"
          drawDesktop()
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
