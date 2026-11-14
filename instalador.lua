-- Plasma OS - bootstrapper (init.lua)
-- Sem OpenOS. Requer placa de internet para instalar pela primeira vez.

local REPO = "https://raw.githubusercontent.com/pmiguel10766-stack/Plasma_OS/main/"
local BOOT_PATH = "/plasma/boot.lua"
local INSTALLER = "instalador.lua"

local fs = component.proxy(computer.getBootAddress())

-- Tela: mensagens de status
local gpu, w, h
do
  local g, s = component.list("gpu")(), component.list("screen")()
  if g and s then
    gpu = component.proxy(g)
    gpu.bind(s)
    local mw, mh = gpu.maxResolution()
    gpu.setResolution(mw, mh)
    w, h = gpu.getResolution()
    gpu.setBackground(0x000000)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(1, 1, w, h, " ")
  end
end

local line = 1
local function say(text)
  if gpu then
    gpu.set(2, line, text:sub(1, w - 2))
  end
  line = line + 1
  if line > h then line = 1 end
end

local function readAll(path)
  local f, err = fs.open(path, "r")
  if not f then return nil, err end
  local parts = {}
  while true do
    local chunk = fs.read(f, math.huge)
    if not chunk then break end
    parts[#parts + 1] = chunk
  end
  fs.close(f)
  return table.concat(parts)
end

local function download(url)
  local netAddr = component.list("internet")()
  if not netAddr then return nil, "sem placa de internet" end
  local net = component.proxy(netAddr)

  local ok, handle = pcall(net.request, url)
  if not ok or not handle then return nil, "falha ao abrir " .. url end

  local timeout = computer.uptime() + 15
  while true do
    local done, connErr = handle.finishConnect()
    if done then break end
    if connErr or computer.uptime() > timeout then
      handle.close()
      return nil, "sem conexão com o GitHub"
    end
    computer.pullSignal(0.1)
  end

  local parts = {}
  while true do
    local chunk = handle.read(math.huge)
    if not chunk then break end
    parts[#parts + 1] = chunk
  end
  handle.close()
  return table.concat(parts)
end

local function runSource(src, name)
  local fn, err = load(src, "=" .. name, "t", _G)
  if not fn then
    say("Erro de sintaxe em " .. name .. ": " .. tostring(err))
    return false
  end
  local ok, runErr = pcall(fn)
  if not ok then
    say("Erro ao rodar " .. name .. ": " .. tostring(runErr))
    return false
  end
  return true
end

-- Fluxo principal -------------------------------------------------------

say("Plasma OS - iniciando...")

if fs.exists(BOOT_PATH) then
  local src, err = readAll(BOOT_PATH)
  if not src then
    say("Não consegui ler " .. BOOT_PATH .. ": " .. tostring(err))
  else
    runSource(src, "plasma/boot.lua")
  end
else
  say("Sistema não encontrado. Baixando instalador...")
  local src, err = download(REPO .. INSTALLER)
  if not src then
    say("Falha: " .. tostring(err))
    say("Verifique a placa de internet e reinicie.")
  else
    runSource(src, INSTALLER)
  end
end

while true do computer.pullSignal(1) end
