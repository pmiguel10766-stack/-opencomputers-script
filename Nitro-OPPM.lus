-- ===================================================
--    NITRO OPPM - FLOPPY BOOTLOADER & PACKAGE MANAGER
-- ===================================================

local component = component
local computer = computer

if not component.isAvailable("gpu") then return end
local gpu = component.gpu
gpu.setResolution(80, 25)

-- Interface Visual do OPPM
gpu.setBackground(0x101014)
gpu.setForeground(0x00E676)
gpu.fill(1, 1, 80, 25, " ")

gpu.set(25, 10, "[ NITRO OPPM ] Inicializando disquete...")

-- Função para descarregar o script via HTTP/HTTPS da internet
local function downloadRemoteScript(url)
  if not component.isAvailable("internet") then
    return nil, "Placa de rede/Internet indisponivel"
  end
  
  local internet = component.internet
  local handle, err = internet.request(url)
  if not handle then return nil, err end
  
  local content = ""
  while true do
    local chunk, reason = handle.read(math.huge)
    if not chunk then break end
    content = content .. chunk
  end
  handle.close()
  return content
end

-- Passo 1: Download do pacote do Nitro OS do GitHub
gpu.set(25, 12, "[1/2] A descarregar pacotes do GitHub...")
local githubUrl = "https://raw.githubusercontent.com/pmiguel10766-stack/-opencomputers-script/refs/heads/main/init.lua"
local remoteCode, downloadErr = downloadRemoteScript(githubUrl)

if not remoteCode or #remoteCode == 0 then
  gpu.setBackground(0xB71C1C)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(15, 8, 52, 8, " ")
  gpu.set(17, 10, "ERRO NO DOWNLOAD DO NITRO OPPM:")
  gpu.set(17, 12, tostring(downloadErr or "Conteudo vazio"):sub(1, 45))
  gpu.set(17, 14, "Pressione qualquer tecla para reiniciar.")
  while true do
    local ev = computer.pullSignal()
    if ev == "key_down" or ev == "touch" then computer.shutdown(true) end
  end
end

gpu.set(25, 14, "[2/2] A preparar ambiente e efetuar Boot...")
os.sleep(0.6)

-- Compila e executa o script descarregado num ambiente seguro
local compiledScript, syntaxErr = load(remoteCode, "=nitro_os", "t", _G)
if not compiledScript then
  gpu.setBackground(0xB71C1C)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(15, 8, 52, 8, " ")
  gpu.set(17, 10, "ERRO DE SINTAXE NO SCRIPT:")
  gpu.set(17, 12, tostring(syntaxErr):sub(1, 45))
  gpu.set(17, 14, "Pressione qualquer tecla para reiniciar.")
  while true do
    local ev = computer.pullSignal()
    if ev == "key_down" or ev == "touch" then computer.shutdown(true) end
  end
end

-- Execução bem-sucedida do Nitro OS
pcall(compiledScript)
