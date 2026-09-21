-- ===================================================
--   NITRO OS v7.0 - WIZARD INSTALLER EDITION
--   Sistema Operacional Independente para OpenComputers
-- ===================================================

local comp_list = component.list
local comp_proxy = component.proxy

if not comp_list("gpu")() then return end

local gpuAddress = comp_list("gpu")()
local gpu = comp_proxy(gpuAddress)
local screenAddress = comp_list("screen")()
if screenAddress then gpu.bind(screenAddress) end

local hddAddress = computer.getBootAddress()
local hdd = comp_proxy(hddAddress)

-- APIs NATIVAS
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
          sleep(0.01)
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

-- CONFIGURAÇÕES DE RESOLUÇÃO E CORES
gpu.setResolution(80, 25)
local maxW, maxH = 80, 25

local COLOR_BG       = 0x101014
local COLOR_CARD     = 0x1B1B22
local COLOR_ACCENT   = 0x00E676  -- Verde Nitro
local COLOR_TEXT     = 0xFFFFFF
local COLOR_SUBTEXT  = 0x8E8E9E
local COLOR_BTN      = 0x2A2A38
local COLOR_RED      = 0xB71C1C

-- VARIÁVEIS DE SISTEMA E INSTALAÇÃO
local isInstalled = filesystem.exists("/.nitro_installed")
local installStep = 1
local setupStep = 1
local userName = ""
local userPass = ""
local selectedHDD = 1
local rawUpdateUrl = "https://raw.githubusercontent.com/pmiguel10766-stack/Atualizar_Nitro_OS/main/init.lua"

if isInstalled then
  local file = filesystem.open("/.nitro_installed", "r")
  if file then
    local content = file:readAll()
    file:close()
    for line in string.gmatch(content, "[^\r\n]+") do
      local k, v = string.match(line, "^(%w+)=(.*)$")
      if k == "user" and v then userName = v end
    end
  end
end

-- ===================================================
-- DESENHO DA JANELA BASE DO INSTALADOR
-- ===================================================
local function drawWindowBase(title)
  gpu.setBackground(COLOR_BG)
  gpu.fill(1, 1, maxW, maxH, " ")

  -- Moldura Central
  gpu.setBackground(COLOR_CARD)
  gpu.fill(8, 3, maxW - 16, maxH - 5, " ")

  -- Barra de Titulo
  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.fill(8, 3, maxW - 16, 1, " ")
  gpu.set(10, 3, "NITRO OS SETUP - " .. title)
end

local function drawButton(x, y, w, text, active)
  gpu.setBackground(active and COLOR_ACCENT or COLOR_BTN)
  gpu.setForeground(active and 0x000000 or COLOR_TEXT)
  gpu.fill(x, y, w, 1, " ")
  local px = x + math.floor((w - #text) / 2)
  gpu.set(px, y, text)
end

-- ===================================================
-- TELAS DE INSTALAÇÃO (1 A 4)
-- ===================================================

-- TELA 1: Preferencias de Idioma
local function drawInstallStep1()
  drawWindowBase("IDIOMA E PREFERENCIAS (1/4)")
  gpu.setBackground(COLOR_CARD)
  gpu.setForeground(COLOR_TEXT)

  gpu.set(12, 6, "Idioma de instalacao:           [ Portugues ]")
  gpu.set(12, 9, "Formato de hora e moeda:        [ Minecraft ]")
  gpu.setForeground(COLOR_SUBTEXT)
  gpu.set(12, 10, "(Nao e possivel trocar isto para garantir funcionamento)")

  gpu.setForeground(COLOR_TEXT)
  gpu.set(12, 13, "Teclado ou metodo de entrada:   [ Portugues ]")

  gpu.setForeground(COLOR_SUBTEXT)
  gpu.set(12, 16, "Insira seu idioma e outras preferencias e clique em 'Avancar'.")

  -- Botoes: Fechar e Avancar
  drawButton(12, 19, 12, "Fechar", false)
  drawButton(54, 19, 14, "Avancar ->", true)
end

-- TELA 2: Seleção de Unidade (HDD)
local function drawInstallStep2()
  drawWindowBase("LOCAL DE INSTALACAO (2/4)")
  gpu.setBackground(COLOR_CARD)
  gpu.setForeground(COLOR_TEXT)

  gpu.set(12, 5, "Onde deseja instalar o Nitro OS?")

  local totalSpc = math.floor((hdd.spaceTotal() or 1024) / 1024)
  local freeSpc = math.floor((hdd.spaceTotal() - hdd.spaceUsed()) / 1024)

  -- Opcoes de HDDs
  drawButton(12, 8, 56, string.format("1. HDD 1 (%d KB) -- %d KB livres %s", totalSpc, freeSpc, selectedHDD == 1 and "[SELECIONADO]" or ""), selectedHDD == 1)
  drawButton(12, 11, 56, "2. HDD 2 (Nao detectado) -- 0 KB livres", false)
  drawButton(12, 14, 56, "3. HDD 3 (Nao detectado) -- [Boot de Sistema]", false)

  drawButton(12, 19, 12, "<- Voltar", false)
  drawButton(54, 19, 14, "Avancar ->", true)
end

-- TELA 3: Baixando Sistema com Barra de Progresso
local function runInstallStep3()
  drawWindowBase("BAIXANDO NITRO OS (3/4)")
  gpu.setBackground(COLOR_CARD)
  gpu.setForeground(COLOR_TEXT)

  gpu.set(12, 7, "Baixando e instalando arquivos do Nitro OS...")
  gpu.setForeground(COLOR_RED)
  gpu.set(12, 9, "[ NAO DESLIGUE O PC ]")

  local barX, barY, barW = 12, 12, 56
  gpu.setBackground(0x08080A)
  gpu.fill(barX, barY, barW, 1, " ")

  local req = internet.request(rawUpdateUrl)
  local downloaded = ""
  
  if req then
    while true do
      local chunk = req.read(4096)
      if chunk then
        downloaded = downloaded .. chunk
        local pct = math.min(100, math.floor((#downloaded / 12000) * 100))
        
        local filled = math.floor((barW * pct) / 100)
        if filled > 0 then
          gpu.setBackground(COLOR_ACCENT)
          gpu.fill(barX, barY, filled, 1, " ")
        end
        gpu.setBackground(COLOR_CARD)
        gpu.setForeground(COLOR_ACCENT)
        gpu.set(barX, barY + 2, string.format("Baixando Nitro OS: [ %3d%% ]", pct))
        sleep(0.03)
      else
        break
      end
    end
    req.close()
  end

  -- Escreve o init.lua no disco
  if #downloaded > 0 then
    local f = filesystem.open("/init.lua", "w")
    if f then f:write(downloaded); f:close() end
  end
end

-- TELA 4: Reinício Automático
local function drawInstallStep4()
  drawWindowBase("INSTALACAO CONCLUIDA (4/4)")
  gpu.setBackground(COLOR_CARD)
  gpu.setForeground(COLOR_TEXT)

  gpu.set(12, 8, "O Nitro OS foi instalado com sucesso!")
  
  for sec = 10, 1, -1 do
    gpu.setBackground(COLOR_CARD)
    gpu.setForeground(COLOR_ACCENT)
    gpu.set(12, 11, string.format("O PC vai reiniciar em %2d segundos...", sec))
    
    drawButton(50, 18, 18, "Reiniciar Agora", true)
    
    local ev, _, x, y = event.pull(1)
    if ev == "touch" and y == 18 and x >= 50 and x <= 68 then
      break
    end
  end
  
  -- Marca etapa de instalacao e reinicia
  local f = filesystem.open("/.nitro_setup", "w")
  if f then f:write("setup=needed"); f:close() end
  computer.shutdown(true)
end

-- ===================================================
-- TELAS DE CONFIGURAÇÃO DE USUÁRIO (1 A 4)
-- ===================================================

-- TELA 1 CONFIG: Carregador
local function showSetupLoading()
  gpu.setBackground(COLOR_BG)
  gpu.fill(1, 1, maxW, maxH, " ")
  
  gpu.setForeground(COLOR_ACCENT)
  gpu.set(28, 10, "Configurando o Sistema...")

  local barX, barY, barW = 20, 12, 40
  gpu.setBackground(0x08080A)
  gpu.fill(barX, barY, barW, 1, " ")

  for p = 0, 100, 5 do
    local filled = math.floor((barW * p) / 100)
    if filled > 0 then
      gpu.setBackground(COLOR_ACCENT)
      gpu.fill(barX, barY, filled, 1, " ")
    end
    gpu.setBackground(COLOR_BG)
    gpu.setForeground(COLOR_TEXT)
    gpu.set(36, barY + 2, string.format("[ %3d%% ]", p))
    sleep(0.02)
  end
end

-- TELA 2 CONFIG: Nome e Senha
local function drawSetupUserStep2()
  drawWindowBase("CONFIGURACAO DE USUARIO (2/3)")
  gpu.setBackground(COLOR_CARD)
  gpu.setForeground(COLOR_TEXT)

  gpu.set(12, 6, "Digite o nome do Usuario:")
  gpu.setBackground(0x252530)
  gpu.fill(12, 8, 40, 1, " ")
  gpu.set(13, 8, userName .. "_")

  gpu.setBackground(COLOR_CARD)
  gpu.set(12, 11, "Digite a Senha (Opcional):")
  gpu.setBackground(0x252530)
  gpu.fill(12, 13, 40, 1, " ")
  gpu.set(13, 13, string.rep("*", #userPass))

  gpu.setForeground(COLOR_SUBTEXT)
  gpu.setBackground(COLOR_CARD)
  gpu.set(12, 15, "(Deixe em branco para um boot mais rapido sem senha)")

  drawButton(54, 19, 14, "Avancar ->", true)
end

-- TELA 3 CONFIG: Idioma e Teclado
local function drawSetupUserStep3()
  drawWindowBase("CONFIRMACAO DE TECLADO (3/3)")
  gpu.setBackground(COLOR_CARD)
  gpu.setForeground(COLOR_TEXT)

  gpu.set(12, 7, "Idioma do Sistema:            [ Portugues ]")
  gpu.set(12, 10, "Teclado ou metodo de entrada: [ Portugues ]")

  drawButton(12, 19, 12, "<- Voltar", false)
  drawButton(54, 19, 14, "Avancar ->", true)
end

-- ===================================================
-- ÁREA DE TRABALHO E BEM-VINDO
-- ===================================================

local function drawDesktopWelcome()
  -- Tela 1 Fundo de Trabalho: Bem-vindo
  gpu.setBackground(COLOR_BG)
  gpu.fill(1, 1, maxW, maxH, " ")

  gpu.setBackground(COLOR_CARD)
  gpu.fill(20, 8, 40, 8, " ")

  gpu.setForeground(COLOR_ACCENT)
  gpu.set(22, 10, "Usuario: " .. (userName ~= "" and userName or "Admin"))
  gpu.setForeground(COLOR_TEXT)
  gpu.set(22, 12, "Bem-vindo(a) ao Nitro OS!")

  sleep(2.5)

  -- Tela 2 Fundo de Trabalho: Desktop Principal
  gpu.setBackground(COLOR_BG)
  gpu.fill(1, 1, maxW, maxH, " ")

  -- Logo Central Nitro OS
  gpu.setForeground(COLOR_SUBTEXT)
  gpu.set(30, 8,  "--------------------")
  gpu.set(30, 9,  "|     NITRO OS     |")
  gpu.set(30, 10, "--------------------")

  -- Barra de Tarefas
  gpu.setBackground(COLOR_CARD)
  gpu.fill(1, maxH, maxW, 1, " ")

  gpu.setBackground(COLOR_ACCENT)
  gpu.setForeground(0x000000)
  gpu.set(2, maxH, " Menu ")

  gpu.setBackground(COLOR_CARD)
  gpu.setForeground(COLOR_TEXT)
  gpu.set(10, maxH, "Arquivos | CMD | Navegador Web | Configs")
end

-- ===================================================
-- CICLO E INTERAÇÕES PRINCIPAIS
-- ===================================================

local function startSetupUserLoop()
  showSetupLoading()
  setupStep = 2
  drawSetupUserStep2()

  while true do
    local ev, _, x, y, code = event.pull()

    if setupStep == 2 then
      if ev == "key_down" then
        local char = code
        if char == 13 or char == 28 then -- ENTER
          if #userName > 0 then
            setupStep = 3
            drawSetupUserStep3()
          end
        elseif char == 8 or char == 14 then -- BACKSPACE
          userName = string.sub(userName, 1, -2)
          drawSetupUserStep2()
        elseif char >= 32 and char <= 126 and #userName < 20 then
          userName = userName .. string.char(char)
          drawSetupUserStep2()
        end
      elseif ev == "touch" and y == 19 and x >= 54 and x <= 68 then
        if #userName > 0 then
          setupStep = 3
          drawSetupUserStep3()
        end
      end

    elseif setupStep == 3 then
      if ev == "touch" then
        if y == 19 and x >= 12 and x <= 24 then
          setupStep = 2
          drawSetupUserStep2()
        elseif y == 19 and x >= 54 and x <= 68 then
          -- Salva a configuracao final
          local f = filesystem.open("/.nitro_installed", "w")
          if f then
            f:write("installed=true\nuser=" .. userName)
            f:close()
          end
          if filesystem.exists("/.nitro_setup") then filesystem.remove("/.nitro_setup") end
          drawDesktopWelcome()
          break
        end
      end
    end
  end
end

-- GERENCIADOR DE BOOT PRINCIPAL
if not isInstalled then
  -- FLUXO DE INSTALAÇÃO INICIAL
  drawInstallStep1()

  while true do
    local ev, _, x, y = event.pull()
    if ev == "touch" then
      if installStep == 1 then
        if y == 19 and x >= 12 and x <= 24 then
          computer.shutdown(false) -- Fechar
        elseif y == 19 and x >= 54 and x <= 68 then
          installStep = 2
          drawInstallStep2()
        end
      elseif installStep == 2 then
        if y == 19 and x >= 12 and x <= 24 then
          installStep = 1
          drawInstallStep1()
        elseif y == 19 and x >= 54 and x <= 68 then
          installStep = 3
          runInstallStep3()
          installStep = 4
          drawInstallStep4()
          break
        end
      end
    end
  end

elseif filesystem.exists("/.nitro_setup") then
  -- FLUXO DE CONFIGURAÇÃO DE USUÁRIO APÓS REINICIAR
  startSetupUserLoop()

else
  -- BOOT DIRETO PARA O DESKTOP
  drawDesktopWelcome()
end
