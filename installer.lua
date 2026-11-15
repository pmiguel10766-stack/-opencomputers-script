-- Nitro OS - Instalador (layout do instalador do Plasma, identidade vermelha e preta)
-- Opcoes: Pro, Go (sistema Nitro) e Plasma OS (novo, instalado em /plasma/ sem mexer no /init.lua do Nitro).
-- Sem OpenOS. Precisa de GPU, tela, disco e placa de rede (internet card).

local cp, cl = computer, component
local NITRO = "https://raw.githubusercontent.com/pmiguel10766-stack/Atualizar_Nitro_OS/main/"
local PLASMA = "https://raw.githubusercontent.com/pmiguel10766-stack/Plasma_OS/main/"

local gpuA, scrA = cl.list("gpu")(), cl.list("screen")()
if not gpuA or not scrA then error("Nitro OS: precisa de GPU e tela.") end
local gpu = cl.proxy(gpuA)
gpu.bind(scrA)
local mw, mh = gpu.maxResolution()
gpu.setResolution(mw, mh)
local W, H = gpu.getResolution()

local netA = cl.list("internet")()
local net = netA and cl.proxy(netA) or nil

-- Cores: identidade do Nitro (preto e vermelho)
local C = {
  bg = 0x0B0B0B, panel = 0x1A1A1A, side = 0x0F0F0F, title = 0x2A2A2A,
  text = 0xF2F2F2, dim = 0x8A8A8A, red = 0xE10600, redDark = 0x7A0000,
  ok = 0x2ECC71, warn = 0xF5A623, btn = 0x2F2F2F, rule = 0x3A3A3A, white = 0xFFFFFF,
}

local function len(s) return (unicode and unicode.len(s)) or #s end
local function usub(s, i, j)
  if unicode then return unicode.sub(s, i, j) end
  return s:sub(i, j)
end

local function rect(x, y, w, h, bg)
  gpu.setBackground(bg)
  gpu.fill(x, y, w, h, " ")
end

local function put(x, y, s, fg, bg, maxw)
  if maxw and len(s) > maxw then s = usub(s, 1, maxw) end
  gpu.setForeground(fg or C.text)
  gpu.setBackground(bg or C.panel)
  gpu.set(x, y, s)
end

-- Textos --------------------------------------------------------------------

local T = {
  pt = {
    steps = { "Introdução", "Idioma", "Destino", "Versão", "Confirmação", "Instalação", "Resumo" },
    win = "Instalar Nitro OS",
    welcome_t = "Bem-vindo ao Nitro OS",
    welcome_s = "Este assistente vai instalar o Nitro OS em um disco.",
    lang_t = "Idioma", lang_s = "Escolha o idioma da instalação.",
    disk_t = "Escolha o disco", disk_s = "Onde o Nitro OS será instalado.",
    ro = "Somente leitura", ro_msg = "Este disco é somente leitura.",
    nodisk = "Nenhum disco encontrado.",
    ver_t = "Escolha a versão", ver_s = "Qual sistema instalar.",
    v_pro = "Nitro OS Pro", v_pro_d = "Completo, com todos os apps e efeitos.",
    v_go = "Nitro OS Go", v_go_d = "Leve: menos apps, sem pausas no boot.",
    v_plasma = "Plasma OS (novo)", v_plasma_d = "Instala o Plasma em /plasma/. O Nitro continua.",
    conf_t = "Confirmar instalação", conf_s = "Revise antes de instalar.",
    disk_lbl = "Disco:", ver_lbl = "Versão:",
    init_warn = "Já existe um /init.lua aqui; será substituído.",
    plasma_ok = "O /init.lua do Nitro não será alterado.",
    wipe_btn = "Apagar disco e instalar", keep_btn = "Instalar sem apagar",
    wipe_t = "Apagar disco", wipe_w = "APAGAR",
    wipe_warn = "Tudo em \"%s\" será apagado.",
    wipe_ask = "Digite %s para confirmar.",
    inst_t = "Instalando o Nitro OS",
    copy = "Gravando", dl = "Baixando ",
    e_net = "Sem placa de rede (internet card).",
    e_ram = "Memória livre insuficiente.",
    e_list = "Não foi possível baixar files.txt",
    e_bad = "Arquivo inválido (não compila)",
    e_write = "Não foi possível gravar",
    err_t = "Erro na instalação",
    done_t = "Instalação concluída",
    done_s = "O computador reiniciará em %d segundos.",
    next = "Continuar", back = "Voltar", retry = "Tentar novamente",
    restart = "Reiniciar agora",
  },
  en = {
    steps = { "Introduction", "Language", "Destination", "Version", "Confirmation", "Installation", "Summary" },
    win = "Install Nitro OS",
    welcome_t = "Welcome to Nitro OS",
    welcome_s = "This wizard will install Nitro OS on a disk.",
    lang_t = "Language", lang_s = "Choose the installation language.",
    disk_t = "Choose a disk", disk_s = "Where Nitro OS will be installed.",
    ro = "Read-only", ro_msg = "This disk is read-only.",
    nodisk = "No disk found.",
    ver_t = "Choose the version", ver_s = "Which system to install.",
    v_pro = "Nitro OS Pro", v_pro_d = "Full, with all apps and effects.",
    v_go = "Nitro OS Go", v_go_d = "Light: fewer apps, no boot pauses.",
    v_plasma = "Plasma OS (new)", v_plasma_d = "Installs Plasma in /plasma/. Nitro stays.",
    conf_t = "Confirm installation", conf_s = "Review before installing.",
    disk_lbl = "Disk:", ver_lbl = "Version:",
    init_warn = "A /init.lua already exists here; it will be replaced.",
    plasma_ok = "The Nitro /init.lua will not be changed.",
    wipe_btn = "Erase disk and install", keep_btn = "Install without erasing",
    wipe_t = "Erase disk", wipe_w = "ERASE",
    wipe_warn = "Everything on \"%s\" will be erased.",
    wipe_ask = "Type %s to confirm.",
    inst_t = "Installing Nitro OS",
    copy = "Writing", dl = "Downloading ",
    e_net = "No network card (internet card).",
    e_ram = "Not enough free memory.",
    e_list = "Could not download files.txt",
    e_bad = "Invalid file (does not compile)",
    e_write = "Could not write",
    err_t = "Installation error",
    done_t = "Installation complete",
    done_s = "The computer will restart in %d seconds.",
    next = "Continue", back = "Back", retry = "Try again",
    restart = "Restart now",
  },
}

local S = { screen = "welcome", lang = "pt", sel = 1, dest = nil, ver = "pro",
            typed = "", err = "", doneAt = 0, last = -1 }

local function t(k, ...)
  local s = T[S.lang][k] or k
  if select("#", ...) > 0 then return string.format(s, ...) end
  return s
end

-- Layout --------------------------------------------------------------------

local WX, WY, WW, WH, SB, PX, PY, PW, PH
local btns = {}

local function frame(stepIdx, title)
  rect(1, 1, W, H, C.bg)
  rect(1, 1, W, 1, C.red)
  put(2, 1, "Nitro OS  ·  " .. t("win"), C.white, C.red)

  WW = math.min(74, W - 4)
  WH = math.min(21, H - 4)
  WX = math.floor((W - WW) / 2) + 1
  WY = math.floor((H - WH) / 2) + 1
  SB = 22

  rect(WX + 1, WY + 1, WW, WH, C.redDark)  -- sombra
  rect(WX, WY, WW, WH, C.panel)
  rect(WX, WY, WW, 1, C.title)
  put(WX + 2, WY, "●", C.red, C.title)
  put(WX + 4, WY, "●", C.warn, C.title)
  put(WX + 6, WY, "●", C.ok, C.title)
  put(WX + math.floor((WW - len(title)) / 2), WY, title, C.text, C.title)

  rect(WX, WY + 1, SB, WH - 1, C.side)
  put(WX + 2, WY + 2, "NITRO OS", C.red, C.side)
  for i, name in ipairs(T[S.lang].steps) do
    local y = WY + 4 + (i - 1) * 2
    local cur = (i == stepIdx)
    put(WX + 2, y, cur and "●" or "○", cur and C.red or C.dim, C.side)
    put(WX + 4, y, name, cur and C.text or C.dim, C.side, SB - 5)
  end

  PX, PY, PW, PH = WX + SB, WY + 1, WW - SB, WH - 1
  rect(PX, PY, PW, PH, C.panel)
  btns = {}
end

local function center(y, s, fg)
  put(PX + math.floor((PW - len(s)) / 2), y, s, fg or C.text, C.panel)
end

local function rule()
  put(PX + 2, PY + PH - 5, string.rep("─", PW - 4), C.rule, C.panel)
end

local function button(x, y, label, primary, action, w)
  local bw = w or (len(label) + 6)
  rect(x, y, bw, 3, primary and C.red or C.btn)
  put(x + math.floor((bw - len(label)) / 2), y + 1, label,
      primary and C.white or C.text, primary and C.red or C.btn)
  table.insert(btns, { x = x, y = y, w = bw, h = 3, action = action })
end

local function navButtons(backAction, label, action)
  rule()
  local y = PY + PH - 4
  if backAction then button(PX + 3, y, t("back"), false, backAction) end
  if label then
    local bw = len(label) + 6
    button(PX + PW - bw - 2, y, label, true, action, bw)
  end
end

local function bar(x, y, width, frac)
  rect(x, y, width, 1, C.btn)
  local n = math.floor(width * math.max(0, math.min(1, frac)))
  if n > 0 then rect(x, y, n, 1, C.red) end
end

local function fmtKB(kb)
  if kb >= 1024 then return string.format("%.1f MB", kb / 1024) end
  return string.format("%d KB", kb)
end

-- Discos --------------------------------------------------------------------

local function disks()
  local list = {}
  local tmp = cp.tmpAddress and cp.tmpAddress() or nil
  for addr in cl.list("filesystem") do
    if addr ~= tmp then
      local fs = cl.proxy(addr)
      table.insert(list, {
        addr = addr, fs = fs,
        name = fs.getLabel() or addr:sub(1, 4),
        used = math.floor(fs.spaceUsed() / 1024),
        total = math.floor(fs.spaceTotal() / 1024),
        ro = fs.isReadOnly(),
      })
    end
  end
  return list
end

local function wipe(fs)
  for _, name in ipairs(fs.list("/") or {}) do
    fs.remove("/" .. name)
  end
end

-- Download ------------------------------------------------------------------

local function downloadOnce(url, timeout)
  if not net then return nil, t("e_net") end
  local req, err = net.request(url)
  if not req then return nil, tostring(err) end
  local limit = cp.uptime() + timeout
  local parts = {}
  local ok, e = pcall(function()
    while not req.finishConnect() do
      if cp.uptime() > limit then error("Timeout", 0) end
      cp.pullSignal(0.05)
    end
    local code = req.response()
    if code and code >= 400 then error("HTTP " .. code, 0) end
    while true do
      local c = req.read(math.huge)
      if not c then break end
      parts[#parts + 1] = c
    end
  end)
  pcall(req.close)
  if not ok then return nil, tostring(e) end
  return table.concat(parts)
end

-- tenta 2 vezes (30 s cada); erro HTTP 4xx nao adianta repetir
local function download(base, path)
  local url = base .. path
  local data, err
  for _ = 1, 2 do
    data, err = downloadOnce(url, 30)
    if data then return data end
    if tostring(err):find("HTTP 4", 1, true) then break end
  end
  return nil, tostring(err) .. " (" .. url .. ")"
end

-- Instalacao ----------------------------------------------------------------

local function status(text)
  rect(PX + 3, PY + 14, PW - 6, 1, C.panel)
  put(PX + 3, PY + 14, text, C.dim, C.panel, PW - 6)
end

local function install(dest, ver)
  local base = (ver == "plasma") and PLASMA or NITRO
  local prefix = (ver == "plasma") and "/plasma" or ""
  local fs = cl.proxy(dest)

  if cp.freeMemory() < 30000 then
    return false, t("e_ram") .. " (" .. math.floor(cp.freeMemory() / 1024) .. " KB)", 204
  end

  status(t("dl") .. "files.txt")
  local list, err = download(base, "files.txt")
  if not list or #list == 0 then return false, t("e_list") .. ": " .. tostring(err), 205 end

  local files = {}
  for line in list:gmatch("[^\r\n]+") do
    line = line:match("^%s*(.-)%s*$")
    if #line > 0 and line:sub(1, 1) ~= "#" then files[#files + 1] = line end
  end
  if #files == 0 then return false, "files.txt vazio", 203 end

  -- baixa e valida tudo antes de gravar no disco
  local blobs = {}
  for i, path in ipairs(files) do
    status(t("dl") .. path)
    bar(PX + 4, PY + 12, PW - 8, i / #files * 0.5)
    local data, e = download(base, path)
    if not data then return false, path .. ": " .. tostring(e), 205 end
    if #data == 0 or data:sub(1, 3) == "404" then return false, path, 203 end
    if path:sub(-4) == ".lua" and not load(data, "=" .. path) then
      return false, t("e_bad") .. ": " .. path, 203
    end
    blobs[i] = data
  end

  for i, path in ipairs(files) do
    status(t("copy") .. "  " .. path)
    bar(PX + 4, PY + 12, PW - 8, 0.5 + i / #files * 0.5)
    local full = prefix .. "/" .. path
    local dir = full:match("^(.*)/[^/]+$")
    if dir and dir ~= "" then fs.makeDirectory(dir) end
    local hnd = fs.open(full, "w")
    if not hnd then return false, t("e_write") .. " " .. full, 205 end
    fs.write(hnd, blobs[i])
    fs.close(hnd)
  end

  if ver ~= "plasma" then
    fs.makeDirectory("/nitro")
    local ed = fs.open("/nitro/edition", "w")
    if ed then
      fs.write(ed, ver)
      fs.close(ed)
    end
  end
  return true
end

-- Telas ---------------------------------------------------------------------

local SCREEN = {}

local function go(name)
  S.screen = name
  S.sel = 1
end

local function run(doWipe)
  if doWipe and S.dest then
    local ok, e = pcall(wipe, cl.proxy(S.dest))
    if not ok then S.err = tostring(e); S.code = 203; go("error"); return end
  end
  S.screen = "install"
end

SCREEN.welcome = {
  draw = function()
    frame(1, t("win"))
    center(PY + 5, t("welcome_t"), C.text)
    center(PY + 7, t("welcome_s"), C.dim)
    navButtons(nil, t("next"), function() go("lang") end)
  end,
  key = function(code)
    if code == 28 then go("lang") end
  end,
}

SCREEN.lang = {
  draw = function()
    frame(2, t("win"))
    center(PY + 3, t("lang_t"), C.text)
    center(PY + 5, t("lang_s"), C.dim)
    local half = math.floor(PW / 2)
    button(PX + half - 21, PY + 8, "Português", S.lang == "pt", function()
      S.lang = "pt"; go("disk")
    end, 19)
    button(PX + half + 2, PY + 8, "English", S.lang == "en", function()
      S.lang = "en"; go("disk")
    end, 19)
    navButtons(function() go("welcome") end)
  end,
  key = function(code)
    if code == 28 then S.lang = "pt"; go("disk")
    elseif code == 14 then go("welcome") end
  end,
}

SCREEN.disk = {
  draw = function()
    frame(3, t("win"))
    center(PY + 1, t("disk_t"), C.text)
    center(PY + 2, t("disk_s"), C.dim)
    local list = disks()
    if #list == 0 then center(PY + 6, t("nodisk"), C.warn) end
    for i, d in ipairs(list) do
      if i > 3 then break end
      local y = PY + 4 + (i - 1) * 3
      local sel = (S.dest == d.addr)
      rect(PX + 2, y, PW - 4, 3, sel and C.redDark or C.btn)
      put(PX + 4, y, (sel and "▶ " or "  ") .. d.name .. (d.ro and ("  [" .. t("ro") .. "]") or ""),
          sel and C.white or C.text, sel and C.redDark or C.btn, PW - 8)
      put(PX + 6, y + 1, fmtKB(d.used) .. " / " .. fmtKB(d.total), C.dim, sel and C.redDark or C.btn)
      table.insert(btns, { x = PX + 2, y = y, w = PW - 4, h = 3, action = function()
        if d.ro then S.msg = t("ro_msg") return end
        S.dest = d.addr; S.label = d.name; S.msg = nil
      end })
    end
    if S.msg then center(PY + 13, S.msg, C.warn) end
    navButtons(function() go("lang") end,
      S.dest and t("next") or nil, function() go("version") end)
  end,
  key = function(code)
    if code == 28 and S.dest then go("version")
    elseif code == 14 then go("lang") end
  end,
}

local VERSIONS = {
  { id = "pro", name = "v_pro", desc = "v_pro_d" },
  { id = "go", name = "v_go", desc = "v_go_d" },
  { id = "plasma", name = "v_plasma", desc = "v_plasma_d" },
}

SCREEN.version = {
  draw = function()
    frame(4, t("win"))
    center(PY + 1, t("ver_t"), C.text)
    center(PY + 2, t("ver_s"), C.dim)
    for i, v in ipairs(VERSIONS) do
      local y = PY + 4 + (i - 1) * 3
      local sel = (S.sel == i)
      rect(PX + 2, y, PW - 4, 3, sel and C.redDark or C.btn)
      put(PX + 4, y, (sel and "▶ " or "  ") .. t(v.name), sel and C.white or C.text, sel and C.redDark or C.btn)
      put(PX + 6, y + 1, t(v.desc), C.dim, sel and C.redDark or C.btn, PW - 10)
      table.insert(btns, { x = PX + 2, y = y, w = PW - 4, h = 3, action = function()
        S.sel = i; S.ver = v.id
      end })
    end
    navButtons(function() go("disk") end, t("next"), function()
      S.ver = VERSIONS[S.sel].id
      go("confirm")
    end)
  end,
  key = function(code)
    if code == 200 and S.sel > 1 then S.sel = S.sel - 1
    elseif code == 208 and S.sel < #VERSIONS then S.sel = S.sel + 1
    elseif code == 28 then S.ver = VERSIONS[S.sel].id; go("confirm")
    elseif code == 14 then go("disk") end
  end,
}

SCREEN.confirm = {
  draw = function()
    frame(5, t("win"))
    center(PY + 1, t("conf_t"), C.text)
    center(PY + 2, t("conf_s"), C.dim)
    local vname = ""
    for _, v in ipairs(VERSIONS) do if v.id == S.ver then vname = t(v.name) end end
    put(PX + 4, PY + 4, t("disk_lbl") .. " " .. (S.label or "-"), C.text, C.panel)
    put(PX + 4, PY + 5, t("ver_lbl") .. " " .. vname, C.text, C.panel)
    if S.ver == "plasma" then
      put(PX + 4, PY + 7, t("plasma_ok"), C.ok, C.panel, PW - 8)
    else
      local dest = S.dest and cl.proxy(S.dest)
      if dest and dest.exists("/init.lua") then
        put(PX + 4, PY + 7, t("init_warn"), C.warn, C.panel, PW - 8)
      end
    end
    local y = PY + 9
    button(PX + 4, y, t("keep_btn"), true, function() run(false) end, PW - 8)
    button(PX + 4, y + 4, t("wipe_btn"), false, function() S.typed = ""; go("wipe") end, PW - 8)
    navButtons(function() go("version") end)
  end,
  key = function(code)
    if code == 28 then run(false)
    elseif code == 14 then go("version") end
  end,
}

SCREEN.wipe = {
  draw = function()
    frame(5, t("win"))
    center(PY + 2, t("wipe_t"), C.red)
    center(PY + 4, string.format(t("wipe_warn"), S.label or "-"), C.text)
    center(PY + 5, string.format(t("wipe_ask"), t("wipe_w")), C.dim)
    rect(PX + 6, PY + 7, PW - 12, 3, C.btn)
    put(PX + 8, PY + 8, S.typed .. "_", C.text, C.btn)
    rule()
    local y = PY + PH - 4
    button(PX + 3, y, t("back"), false, function() go("confirm") end)
    if S.typed:upper() == t("wipe_w") then
      local label = t("wipe_btn")
      local bw = len(label) + 6
      button(PX + PW - bw - 2, y, label, true, function() run(true) end, bw)
    end
  end,
  key = function(code, char)
    if code == 14 then S.typed = S.typed:sub(1, -2)
    elseif code == 28 then
      if S.typed:upper() == t("wipe_w") then run(true) end
    elseif code == 1 then go("confirm")
    elseif char and char >= 32 and char < 127 and #S.typed < 12 then
      S.typed = S.typed .. string.char(char)
    end
  end,
}

SCREEN.install = {
  draw = function()
    frame(6, t("win"))
    center(PY + 2, t("inst_t"), C.text)
  end,
}

SCREEN.error = {
  draw = function()
    frame(6, t("win"))
    center(PY + 3, t("err_t"), C.red)
    local msg = S.err or ""
    local lw = PW - 6
    put(PX + 3, PY + 6, usub(msg, 1, lw), C.text, C.panel, lw)
    if len(msg) > lw then put(PX + 3, PY + 7, usub(msg, lw + 1, 2 * lw), C.dim, C.panel, lw) end
    put(PX + 3, PY + 9, "MX-" .. tostring(S.code or 208), C.warn, C.panel)
    navButtons(function() go("disk") end, t("retry"), function() go("install") end)
  end,
  key = function(code)
    if code == 28 then go("install") elseif code == 14 then go("disk") end
  end,
}

SCREEN.done = {
  draw = function()
    frame(7, t("win"))
    center(PY + 4, t("done_t"), C.ok)
    local left = math.max(0, math.ceil(S.doneAt - cp.uptime()))
    center(PY + 7, string.format(t("done_s"), left), C.dim)
    button(PX + math.floor((PW - 24) / 2), PY + 11, t("restart"), true, function() cp.shutdown(true) end, 24)
  end,
  key = function(code)
    if code == 28 then cp.shutdown(true) end
  end,
}

-- Loop ----------------------------------------------------------------------

local function draw()
  local s = SCREEN[S.screen]
  if s and s.draw then s.draw() end
  if S.screen == "install" then
    -- a instalacao roda uma vez (sem ser interrompida); depois mostra o resultado
    local ok, err, code = install(S.dest, S.ver)
    if ok then
      S.doneAt = cp.uptime() + 10
      go("done")
    else
      S.err = tostring(err)
      S.code = code or 208
      go("error")
    end
    draw()
  end
end

draw()
while true do
  if S.screen == "done" then
    local left = math.max(0, math.ceil(S.doneAt - cp.uptime()))
    if left == 0 then cp.shutdown(true) end
    if left ~= S.last then
      S.last = left
      draw()
    end
  end
  local sig, _, a, b = cp.pullSignal(0.5)
  if sig == "touch" then
    for i = #btns, 1, -1 do
      local bt = btns[i]
      if a >= bt.x and a < bt.x + bt.w and b >= bt.y and b < bt.y + bt.h then
        bt.action()
        break
      end
    end
    draw()
  elseif sig == "key_down" then
    local s = SCREEN[S.screen]
    if s and s.key then s.key(b, a) end
    draw()
  end
end
