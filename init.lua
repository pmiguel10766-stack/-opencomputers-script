-- ===================================================
--   NITRO OS v6.5 - NATIVE KERNEL EDITION
--   Sistema Operacional Independente para OpenComputers
-- ===================================================

-- 1. GLOBALS NATIVOS DA BIOS
local comp_list = component.list
local comp_proxy = component.proxy

if not comp_list("gpu")() then return end

-- 2. HARDWARE BINDING (GPU e BOOT HDD)
local gpuAddress = comp_list("gpu")()
local gpu = comp_proxy(gpuAddress)
local screenAddress = comp_list("screen")()
if screenAddress then gpu.bind(screenAddress) end

local hddAddress = computer.getBootAddress()
local hdd = comp_proxy(hddAddress)

-- 3. APIs NATIVAS DO NITRO OS
local function sleep(timeout)
  local deadline = computer.uptime() + (timeout or 0)
  repeat
    computer.pullSignal(deadline - computer.uptime())
  until computer.uptime() >= deadline
end

local event = {
  pull = function(timeout)
    return computer.pullSignal(timeout)
  end
}

local filesystem = {
  exists = function(path) return hdd.exists(path) end,
  isDirectory = function(path) return hdd.isDirectory(path) end,
  makeDirectory = function(path) return hdd.makeDirectory(path) end,
  remove = function(path) return hdd.remove(path) end,
  rename = function(from, to) return hdd.rename(from, to) end,
  size = function(path) return hdd.size(path) end,
  list = function(path)
    local res = hdd.list(path)
    if type(res) == "table" then
      local i = 0
      return function() i = i + 1; return res[i] end
    elseif type(res) == "function" then
      return res
    else
      return function() return nil end
    end
  end,
  open = function(path, mode)
    local handle, err = hdd.open(path, mode)
    if not handle then return nil, err end
    return {
      readAll = function(self)
        local data = ""
        while true do
          local chunk = hdd.read(handle, 4096)
          if not chunk or #chunk == 0 then break end
          data = data .. chunk
        end
        return data
      end,
      write = function(self, data) return hdd.write(handle, data) end,
      close = function(self) return hdd.close(handle) end
    }
  end
}

local internet = {
  request = function(url)
    local inetAddr = comp_list("internet")()
    if not inetAddr then return nil, "Sem placa" end
    local inet = comp_proxy(inetAddr)
    return inet.request(url)
  end
}

-- REQUIRE CUSTOMIZADO
local _loaded = {}
local function custom_require(module)
  if _loaded[module] then return _loaded[module] end
  local paths = {"/lib/"..module..".lua", "/usr/lib/"..module..".lua", "/"..module..".lua"}
  for _, p in ipairs(paths) do
    if filesystem.exists(p) then
      local f = filesystem.open(p, "r")
      if f then
        local content = f:readAll()
        f:close()
        local compiled, err = load(content, "=" .. p, "t", _ENV or getfenv())
        if compiled then
          _loaded[module] = compiled() or true
          return _loaded[module]
        end
      end
    end
  end
  return nil
end

-- 4. VARIÁVEIS DE SISTEMA
local isInstalled = filesystem.exists("/.nitro_installed")
local installStep = 2
local selectedLang = "PT-BR"
local userName = "Admin"
local rawUpdateUrl = "https://raw.githubusercontent.com/pmiguel10766-stack/Atualizar_Nitro_OS/main/init.lua"

-- Dependências Nativas Extras (Preencha para baixar libs automaticamente)
local DEPS = {
  -- {"/lib/minhalib.lua", "https://raw.githubusercontent.com/..."}
}

if isInstalled then
  local file = filesystem.open("/.nitro_installed", "r")
  if file then
    local content = file:readAll()
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
local COLOR_ACCENT   = 0x00E676
local COLOR_TEXT     = 0xFFFFFF
local COLOR_SUBTEXT  = 0x6E6E7E
local COLOR_MENU_BG  = 0x15151C
local COLOR_RED      = 0xB71C1C
local COLOR_C_STRIPE = 0x22222E

local isStartMenuOpen = false
local currentApp = nil
local webUrlInput = "https://raw.githubusercontent.com/"
local webContent = "Digite uma URL HTTP/HTTPS para navegar."
local currentPath = "/"
local fileListCache = {}
local editFilePath = ""
local editFileContent = ""

local modelName = "modelo1.3d"
local modelGrid = {}
for r = 1, 8 do modelGrid[r] = {}; for c = 1, 8 do modelGrid[r][c] = 0 end end

local cmdInput = ""
local cmdHistory = {
  "Nitro OS v6.5 [Kernel Nativo Ativo]",
  "Digite 'help' para listar comandos.",
  ""
}

-- 5. FUNÇÕES DE UI / BOOT
local function drawCOLogo(cx, cy)
  gpu.setBackground(COLOR_BG)
  gpu.setForeground(COLOR_C_STRIPE)
  gpu.set(cx - 15, cy - 3, "------------------------")
  gpu.set(cx - 15, cy - 2, "|                      |")
  gpu.set(cx - 15, cy - 1, "|  ||||||||||||||||||  |")
  for i = 0, 4 do gpu.set(cx - 15, cy + i, "|  ||") end
  gpu.set(cx - 15, cy + 5, "|  ||||||||||||||||||  |")
  gpu.set(cx - 15, cy + 6, "|                      |")
  gpu.set(cx - 15, cy + 7, "------------------------")
  gpu.setBackground(COLOR_RED)
  gpu.setForeground(COLOR_TEXT)
  gpu.fill(cx + 1, cy, 9, 5, " ")
  gpu.set(cx + 3, cy + 1, ">  <")
  gpu.set(cx + 3, cy + 3, "\\__/")
end

local function showOfficialBootScreen(statusMsg, pct)
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

  if pct then
    local filled = math.floor((barWidth * pct) / 100)
    if filled > 0 then
      gpu.setBackground(COLOR_ACCENT)
      gpu.fill(barX, barY, filled, 1, " ")
    end
    gpu.setBackground(COLOR_BG)
    gpu.setForeground(COLOR_ACCENT)
    gpu.set(barX + barWidth + 2, barY, string.format("%3d%%", pct))
  else
    -- Animacao padrao
    for p = 0, 100, 20 do
      local filled = math.floor((barWidth * p) / 100)
      gpu.setBackground(COLOR_ACCENT)
      gpu.fill(barX, barY, filled > 0 and filled or 1, 1, " ")
      gpu.setBackground(COLOR_BG)
      gpu.setForeground(COLOR_ACCENT)
      gpu.set(barX + barWidth + 2, barY, string.format("%3d%%", p))
      sleep(0.05)
    end
  end
end

-- 6. ATUALIZADOR SEGURO EM 6 ETAPAS
local function runSecureUpdater()
  showOfficialBootScreen("1/6 Verificando Hardware...", 10)
  if not comp_list("internet")() then
    showOfficialBootScreen("ERRO: Placa de Internet não detectada!", 0)
    sleep(2) return
  end
  if hdd.isReadOnly() then
    showOfficialBootScreen("ERRO: O HD é somente leitura!", 0)
    sleep(2) return
  end

  showOfficialBootScreen("2/6 Verificando Dependências...", 25)
  for _, dep in ipairs(DEPS) do
    local path, url = dep[1], dep[2]
    if not filesystem.exists(path) then
      local req = internet.request(url)
      if req then
        local data = ""
        while true do
          local chunk = req.read()
          if chunk then data = data .. chunk else break end
        end
        req.close()
        local f = filesystem.open(path, "w")
        if f then f:write(data) f:close() end
      end
    end
  end

  showOfficialBootScreen("3/6 Conectando ao Servidor...", 40)
  local req = internet.request(rawUpdateUrl)
  if not req then
    showOfficialBootScreen("ERRO: Falha ao conectar no GitHub", 0)
    sleep(2) return
  end

  local downloadedContent = ""
  while true do
    local chunk = req.read()
    if chunk then
      downloadedContent = downloadedContent .. chunk
      showOfficialBootScreen("Baixando: " .. math.floor(#downloadedContent / 1024) .. " KB", 60)
    else
      break
    end
  end
  req.close()

  showOfficialBootScreen("4/6 Validando Código...", 75)
  if #downloadedContent == 0 or string.find(downloadedContent, "404: Not Found") then
    showOfficialBootScreen("ERRO: Arquivo vazio ou 404", 0)
    sleep(3) return
  end
  local compiled, err = load(downloadedContent)
  if not compiled then
    showOfficialBootScreen("ERRO DE SINTAXE: " .. string.sub(tostring(err), 1, 30), 0)
    sleep(4) return
  end

  showOfficialBootScreen("5/6 Gravando Sistema...", 90)
  local f = filesystem.open("/init.lua.new", "w")
  if f then
    f:write(downloadedContent)
    f:close()
    if filesystem.exists("/init.lua.bak") then filesystem.remove("/init.lua.bak") end
    filesystem.rename("/init.lua", "/init.lua.bak")
    local success = filesystem.rename("/init.lua.new", "/init.lua")
    if not success then
      filesystem.rename("/init.lua.bak", "/init.lua")
      showOfficialBootScreen("ERRO FATAL: Restauração do Backup falhou!", 0)
      sleep(3) return
    end
    
    local marker = filesystem.open("/.nitro_installed", "w")
    if marker then
      marker:write("installed=true\nlang=" .. selectedLang .. "\nuser=" .. userName .. "\nurl=" .. rawUpdateUrl)
      marker:close()
    end
  else
    showOfficialBootScreen("ERRO: Falha ao escrever /init.lua.new", 0)
    sleep(3) return
  end

  showOfficialBootScreen("6/6 Sistema Atualizado! Reiniciando...", 100)
  sleep(1.5)
  computer.shutdown(true)
end

-- 7. PROCESSADOR DE COMANDOS
local function resolvePath(path)
  if not path or path == "" then return currentPath end
  if string.sub(path, 1, 1) == "/" then return path end
  return currentPath == "/" and ("/" .. path) or (currentPath .. "/" .. path)
end

local function processCMDCommand(rawCmd)
  local cmd = string.match(rawCmd, "^%s*(.-)%s*$")
  if cmd == "" then return end
  table.insert(cmdHistory, "> " .. cmd)
  local args = {}
  for word in string.gmatch(cmd, "%S+") do table.insert(args, word) end
  local action = string.lower(args[1] or "")

  if action == "help" then
    table.insert(cmdHistory, "Comandos: ls/dir, cd, pwd, mkdir, rm, cat, wget, update, clear, reboot")
  elseif action == "clear" or action == "cls" then
    cmdHistory = {}
  elseif action == "ls" or action == "dir" then
    if filesystem.exists(currentPath) then
      for item in filesystem.list(currentPath) do
        local fp = currentPath == "/" and ("/" .. item) or (currentPath .. "/" .. item)
        local tag = filesystem.isDirectory(fp) and "<DIR>" or ""
        table.insert(cmdHistory, string.format("  %-25s %s", item, tag))
      end
    end
  elseif action == "cd" then
    local target = args[2]
    if not target or target == "" then
      table.insert(cmdHistory, currentPath)
    elseif target == ".." then
      if currentPath ~= "/" then
        currentPath = string.match(currentPath, "^(.*)/[^/]+$") or "/"
        if currentPath == "" then currentPath = "/" end
      end
    else
      local newPath = resolvePath(target)
      if filesystem.exists(newPath) and filesystem.isDirectory(newPath) then
        currentPath = newPath
      else
        table.insert(cmdHistory, "Erro: Diretorio nao encontrado.")
      end
    end
  elseif action == "cat" then
    local path = resolvePath(args[2])
    if filesystem.exists(path) and not filesystem.isDirectory(path) then
      local f = filesystem.open(path, "r")
      if f then
        local data = string.sub(f:readAll(), 1, 1000)
        f:close()
        for line in string.gmatch(data, "[^\r\n]+") do table.insert(cmdHistory, line) end
      end
    end
  elseif action == "wget" then
    if not comp_list("internet")() then table.insert(cmdHistory, "Erro: Sem internet."); return end
    local url, out = args[2], args[3]
    if url and out then
      table.insert(cmdHistory, "Baixando...")
      local req = internet.request(url)
      if req then
        local data = ""
        while true do local c = req.read(); if c then data = data..c else break end end
        req.close()
        local f = filesystem.open(resolvePath(out), "w")
        if f then f:write(data) f:close() table.insert(cmdHistory, "Concluido.") end
      end
    end
  elseif action == "update" then
    runSecureUpdater()
  elseif action == "reboot" then
    computer.shutdown(true)
  else
    table.insert(cmdHistory, "Comando '" .. action .. "' nao reconhecido.")
  end

  while #cmdHistory > 14 do table.remove(cmdHistory, 1) end
end

-- 8. DESENHO DOS APPS
local function drawCMDApp()
  gpu.setBackground(COLOR_CARD)
  gpu.fill(4, 2, maxW - 8, maxH - 4, " ")
  gpu.setBackground(0x000000)
  gpu.setForeground(COLOR_ACCENT)
  gpu.fill(4, 2, maxW - 8, 1, " ")
  gpu.set(6, 2, "PROMPT DE COMANDO (SHELL) - NATIVO")
  gpu.fill(6, 4, maxW - 12, maxH - 7, " ")
  local startY = 5
  for i, line in ipairs(cmdHistory) do
    if startY > maxH - 5 then break end
    gpu.set(8, startY, string.sub(line, 1, maxW - 16))
    startY = startY + 1
  end
  gpu.setForeground(COLOR_TEXT)
  local pStr = userName .. "@nitro:" .. currentPath .. "# "
  gpu.set(8, maxH - 4, pStr .. string.sub(cmdInput, 1, maxW - 16 - #pStr) .. "_")
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

-- (Outros Apps: Files, Editor, 3D, Segredos)
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
  gpu.set(4, maxH - 16, "2. Prompt CMD Nativo")
  gpu.set(4, maxH - 14, "3. Navegador Web")
  gpu.set(4, maxH - 12, "4. Impressora 3D")
  gpu.set(4, maxH - 10, "5. Segredos & Extras")
  gpu.set(4, maxH - 8,  "6. Atualizar Sistema (OS)")
  gpu.set(4, maxH - 4,  "7. Reiniciar Computador")
  gpu.set(4, maxH - 2,  "8. Desligar")
end

local function drawDesktop()
  gpu.setBackground(COLOR_BG)
  gpu.fill(1, 1, maxW, maxH, " ")
  drawCOLogo(math.floor(maxW / 2) - 2, 6)

  if currentApp == "CMD" then drawCMDApp()
  elseif currentApp == "WEB" then drawWebApp()
  -- (Adicione chamadas de drawFilesApp, etc, se desejar os outros apps visuais)
  end

  gpu.setBackground(COLOR_CARD)
  gpu.fill(1, maxH, maxW, 1, " ")
  gpu.setBackground(isStartMenuOpen and 0x2A2A38 or COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.set(2, maxH, " Menu ")
  gpu.setBackground(COLOR_CARD)
  gpu.setForeground(COLOR_TEXT)
  -- Hitboxes perfeitas: 10-17, 21-23, 27-29, 33-38, 42-49
  gpu.set(10, maxH, "Arquivos | CMD | Web | App 3D | Segredos")
  
  if isStartMenuOpen then drawStartMenu() end
end

-- 9. KERNEL PANIC E LOOP PRINCIPAL
local function mainLoop()
  if not isInstalled then
    showOfficialBootScreen("Instalando pela primeira vez...", 50)
    runSecureUpdater()
  else
    showOfficialBootScreen("Iniciando Nitro OS v6.5...")
    drawDesktop()
  end

  while true do
    local ev, arg1, arg2, arg3, arg4 = event.pull(0.1)

    if ev == "key_down" then
      local char = arg2
      local code = arg3

      if currentApp == "CMD" then
        if code == 28 or char == 13 then -- ENTER
          processCMDCommand(cmdInput)
          cmdInput = ""
          drawDesktop()
        elseif code == 14 or char == 8 then -- BACKSPACE
          if #cmdInput > 0 then cmdInput = string.sub(cmdInput, 1, -2) drawDesktop() end
        elseif char >= 32 and char <= 126 and #cmdInput < 50 then
          cmdInput = cmdInput .. string.char(char)
          drawDesktop()
        end
      end

    elseif ev == "touch" then
      local x, y = arg2, arg3

      -- HITBOXES CORRIGIDAS DA TASKBAR
      if y == maxH then
        if x >= 2 and x <= 8 then isStartMenuOpen = not isStartMenuOpen drawDesktop()
        elseif x >= 10 and x <= 17 then currentApp = "FILES" isStartMenuOpen = false drawDesktop()
        elseif x >= 21 and x <= 23 then currentApp = "CMD" isStartMenuOpen = false drawDesktop()
        elseif x >= 27 and x <= 29 then currentApp = "WEB" isStartMenuOpen = false drawDesktop()
        elseif x >= 33 and x <= 38 then currentApp = "MODEL3D" isStartMenuOpen = false drawDesktop()
        elseif x >= 42 and x <= 49 then currentApp = "SECRETS" isStartMenuOpen = false drawDesktop()
        end
      
      -- MENU INICIAR
      elseif isStartMenuOpen and x >= 2 and x <= 30 then
        if y == maxH - 18 then currentApp = "FILES" isStartMenuOpen = false drawDesktop()
        elseif y == maxH - 16 then currentApp = "CMD" isStartMenuOpen = false drawDesktop()
        elseif y == maxH - 14 then currentApp = "WEB" isStartMenuOpen = false drawDesktop()
        elseif y == maxH - 8 then isStartMenuOpen = false runSecureUpdater()
        elseif y == maxH - 4 then computer.shutdown(true)
        elseif y == maxH - 2 then computer.shutdown(false) end

      -- FECHAR APPS
      elseif currentApp and y == 2 and x >= maxW - 7 and x <= maxW - 3 then
        currentApp = nil drawDesktop()

      -- CONTROLES DO NAVEGADOR
      elseif currentApp == "WEB" then
        if y == 3 and x >= 68 and x <= 73 then
          webContent = "Baixando da rede..." drawDesktop()
          local req = internet.request(webUrlInput)
          if req then
            local data = ""
            while true do
              local c = req.read()
              if c then data = data..c if #data > 1500 then break end else break end
            end
            req.close()
            webContent = #data > 0 and string.sub(data, 1, 1500) or "Erro/404"
          else
            webContent = "Erro de conexão."
          end
          drawDesktop()
        elseif y == 3 and x >= 12 and x <= 66 then
          webUrlInput = ""
          webContent = ">> MODO DE DIGITACAO <<\nDigite a URL usando o teclado e aperte ENTER."
          drawDesktop()
          while true do
            local tev, _, tc, tk = event.pull()
            if tev == "key_down" then
              if tk == 28 or tc == 13 then break
              elseif tk == 14 or tc == 8 then 
                if #webUrlInput > 0 then webUrlInput = string.sub(webUrlInput, 1, -2) drawDesktop() end
              elseif tc >= 32 and tc <= 126 and #webUrlInput < 50 then
                webUrlInput = webUrlInput .. string.char(tc) drawDesktop()
              end
            end
          end
        end
      end
    end
  end
end

-- INICIA O SISTEMA PROTEGIDO POR KERNEL PANIC
local ok, err = pcall(mainLoop)
if not ok then
  gpu.setBackground(0x0000AA)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, maxW, maxH, " ")
  gpu.set(3, 3, "NITRO OS - FATAL KERNEL ERROR (BSOD)")
  gpu.set(3, 5, "Uma excecao nao tratada causou uma falha geral no sistema.")
  gpu.set(3, 7, "Erro: " .. tostring(err))
  gpu.set(3, maxH - 2, "Pressione qualquer tecla para reiniciar o computador...")
  while true do
    local e = computer.pullSignal()
    if e == "key_down" then computer.shutdown(true) end
  end
end
