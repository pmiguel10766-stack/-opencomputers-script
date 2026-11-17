-- init.lua (instalador do Plasma_OS, sem OpenOS)
local component = component
local computer = computer

local BASE = "https://raw.githubusercontent.com/pmiguel10766-stack/Plasma_OS/refs/heads/main/"
local ARQUIVO_LISTA = "files.txt"

local bootAddr = computer.getBootAddress()
local disco = component.proxy(bootAddr)
local netAddr = component.list("internet")()
local net = netAddr and component.proxy(netAddr)

local function print_(msg)
  local gpu = component.list("gpu")()
  local screen = component.list("screen")()
  if gpu and screen then
    local g = component.proxy(gpu)
    g.bind(screen)
    local w, h = g.getResolution()
    g.setBackground(0x000000)
    g.setForeground(0xFFFFFF)
    g.fill(1, 1, w, h, " ")
  end
  io.write(msg .. "\n")
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
  disco.write(h, conteudo)
  disco.close(h)
end

print_("Plasma_OS - instalador")
print_("Baixando lista de arquivos...")

local lista = baixar(BASE .. ARQUIVO_LISTA)
local total, ok, falhas = 0, 0, {}
local initCode = nil

for linha in lista:gmatch("[^\r\n]+") do
  local nome = linha:match("^%s*(.-)%s*$")
  if nome ~= "" then
    total = total + 1
    io.write("Baixando " .. nome .. " ... ")
    local sucesso, dados = pcall(baixar, BASE .. nome)
    if sucesso then
      local ok2, err = pcall(salvar, nome, dados)
      if ok2 then
        print_("OK")
        ok = ok + 1
        if nome == "init.lua" then initCode = dados end
      else
        print_("ERRO ao salvar: " .. tostring(err))
        falhas[#falhas + 1] = nome
      end
    else
      print_("ERRO no download: " .. tostring(dados))
      falhas[#falhas + 1] = nome
    end
  end
end

print_("")
print_("Concluído: " .. ok .. "/" .. total .. " arquivos.")
if #falhas > 0 then
  print_("Falharam: " .. table.concat(falhas, ", "))
  print_("Reinicie o computador para tentar de novo.")
  return
end

if initCode then
  local f, e = load(initCode, "=init.lua")
  if f then
    f()
  else
    print_("Erro no init.lua: " .. tostring(e))
  end
else
  print_("init.lua não foi encontrado na lista.")
end
