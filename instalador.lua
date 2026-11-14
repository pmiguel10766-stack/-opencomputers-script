-- instalador.lua - Instalador do Plasma OS (sem OpenOS, com interface)
-- Baixa files.txt do GitHub e copia cada arquivo listado para o disco escolhido.
-- init.lua vai para a raiz do disco. O resto vai para /PlasmaOS/.

local REPO = "https://raw.githubusercontent.com/pmiguel10766-stack/Plasma_OS/main/"
local SYSTEM_DIR = "/PlasmaOS/"
local TIMEOUT = 30

-- Tela ----------------------------------------------------------------------

local gpuAddr = component.list("gpu")()
local scrAddr = component.list("screen")()
if not gpuAddr or not scrAddr then error("Precisa de GPU e tela.") end

local gpu = component.proxy(gpuAddr)
gpu.bind(scrAddr)
local mw, mh = gpu.maxResolution()
gpu.setResolution(mw, mh)
local W, H = gpu.getResolution()

local C = {
  desk = 0xE4E4E4, win = 0xF6F6F6, line = 0xC8C8C8,
  text = 0x222222, dim = 0x777777, blue = 0x0A84FF,
  white = 0xFFFFFF, bar = 0x3DB54A, barBg = 0xD6D6D6, err = 0xD93025,
}

local PW, PH = 50, 18
local PX = math.floor((W - PW) / 2) + 1
local PY = math.floor((H - PH) / 2) + 1

local state = { screen = "welcome", disks = {}, sel = 1, pct = 0, file = "", err = "" }
local buttons = {}

-- Rede ----------------------------------------------------------------------

local function download(path)
  local inetAddr = component.list("internet")()
  if not inetAddr then return nil, "sem placa de internet" end

  local net = component.proxy(inetAddr)
  local ok, handle = pcall(net.request, REPO .. path)
  if not ok or not handle then return nil, tostring(handle) end

  local started = computer.uptime()

  while not handle:finishConnect() do
    if computer.uptime() - started > TIMEOUT then
      handle:close()
      return nil, "tempo esgotado ao conectar"
    end
    computer.pullSignal(0.1)
  end

  local parts = {}
  while true do
    if computer.uptime() - started > TIMEOUT then
      handle:close()
      return nil, "tempo esgotado ao baixar"
    end
    local chunk, reason = handle:read(2048)
    if chunk then
      parts[#parts + 1] = chunk
    elseif reason then
      handle:close()
      return nil, tostring(reason)
    else
      break
    end
  end
  handle:close()

  local data = table.concat(parts)
  if data == "" then return nil, "arquivo vazio" end
  if data:sub(1, 4) == "404:" then return nil, "não encontrado no GitHub" end
  return data
end

-- Disco ---------------------------------------------------------------------

local function listDisks()
  local out = {}
  local tmp = computer.tmpAddress()
  for addr in component.list("filesystem") do
    if addr ~= tmp then
      local p = component.proxy(addr)
      if not p.isReadOnly() then
        out[#out + 1] = {
          addr = addr,
          label = p.getLabel() or addr:sub(1, 8),
          kb = math.floor(p.spaceTotal() / 1024),
        }
      end
    end
  end
  return out
end

local function writeFile(fs, path, data)
  local dir = path:match("^(.*)/[^/]+$")
  if dir and dir ~= "" then
    local acc = ""
    for part in dir:gmatch("[^/]+") do
      acc = acc .. "/" .. part
      if not fs.exists(acc) then fs.makeDirectory(acc) end
    end
  end
  local h, e = fs.open(path, "w")
  if not h then return false, e end
  fs.write(h, data)
  fs.close(h)
  return true
end

local function destFor(path)
  if path == "init.lua" then return "/init.lua" end
  return SYSTEM_DIR .. path
end

-- Instalação ----------------------------------------------------------------

local function install(addr, progress)
  local fs = component.proxy(addr)

  progress(0, "files.txt")
  local listRaw, e = download("files.txt")
  if not listRaw then return false, "files.txt: " .. tostring(e) end

  local files = {}
  for line in listRaw:gmatch("[^\r\n]+") do
    local f = line:match("^%s*(.-)%s*$")
    if f ~= "" then files[#files + 1] = f end
  end
  if #files == 0 then return false, "files.txt vazio" end

  for i, path in ipairs(files) do
    progress((i - 1) / #files, path)

    local data, e2 = download(path)
    if not data then return false, path .. ": " .. tostring(e2) end

    if path:sub(-4) == ".lua" then
      local fn, le = load(data, "=" .. path)
      if not fn then return false, path .. " com erro: " .. tostring(le) end
    end

    local dest = destFor(path)
    local ok, e3 = writeFile(fs, dest, data)
    if not ok then return false, dest .. ": " .. tostring(e3) end
  end

  local ok, e4 = writeFile(fs, SYSTEM_DIR .. "files.txt", listRaw)
  if not ok then return false, "files.txt local: " .. tostring(e4) end

  progress(1, "concluído")
  return true
end

-- Interface -----------------------------------------------------------------

local function fillBox(x, y, w, h, color)
  gpu.setBackground(color)
  gpu.fill(x, y, w, h, " ")
end

local function center(y, text, color)
  gpu.setForeground(color or C.text)
  gpu.set(PX + math.floor((PW - #text) / 2), y, text)
end

local function button(id, label, row, primary)
  local bw = #label + 6
  local bx = PX + math.floor((PW - bw) / 2)
  local by = PY + row
  buttons[id] = { x = bx, y = by, w = bw }
  gpu.setBackground(primary and C.blue or C.line)
  gpu.setForeground(primary and C.white or C.text)
  gpu.fill(bx, by, bw, 1, " ")
  gpu.set(bx + 3, by, label)
end

local function frame(title)
  buttons = {}
  fillBox(1, 1, W, H, C.desk)
  fillBox(PX, PY, PW, PH, C.win)
  fillBox(PX, PY, PW, 1, C.line)
  gpu.setBackground(C.line)
  gpu.setForeground(C.text)
  gpu.set(PX + math.floor((PW - #title) / 2), PY, title)
end

local function drawDisks()
  for i, d in ipairs(state.disks) do
    local y = PY + 2 + i
    if i == state.sel then
      gpu.setBackground(C.blue)
      gpu.setForeground(C.white)
    else
      gpu.setBackground(C.win)
      gpu.setForeground(C.text)
    end
    gpu.fill(PX + 3, y, PW - 6, 1, " ")
    gpu.set(PX + 4, y, d.label .. "  (" .. d.kb .. " KB)")
  end
end

local function draw()
  local s = state.screen
  if s == "welcome" then
    frame("Instalar o Plasma OS")
    center(PY + 3, "Bem-vindo ao instalador do Plasma OS.")
    center(PY + 5, "O sistema será baixado do GitHub e copiado", C.dim)
    center(PY + 6, "para o disco que você escolher.", C.dim)
    button("next", "Continuar", PH - 3, true)

  elseif s == "disk" then
    frame("Escolha o disco")
    if #state.disks == 0 then
      center(PY + 4, "Nenhum disco gravável encontrado.", C.err)
    else
      drawDisks()
    end
    button("install", "Instalar", PH - 3, true)

  elseif s == "progress" then
    frame("Instalando o Plasma OS")
    center(PY + 3, "Copiando arquivos...")
    center(PY + 5, state.file:sub(1, PW - 4), C.dim)
    local bw = PW - 8
    local bx = PX + 4
    local by = PY + 7
    fillBox(bx, by, bw, 1, C.barBg)
    fillBox(bx, by, math.floor(bw * state.pct), 1, C.bar)
    center(PY + 9, math.floor(state.pct * 100) .. "%")

  elseif s == "done" then
    frame("Instalação concluída")
    center(PY + 4, "Plasma OS instalado com sucesso.")
    center(PY + 5, "Retire o disco de instalação e clique em Reiniciar.", C.dim)
    button("reboot", "Reiniciar", PH - 3, true)

  elseif s == "error" then
    frame("Erro na instalação")
    center(PY + 4, "Não foi possível concluir.", C.err)
    center(PY + 6, state.err:sub(1, PW - 4), C.dim)
    button("back", "Tentar de novo", PH - 3, true)
  end
end

local function go(s)
  state.screen = s
  if s == "disk" then
    state.disks = listDisks()
    state.sel = 1
  end
  draw()
end

local function hitButton(x, y)
  for id, b in pairs(buttons) do
    if x >= b.x and x < b.x + b.w and y == b.y then return id end
  end
  return nil
end

local function runInstall(addr)
  state.screen = "progress"
  local ok, err = install(addr, function(pct, file)
    state.pct = pct
    state.file = file
    draw()
  end)
  if ok then
    go("done")
  else
    state.err = tostring(err)
    go("error")
  end
end

-- Ações ---------------------------------------------------------------------

local function activate(id)
  local s = state.screen
  if s == "welcome" and id == "next" then
    go("disk")
  elseif s == "disk" and id == "install" then
    if #state.disks > 0 then runInstall(state.disks[state.sel].addr) end
  elseif s == "done" and id == "reboot" then
    computer.shutdown(true)
  elseif s == "error" and id == "back" then
    go("disk")
  end
end

local function primaryId()
  local s = state.screen
  if s == "welcome" then return "next" end
  if s == "disk" then return "install" end
  if s == "done" then return "reboot" end
  if s == "error" then return "back" end
  return nil
end

local ENTER_KEYS = { [28] = true, [156] = true }

-- Principal -----------------------------------------------------------------

draw()
while true do
  local sig, _, a, b = computer.pullSignal()

  if sig == "touch" then
    local id = hitButton(a, b)
    if id then
      activate(id)
    elseif state.screen == "disk" then
      local i = b - (PY + 2)
      if i >= 1 and i <= #state.disks then
        state.sel = i
        draw()
      end
    end

  elseif sig == "key_down" then
    if ENTER_KEYS[b] then
      local id = primaryId()
      if id then activate(id) end
    end
  end
end
