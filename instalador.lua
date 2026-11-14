-- Plasma OS - Instalador
-- Sem OpenOS. Precisa de GPU, tela, disco e placa de rede (internet card).

local REPO = "https://raw.githubusercontent.com/pmiguel10766-stack/Plasma_OS/main/"
local BOOT = computer.getBootAddress()

local function proxyOf(kind)
  local addr = component.list(kind)()
  if addr then return component.proxy(addr) end
  return nil
end

local gpu = proxyOf("gpu")
local scrAddr = component.list("screen")()
if not gpu or not scrAddr then error("Plasma OS: precisa de GPU e tela.") end
gpu.bind(scrAddr)
local mw, mh = gpu.maxResolution()
gpu.setResolution(mw, mh)
local W, H = gpu.getResolution()

local C = {
  bg = 0xF2F2F2, panel = 0xFFFFFF, text = 0x1A1A1A, sub = 0x6E6E6E,
  blue = 0x0A84FF, barBg = 0xD6D6D6, white = 0xFFFFFF, red = 0xD93025,
}

-- Textos ----------------------------------------------------------------

local T = {
  pt = {
    welcome_title = "Bem-vindo ao Plasma OS",
    welcome_sub   = "Este assistente vai instalar o Plasma OS em um disco.",
    next = "Continuar", back = "Voltar", cancel = "Cancelar",
    lang_title = "Idioma", lang_sub = "Escolha o idioma da instalação.",
    disk_title = "Escolha o disco", disk_sub = "Onde o Plasma OS será instalado.",
    readonly = "Somente leitura",
    readonly_msg = "Este disco é somente leitura.",
    no_disks = "Nenhum disco encontrado.",
    confirm_title = "Confirmar instalação",
    confirm_sub = "Você pode apagar o disco antes de instalar.",
    wipe_yes = "Apagar e instalar", install_only = "Só instalar",
    install_title = "Instalando Plasma OS",
    no_net = "Sem placa de rede (internet card).",
    no_list = "Não foi possível baixar files.txt",
    step_list = "Baixando lista de arquivos...",
    step_dl = "Baixando", step_wipe = "Apagando disco...", step_write = "Gravando",
    error_title = "Erro na instalação", retry = "Tentar novamente",
    done_title = "Instalação concluída",
    done_sub = "O computador reiniciará em %d segundos.",
    restart = "Reiniciar agora",
  },
  en = {
    welcome_title = "Welcome to Plasma OS",
    welcome_sub   = "This wizard will install Plasma OS on a disk.",
    next = "Continue", back = "Back", cancel = "Cancel",
    lang_title = "Language", lang_sub = "Choose the installation language.",
    disk_title = "Choose a disk", disk_sub = "Where Plasma OS will be installed.",
    readonly = "Read-only",
    readonly_msg = "This disk is read-only.",
    no_disks = "No disk found.",
    confirm_title = "Confirm installation",
    confirm_sub = "You can erase the disk before installing.",
    wipe_yes = "Erase and install", install_only = "Install only",
    install_title = "Installing Plasma OS",
    no_net = "No network card (internet card).",
    no_list = "Could not download files.txt",
    step_list = "Downloading file list...",
    step_dl = "Downloading", step_wipe = "Erasing disk...", step_write = "Writing",
    error_title = "Installation error", retry = "Try again",
    done_title = "Installation complete",
    done_sub = "The computer will restart in %d seconds.",
    restart = "Restart now",
  },
}

local state = { screen = "welcome", lang = "pt" }
local buttons = {}
local P = {}

local function t(k, ...)
  local s = T[state.lang][k] or k
  if select("#", ...) > 0 then return string.format(s, ...) end
  return s
end

-- Desenho ---------------------------------------------------------------

local function fmt(n)
  if n >= 1048576 then return string.format("%.1f MB", n / 1048576) end
  return string.format("%d KB", math.floor(n / 1024))
end

local function frame()
  gpu.setBackground(C.bg)
  gpu.fill(1, 1, W, H, " ")
  P.w = math.min(60, W - 4)
  P.h = math.min(20, H - 2)
  P.x = math.floor((W - P.w) / 2) + 1
  P.y = math.floor((H - P.h) / 2) + 1
  gpu.setBackground(C.panel)
  gpu.fill(P.x, P.y, P.w, P.h, " ")
end

local function center(y, s, fg)
  gpu.setBackground(C.panel)
  gpu.setForeground(fg or C.text)
  gpu.set(P.x + math.floor((P.w - #s) / 2), y, s)
end

local function bar(x, y, width, frac)
  gpu.setBackground(C.barBg)
  gpu.fill(x, y, width, 1, " ")
  local filled = math.floor(width * math.max(0, math.min(1, frac)))
  if filled > 0 then
    gpu.setBackground(C.blue)
    gpu.fill(x, y, filled, 1, " ")
  end
end

local function button(x, y, label, primary, action, w)
  local bw = w or (#label + 6)
  gpu.setBackground(primary and C.blue or C.barBg)
  gpu.setForeground(primary and C.white or C.text)
  gpu.fill(x, y, bw, 3, " ")
  gpu.set(x + math.floor((bw - #label) / 2), y + 1, label)
  table.insert(buttons, { x = x, y = y, w = bw, h = 3, action = action })
end

-- Botão centralizado no painel
local function cbtn(y, label, primary, action)
  local bw = #label + 8
  button(P.x + math.floor((P.w - bw) / 2), y, label, primary, action, bw)
end

-- Voltar à esquerda, avançar à direita
local function navButtons(backAction, label, action)
  local y = P.y + P.h - 4
  if backAction then button(P.x + 3, y, t("back"), false, backAction) end
  if label then
    local bw = #label + 6
    button(P.x + P.w - bw - 2, y, label, true, action, bw)
  end
end

local function hit(x, y)
  for i = #buttons, 1, -1 do
    local b = buttons[i]
    if x >= b.x and x < b.x + b.w and y >= b.y and y < b.y + b.h then
      return b
    end
  end
  return nil
end

local function drawProgress(msg, frac)
  buttons = {}
  frame()
  center(P.y + 4, t("install_title"))
  center(P.y + 8, msg, C.sub)
  bar(P.x + 4, P.y + 11, P.w - 8, frac)
  center(P.y + 13, string.format("%d%%", math.floor(frac * 100)), C.sub)
end

-- Rede ------------------------------------------------------------------

local function httpGet(inet, url)
  local okReq, h, err = pcall(inet.request, url)
  if not okReq then return nil, h end
  if not h then return nil, err end

  local deadline = computer.uptime() + 15
  while not h.finishConnect() do
    if computer.uptime() > deadline then
      h.close()
      return nil, "timeout"
    end
    computer.pullSignal(0.1)
  end

  local parts = {}
  while true do
    local chunk, reason = h.read(math.huge)
    if chunk then
      parts[#parts + 1] = chunk
    else
      h.close()
      if reason then return nil, reason end
      return table.concat(parts)
    end
  end
end

-- Discos ----------------------------------------------------------------

local function listDisks()
  local out = {}
  for addr in component.list("filesystem") do
    if addr ~= BOOT then
      local fs = component.proxy(addr)
      table.insert(out, {
        addr = addr,
        label = fs.getLabel() or addr:sub(1, 8),
        total = fs.spaceTotal(),
        used = fs.spaceUsed(),
        ro = fs.isReadOnly(),
      })
    end
  end
  return out
end

local function wipe(fs)
  local function rm(dir)
    for _, name in ipairs(fs.list(dir) or {}) do
      local p = dir .. name
      if name:sub(-1) == "/" then rm(p) end
      fs.remove(p)
    end
  end
  rm("/")
end

local function writeFile(fs, path, data)
  local dir = path:match("^(.*)/[^/]*$")
  if dir and dir ~= "" and not fs.exists("/" .. dir) then
    local ok, err = fs.makeDirectory("/" .. dir)
    if not ok then return false, err end
  end
  local h, err = fs.open("/" .. path, "w")
  if not h then return false, err end
  local ok, werr = fs.write(h, data)
  fs.close(h)
  return ok, werr
end

-- Instalação ------------------------------------------------------------

local function install(dest, doWipe)
  local inet = proxyOf("internet")
  if not inet then return false, t("no_net") end

  drawProgress(t("step_list"), 0)
  local list, err = httpGet(inet, REPO .. "files.txt")
  if not list then return false, t("no_list") .. ": " .. tostring(err) end

  local paths = {}
  for line in list:gmatch("[^\r\n]+") do
    line = line:match("^%s*(.-)%s*$")
    if line ~= "" and line:sub(1, 1) ~= "#" then
      paths[#paths + 1] = line
    end
  end

  -- Baixa tudo e valida antes de tocar no disco
  local files = {}
  for i, p in ipairs(paths) do
    drawProgress(t("step_dl") .. " " .. p, i / #paths * 0.5)
    local body, derr = httpGet(inet, REPO .. p)
    if not body then return false, p .. ": " .. tostring(derr) end
    if p:sub(-4) == ".lua" then
      local fn, serr = load(body, "=" .. p, "t")
      if not fn then return false, p .. ": " .. tostring(serr) end
    end
    files[i] = { path = p, data = body }
  end

  if doWipe then
    drawProgress(t("step_wipe"), 0.5)
    wipe(component.proxy(dest))
  end

  local fs = component.proxy(dest)
  for i, f in ipairs(files) do
    drawProgress(t("step_write") .. " " .. f.path, 0.5 + i / #files * 0.5)
    local ok, werr = writeFile(fs, f.path, f.data)
    if not ok then return false, f.path .. ": " .. tostring(werr) end
  end
  return true
end

-- Ações -----------------------------------------------------------------

local function go(name) state.screen = name end

local function pick(d)
  if d.ro then
    state.msg = t("readonly_msg")
    return
  end
  state.msg = nil
  state.dest = d.addr
  state.label = d.label
  go("confirm")
end

local function runInstall(doWipe)
  state.doWipe = doWipe
  local ok, err = install(state.dest, doWipe)
  if ok then
    state.doneAt = computer.uptime() + 5
    state.lastLeft = nil
    go("done")
  else
    state.err = tostring(err)
    go("error")
  end
end

-- Telas -----------------------------------------------------------------

local function drawWelcome()
  center(P.y + 5, t("welcome_title"))
  center(P.y + 7, t("welcome_sub"), C.sub)
  navButtons(nil, t("next"), function() go("lang") end)
end

local function drawLang()
  center(P.y + 4, t("lang_title"))
  center(P.y + 6, t("lang_sub"), C.sub)
  local half = math.floor(P.w / 2)
  button(P.x + half - 22, P.y + 9, "Português", false, function()
    state.lang = "pt"; go("disk")
  end, 20)
  button(P.x + half + 2, P.y + 9, "English", false, function()
    state.lang = "en"; go("disk")
  end, 20)
  navButtons(function() go("welcome") end)
end

local function drawDisk()
  center(P.y + 2, t("disk_title"))
  center(P.y + 3, t("disk_sub"), C.sub)

  local list = listDisks()
  if #list == 0 then center(P.y + 7, t("no_disks"), C.red) end

  for i, d in ipairs(list) do
    if i > 3 then break end
    local y = P.y + 5 + (i - 1) * 3
    gpu.setBackground(C.panel)
    gpu.setForeground(C.text)
    local tag = d.ro and ("  [" .. t("readonly") .. "]") or ""
    gpu.set(P.x + 3, y, d.label .. tag)
    gpu.setForeground(C.sub)
    gpu.set(P.x + 3, y + 1, fmt(d.used) .. " / " .. fmt(d.total))
    bar(P.x + 3, y + 2, P.w - 6, d.total > 0 and d.used / d.total or 0)
    table.insert(buttons, {
      x = P.x + 2, y = y, w = P.w - 4, h = 3,
      action = function() pick(d) end,
    })
  end

  if state.msg then center(P.y + 14, state.msg, C.red) end
  navButtons(function() go("lang") end)
end

local function drawConfirm()
  center(P.y + 3, t("confirm_title"))
  center(P.y + 5, state.label, C.sub)
  center(P.y + 6, t("confirm_sub"), C.sub)
  cbtn(P.y + 8, t("wipe_yes"), true, function() runInstall(true) end)
  cbtn(P.y + 11, t("install_only"), false, function() runInstall(false) end)
  cbtn(P.y + 14, t("cancel"), false, function() go("disk") end)
end

local function drawError()
  center(P.y + 4, t("error_title"), C.red)
  local msg = state.err or ""
  center(P.y + 7, msg:sub(1, P.w - 6), C.text)
  if #msg > P.w - 6 then
    center(P.y + 8, msg:sub(P.w - 5, 2 * (P.w - 6)), C.sub)
  end
  local y = P.y + P.h - 4
  button(P.x + 3, y, t("back"), false, function() go("disk") end)
  local label = t("retry")
  local bw = #label + 6
  button(P.x + P.w - bw - 2, y, label, true, function() runInstall(state.doWipe) end, bw)
end

local function drawDone()
  local left = math.max(0, math.ceil(state.doneAt - computer.uptime()))
  center(P.y + 4, t("done_title"))
  center(P.y + 7, t("done_sub", left), C.sub)
  cbtn(P.y + 11, t("restart"), true, function() computer.shutdown(true) end)
end

local drawers = {
  welcome = drawWelcome, lang = drawLang, disk = drawDisk,
  confirm = drawConfirm, error = drawError, done = drawDone,
}

local function draw()
  buttons = {}
  frame()
  drawers[state.screen]()
end

-- Loop ------------------------------------------------------------------

draw()
while true do
  if state.screen == "done" then
    local left = math.max(0, math.ceil(state.doneAt - computer.uptime()))
    if left == 0 then computer.shutdown(true) end
    if left ~= state.lastLeft then
      state.lastLeft = left
      draw()
    end
  end

  local sig, _, a, b = computer.pullSignal(0.5)
  if sig == "touch" then
    local btn = hit(a, b)
    if btn then
      btn.action()
      draw()
    end
  elseif sig == "key_down" then
    if b == 28 and state.screen == "welcome" then  -- Enter
      go("lang")
      draw()
    end
  end
end
