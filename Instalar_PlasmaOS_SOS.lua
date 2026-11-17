-- init.lua (instalador do Plasma_OS, sem 676767667676677667667676767676776767677676777)
local BASE = "https://raw.githubusercontent.com/pmiguel10766-stack/Plasma_OS/refs/heads/main/"

local disco = component.proxy(computer.getBootAddress())
if not disco then error("Disco de boot não encontrado") end

local netAddr = component.list("internet")()
local net = netAddr and component.proxy(netAddr)

local gpuAddr = component.list("gpu")()
local screenAddr = component.list("screen")()
local gpu = gpuAddr and component.proxy(gpuAddr)
local W, H, linha = 80, 25, 1

if gpu then
  if screenAddr then gpu.bind(screenAddr) end
  W, H = gpu.getResolution()
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, W, H, " ")
end

local function msg(texto)
  if not gpu then return end
  if linha > H then
    gpu.copy(1, 2, W, H - 1, 0, -1)
    gpu.fill(1, H, W, 1, " ")
    linha = H
  end
  gpu.set(1, linha, tostring(texto))
  linha = linha + 1
end

local function baixar(url)
  if not net then error("Sem placa de internet") end
  local h, err = net.request(url)
  if not h then error("Falha ao conectar: " .. tostring(err)) end
  while not h.finishConnect() do computer.pullSignal(0.05) end
  local partes = {}
  while true do
    local pedaco = h.read(2048)
    if pedaco == nil then break end
    if pedaco ~= "" then partes[#partes + 1] = pedaco end
  end
  h.close()
  return table.concat(partes)
end

local function salvar(caminho, conteudo)
  local pasta = caminho:match("(.*/)")
  if pasta and not disco.exists(pasta) then
    disco.makeDirectory(pasta)
  end
  local h = disco.open(caminho, "w")
  if not h then error("Não foi possível abrir " .. caminho) end
  disco.write(h, conteudo)
  disco.close(h)
end

msg("Plasma_OS - instalador")
msg("Baixando lista de arquivos...")

local lista = baixar(BASE .. "files.txt")
local total, ok, falhas = 0, 0, {}
local initCode = nil

for linhaArq in lista:gmatch("[^\r\n]+") do
  local nome = linhaArq:match("^%s*(.-)%s*$")
  if nome ~= "" then
    total = total + 1
    msg("Baixando " .. nome)
    local sucesso, dados = pcall(baixar, BASE .. nome)
    if sucesso then
      local ok2, err = pcall(salvar, nome, dados)
      if ok2 then
        msg("  OK")
        ok = ok + 1
        if nome == "init.lua" then initCode = dados end
      else
        msg("  ERRO ao salvar: " .. tostring(err))
        falhas[#falhas + 1] = nome
      end
    else
      msg("  ERRO no download: " .. tostring(dados))
      falhas[#falhas + 1] = nome
    end
  end
end

msg("")
msg("Concluído: " .. ok .. "/" .. total .. " arquivos.")

if #falhas > 0 then
  msg("Falharam: " .. table.concat(falhas, ", "))
  msg("Reinicie o computador para tentar de novo.")
  return
end

if initCode then
  local f, e = load(initCode, "=init.lua")
  if f then
    f()
  else
    msg("Erro no init.lua: " .. tostring(e))
  end
else
  msg("init.lua não foi encontrado na lista.")
end
