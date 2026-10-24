-- Nitro OS Installer (installer.lua) - visual v2
-- Troque SEU_USUARIO pelo seu usuario do GitHub.
local BASE = "https://raw.githubusercontent.com/pmiguel10766-stack/-opencomputers-script/refs/heads/main/"

local cl, cp = component, computer
local gpu = cl.proxy(cl.list("gpu")())
local screenAddr = cl.list("screen")()
if screenAddr and not gpu.getScreen() then gpu.bind(screenAddr) end
local w, h = gpu.getResolution()
local netAddr = cl.list("internet")()
local net = netAddr and cl.proxy(netAddr) or nil

local ulen = (unicode and unicode.len) or string.len
local usub = (unicode and unicode.sub) or string.sub

---------------------------------------------------------------- cores
local C = {
  bg = 0x050505, panel = 0x1A1A1A, accent = 0xFF2D2D, text = 0xFFFFFF,
  dim = 0xA0A0A0, ok = 0x3DDC84, warn = 0xFFB300, err = 0xFF8A8A,
  barbg = 0x3A3A3A,
}

---------------------------------------------------------------- desenho
local function rect(x, y, rw, rh, bg)
  gpu.setBackground(bg)
  gpu.fill(x, y, rw, rh, " ")
end

local function put(x, y, s, fg, bg, maxw)
  s = tostring(s)
  if maxw and ulen(s) > maxw then s = usub(s, 1, maxw) end
  gpu.setBackground(bg)
  gpu.setForeground(fg)
  gpu.set(x, y, s)
end

local function key()
  while true do
    local ev, _, _, code = cp.pullSignal()
    if ev == "key_down" then return code end
  end
end

-- layout do painel central
local pw = math.min(w - 4, 64)
local px = math.floor((w - pw) / 2) + 1
local py = 4
local ph = math.max(9, math.min(h - 5, 22))
local cx = px + 3
local cw = pw - 6

local function center(y, s, fg, bg)
  put(px + math.floor((pw - ulen(s)) / 2), y, s, fg, bg)
end

local function footer(text)
  rect(1, h, w, 1, C.panel)
  put(2, h, text, C.dim, C.panel, w - 2)
end

---------------------------------------------------------------- logo Nitro OS
-- C listrado + rosto vermelho. x,y = canto superior esquerdo; size = altura em linhas.
local function logoSize()
  return (h >= 24) and 14 or 8
end

local function logoWidth(size)
  return math.floor(size * 1.75 + 0.5)
end

local function drawLogo(x, y, size, bg, stripe)
  local R = size
  local r = math.floor(R * 0.64 + 0.5)
  local arm = math.floor(R * 0.65 + 0.5)

  -- C listrado (uma listra fina por linha)
  gpu.setBackground(bg)
  gpu.setForeground(stripe)
  for ry = 0, R - 1 do
    local dy = (ry + 0.5) * 2 - R
    local left = math.floor(R - math.sqrt(R * R - dy * dy) + 0.5)
    local right
    if math.abs(dy) >= r then
      right = R + arm
    else
      right = math.floor(R - math.sqrt(r * r - dy * dy) + 0.5)
    end
    if right > left then
      gpu.set(x + left, y + ry, string.rep("▀", right - left))
    end
  end

  -- rosto vermelho
  local Rf = math.floor(R * 0.43 + 0.5)
  local fcx = R + math.floor(R * 0.28 + 0.5)
  local red, black = 0xD01818, 0x000000
  local frows = {}
  gpu.setBackground(red)
  for ry = 0, R - 1 do
    local dy = (ry + 0.5) * 2 - R
    if math.abs(dy) < Rf then
      local hw = math.floor(math.sqrt(Rf * Rf - dy * dy) + 0.5)
      if hw > 0 then
        gpu.fill(x + fcx - hw, y + ry, hw * 2, 1, " ")
        frows[#frows + 1] = ry
      end
    end
  end

  local nF = #frows
  if nF >= 2 then
    local eyeRow = frows[nF >= 5 and 2 or 1]
    gpu.setBackground(red)
    gpu.setForeground(black)
    gpu.set(x + fcx - 3, y + eyeRow, ">")
    gpu.set(x + fcx + 2, y + eyeRow, "<")
    gpu.setBackground(black)
    if nF >= 5 then
      gpu.fill(x + fcx - 3, y + frows[4], 7, 1, " ")
      gpu.fill(x + fcx - 2, y + frows[5], 5, 1, " ")
    else
      gpu.fill(x + fcx - 1, y + frows[nF], 3, 1, " ")
    end
  end
end

local function splash(subtitle)
  rect(1, 1, w, h, C.bg)
  local size = logoSize()
  local ly = math.floor((h - (size + 3)) / 2) + 1
  drawLogo(math.floor((w - logoWidth(size)) / 2) + 1, ly, size, C.bg, 0xE6E6E6)
  local name = "NITRO OS"
  put(math.floor((w - ulen(name)) / 2) + 1, ly + size + 1, name, C.text, C.bg)
  if subtitle then
    put(math.floor((w - ulen(subtitle)) / 2) + 1, ly + size + 2, subtitle, C.dim, C.bg)
  end
  cp.pullSignal(1.5)
end

---------------------------------------------------------------- idiomas
local langs = {
  { name = "Português", t = {
    steps = { "Idioma", "HD", "Instalar" },
    chooseDisk = "Escolha do HD",
    noDisk = "Nenhum HD encontrado",
    readonly = "(leitura)",
    diskKeys = "↑↓ Escolher  D Excluir  Enter OK  Bksp Voltar",
    roMsg = "Esse disco é somente leitura",
    wipeAsk = "Apagar TUDO de %s?",
    yn = "[S/N]",
    installing = "Instalando Nitro OS",
    check = "Verificar atualização",
    copy = "Copiar Script Nitro OS",
    noNet = "Sem Internet Card",
    fail = "Falha na instalação",
    failKeys = "Enter Tentar de novo  Bksp Voltar",
    edTitle = "Escolha a versão do Nitro OS",
    edLegacy = "Nitro OS Legado",
    edLegacyDesc = "v6.5, o sistema antigo (arquivo único)",
    edPro = "Nitro OS Pro",
    edProDesc = "Completo: Arquivos, Notas, Impressora 3D, Ajustes",
    edGo = "Nitro OS Go (mais rápido)",
    edGoDesc = "Leve: abre mais rápido, poucos apps e efeitos",
    edKeys = "↑↓ Escolher  Enter OK  Bksp Voltar",
    errTitle = "ERRO FATAL DO SISTEMA",
    errTitleApp = "ERRO NO SISTEMA",
    errContinue = "Enter Continuar",
    errRestart = "Enter Reiniciar",
    e203 = "Sistema corrompido",
    e204 = "Sistema sem RAM",
    e205 = "Falha ao atualizar",
    e206 = "Problema no boot do sistema",
    e207 = "Problema em app ou usuário",
    e208 = "Erro desconhecido",
    done = "Instalação concluída!",
    restartIn = "Reiniciando em %ds",
    restartNow = " Enter  Reiniciar agora ",
    downloading = "Baixando: ",
  } },
  { name = "English", t = {
    steps = { "Language", "Drive", "Install" },
    chooseDisk = "Choose the drive",
    noDisk = "No drive found",
    readonly = "(read-only)",
    diskKeys = "↑↓ Select  D Erase  Enter OK  Bksp Back",
    roMsg = "This drive is read-only",
    wipeAsk = "Erase EVERYTHING on %s?",
    yn = "[Y/N]",
    installing = "Installing Nitro OS",
    check = "Check for updates",
    copy = "Copy Nitro OS files",
    noNet = "No Internet Card",
    fail = "Installation failed",
    failKeys = "Enter Try again  Bksp Back",
    edTitle = "Choose the Nitro OS version",
    edLegacy = "Nitro OS Legacy",
    edLegacyDesc = "v6.5, the old system (single file)",
    edPro = "Nitro OS Pro",
    edProDesc = "Full: Files, Notes, 3D Printer, Settings",
    edGo = "Nitro OS Go (faster)",
    edGoDesc = "Light: boots faster, few apps and effects",
    edKeys = "↑↓ Select  Enter OK  Bksp Back",
    errTitle = "FATAL SYSTEM ERROR",
    errTitleApp = "SYSTEM ERROR",
    errContinue = "Enter Continue",
    errRestart = "Enter Restart",
    e203 = "System corrupted",
    e204 = "System out of RAM",
    e205 = "Update failed",
    e206 = "System boot problem",
    e207 = "App or user problem",
    e208 = "Unknown error",
    done = "Installation complete!",
    restartIn = "Restarting in %ds",
    restartNow = " Enter  Restart now ",
    downloading = "Downloading: ",
  } },
}

local T = langs[1].t

---------------------------------------------------------------- moldura
local function frame(step, title)
  rect(1, 1, w, h, C.bg)
  rect(1, 1, w, 1, C.panel)
  put(2, 1, "◆ NITRO OS", C.accent, C.panel)
  put(13, 1, "Installer", C.dim, C.panel)

  local x = px
  for i, name in ipairs(T.steps) do
    local label = " " .. i .. " " .. name .. " "
    if i == step then
      put(x, 2, label, C.bg, C.accent)
    elseif i < step then
      put(x, 2, label, C.ok, C.bg)
    else
      put(x, 2, label, C.dim, C.bg)
    end
    x = x + ulen(label) + 1
  end

  rect(px, py, pw, ph, C.panel)
  local line = string.rep("─", pw - 2)
  put(px, py, "╭" .. line .. "╮", C.accent, C.panel)
  for r = 1, ph - 2 do
    put(px, py + r, "│", C.accent, C.panel)
    put(px + pw - 1, py + r, "│", C.accent, C.panel)
  end
  put(px, py + ph - 1, "╰" .. line .. "╯", C.accent, C.panel)
  if title then put(px + 2, py, " " .. title .. " ", C.text, C.panel, pw - 6) end
end

---------------------------------------------------------------- tela 1: idioma
local function chooseLanguage()
  local sel = 1
  local function draw()
    frame(1, "Language / Idioma")
    put(cx, py + 2, "Escolha o idioma / Choose your language", C.dim, C.panel, cw)
    for i, l in ipairs(langs) do
      local y = py + 4 + (i - 1) * 2
      if i == sel then
        rect(cx - 1, y, cw + 2, 1, C.accent)
        put(cx, y, "▶ " .. l.name, C.bg, C.accent, cw)
      else
        put(cx, y, "  " .. l.name, C.text, C.panel, cw)
      end
    end
    footer("↑↓ Select / Escolher    Enter OK")
  end
  draw()
  while true do
    local code = key()
    if code == 200 and sel > 1 then
      sel = sel - 1
      draw()
    elseif code == 208 and sel < #langs then
      sel = sel + 1
      draw()
    elseif code == 28 then
      T = langs[sel].t
      return
    end
  end
end

---------------------------------------------------------------- tela 2: HD
local function disks()
  local list = {}
  for addr in cl.list("filesystem") do
    if addr ~= cp.tmpAddress() then
      local fs = cl.proxy(addr)
      list[#list + 1] = {
        addr = addr,
        fs = fs,
        name = fs.getLabel() or addr:sub(1, 4),
        used = math.floor(fs.spaceUsed() / 1024),
        total = math.floor(fs.spaceTotal() / 1024),
        ro = fs.isReadOnly(),
      }
    end
  end
  return list
end

local function wipe(d)
  for _, name in ipairs(d.fs.list("/")) do
    d.fs.remove("/" .. name)
  end
end

local function chooseDisk()
  local list, sel, first = disks(), 1, 1
  local msg, msgColor = "", C.warn
  local rows = math.max(1, math.floor((ph - 5) / 3))

  local function draw()
    frame(2, T.chooseDisk)
    if #list == 0 then put(cx, py + 3, T.noDisk, C.warn, C.panel, cw) end
    if sel < first then first = sel end
    if sel >= first + rows then first = sel - rows + 1 end

    for n = 0, rows - 1 do
      local i = first + n
      local d = list[i]
      if d then
        local y = py + 2 + n * 3
        local selected = (i == sel)
        local bg = selected and C.accent or C.panel
        local fg = selected and C.bg or C.text
        rect(cx - 1, y, cw + 2, 2, bg)

        local name = string.format("HDD %d  %s", i, d.name)
        if d.ro then name = name .. " " .. T.readonly end
        put(cx, y, (selected and "▶ " or "  ") .. name, fg, bg, cw - 14)

        local size = string.format("%d/%d KB", d.used, d.total)
        put(cx + cw - ulen(size), y, size, fg, bg)

        local pct = d.total > 0 and math.floor(d.used * 100 / d.total) or 0
        local bw = cw - 8
        local fillColor = pct > 85 and C.err or (pct > 60 and C.warn or C.ok)
        rect(cx + 2, y + 1, bw, 1, C.barbg)
        rect(cx + 2, y + 1, math.floor(bw * pct / 100), 1, fillColor)
        put(cx + 3 + bw, y + 1, string.format("%3d%%", pct), fg, bg)
      end
    end

    if first > 1 then put(px + pw - 3, py + 1, "▲", C.dim, C.panel) end
    if first + rows <= #list then put(px + pw - 3, py + ph - 4, "▼", C.dim, C.panel) end

    rect(px + 1, py + ph - 3, pw - 2, 1, C.panel)
    put(cx, py + ph - 3, msg, msgColor, C.panel, cw)
    footer(T.diskKeys)
  end

  local function confirm(text)
    msg, msgColor = text .. " " .. T.yn, C.err
    draw()
    local result
    while true do
      local c = key()
      if c == 31 or c == 21 then result = true break end
      if c == 49 then result = false break end
    end
    msg, msgColor = "", C.warn
    return result
  end

  draw()
  while true do
    local code = key()
    local d = list[sel]
    msg, msgColor = "", C.warn
    if code == 200 and sel > 1 then
      sel = sel - 1
    elseif code == 208 and sel < #list then
      sel = sel + 1
    elseif code == 14 then
      return nil
    elseif code == 28 and d then
      if d.ro then msg = T.roMsg else return d.addr end
    elseif code == 32 and d then
      if d.ro then
        msg = T.roMsg
      elseif confirm(string.format(T.wipeAsk, d.name)) then
        wipe(d)
        list = disks()
        sel = math.max(1, math.min(sel, #list))
      end
    end
    draw()
  end
end

---------------------------------------------------------------- download
local function download(path)
  if not net then return nil, T.noNet end
  local url = path:match("^https?://") and path or (BASE .. path)
  local req, err = net.request(url)
  if not req then return nil, tostring(err) end
  local limit = cp.uptime() + 20
  local data = ""
  local ok, e = pcall(function()
    while not req.finishConnect() do
      if cp.uptime() > limit then error("Timeout") end
      cp.pullSignal(0)
    end
    while true do
      local c = req.read(math.huge)
      if not c then break end
      data = data .. c
    end
  end)
  pcall(req.close)
  if not ok then return nil, tostring(e) end
  return data
end

local EDITIONS = {
  { id = "legado", name = "edLegacy", desc = "edLegacyDesc" },
  { id = "pro", name = "edPro", desc = "edProDesc" },
  { id = "go", name = "edGo", desc = "edGoDesc" },
}

local function chooseEdition()
  local sel = 2
  local function draw()
    frame(2, T.edTitle)
    for i, e in ipairs(EDITIONS) do
      local y = py + 2 + (i - 1) * 3
      if i == sel then
        rect(cx - 1, y, cw + 2, 2, C.accent)
        put(cx, y, "▶ " .. T[e.name], C.bg, C.accent, cw)
        put(cx + 2, y + 1, T[e.desc], C.bg, C.accent, cw - 2)
      else
        put(cx, y, "  " .. T[e.name], C.text, C.panel, cw)
        put(cx + 2, y + 1, T[e.desc], C.dim, C.panel, cw - 2)
      end
    end
    footer(T.edKeys)
  end
  draw()
  while true do
    local k = key()
    if k == 200 and sel > 1 then
      sel = sel - 1
      draw()
    elseif k == 208 and sel < #EDITIONS then
      sel = sel + 1
      draw()
    elseif k == 28 then
      return EDITIONS[sel].id
    elseif k == 14 then
      return nil
    end
  end
end

---------------------------------------------------------------- tela 3: instalar
local function bar(y, label, pct)
  local icon, iconColor = "○", C.dim
  if pct >= 100 then
    icon, iconColor = "●", C.ok
  elseif pct > 0 then
    icon, iconColor = "●", C.accent
  end
  put(cx, y, icon, iconColor, C.panel)
  put(cx + 2, y, label, C.text, C.panel, cw - 8)
  put(cx + cw - 4, y, string.format("%3d%%", pct),
    pct >= 100 and C.ok or C.text, C.panel)
  rect(cx, y + 1, cw, 1, C.barbg)
  rect(cx, y + 1, math.floor(cw * pct / 100), 1, pct >= 100 and C.ok or C.accent)
end

local function status(text)
  rect(px + 1, py + ph - 3, pw - 2, 1, C.panel)
  put(cx, py + ph - 3, text, C.dim, C.panel, cw)
end

local LEGACY_URL = "https://raw.githubusercontent.com/pmiguel10766-stack/-opencomputers-script/refs/heads/main/Nitro_OS_Legado.lua"

local function installLegacy(target)
  status(T.downloading .. "Nitro_OS_Legado.lua")
  local data, err = download(LEGACY_URL)
  if not data then return false, tostring(err), 205 end
  bar(py + 3, T.check, 100)
  if #data == 0 or data:sub(1, 3) == "404" or not load(data, "=Nitro_OS_Legado") then
    return false, "Nitro_OS_Legado.lua", 203
  end
  local fs = cl.proxy(target)
  local hnd = fs.open("/init.lua", "w")
  if not hnd then return false, "/init.lua", 205 end
  fs.write(hnd, data)
  fs.close(hnd)
  bar(py + 6, T.copy, 70)
  -- o marcador faz o Legado abrir direto, sem tentar se atualizar sozinho no primeiro boot
  local marker = fs.open("/.nitro_installed", "w")
  if marker then
    fs.write(marker, "installed=true\nlang=PT-BR\nuser=Admin\nurl=" .. LEGACY_URL)
    fs.close(marker)
  end
  bar(py + 6, T.copy, 100)
  status("")
  return true
end

local function install(target, edition)
  frame(3, T.installing)
  footer("Nitro OS")
  bar(py + 3, T.check, 0)
  bar(py + 6, T.copy, 0)
  if cp.freeMemory() < 30000 then
    return false, string.format("RAM livre: %d KB", math.floor(cp.freeMemory() / 1024)), 204
  end
  if edition == "legado" then return installLegacy(target) end
  status(T.downloading .. "files.txt")

  local list, err = download("files.txt")
  if not list or #list == 0 then return false, err or "files.txt", 205 end
  bar(py + 3, T.check, 100)

  local files = {}
  for line in list:gmatch("[^\r\n]+") do
    line = line:match("^%s*(.-)%s*$")
    if #line > 0 then files[#files + 1] = line end
  end
  if #files == 0 then return false, "files.txt", 203 end

  local fs = cl.proxy(target)
  for i, path in ipairs(files) do
    status(T.downloading .. path)
    local data, e = download(path)
    if not data then return false, path .. ": " .. tostring(e), 205 end
    if #data == 0 or data:sub(1, 3) == "404"
        or (path:sub(-4) == ".lua" and not load(data, "=" .. path)) then
      return false, path, 203
    end
    local dir = path:match("^(.*)/[^/]+$")
    if dir then fs.makeDirectory("/" .. dir) end
    local hnd = fs.open("/" .. path, "w")
    if not hnd then return false, path, 205 end
    fs.write(hnd, data)
    fs.close(hnd)
    bar(py + 6, T.copy, math.floor(i * 100 / #files))
  end
  -- grava a edicao escolhida (pro ou go) para o boot.lua ler
  fs.makeDirectory("/nitro")
  local ed = fs.open("/nitro/edition", "w")
  if ed then
    fs.write(ed, edition or "pro")
    fs.close(ed)
  end
  status("")
  return true
end

---------------------------------------------------------------- erro / reinício
local function errorScreen(code, detail)
  local ew = math.min(w - 4, 60)
  local eh = math.min(h - 4, 12)
  local ex = math.floor((w - ew) / 2) + 1
  local ey = math.floor((h - eh) / 2) + 1
  rect(1, 1, w, h, C.bg)
  local line = string.rep("─", ew - 2)
  put(ex, ey, "╭" .. line .. "╮", C.accent, C.bg)
  for r = 1, eh - 2 do
    put(ex, ey + r, "│", C.accent, C.bg)
    put(ex + ew - 1, ey + r, "│", C.accent, C.bg)
  end
  put(ex, ey + eh - 1, "╰" .. line .. "╯", C.accent, C.bg)

  local ix = ex + 3
  local icon = { "┏━     ━┓", "┃ ╲   ╱ ┃", "┃   ╳   ┃", "┃ ╱   ╲ ┃", "┗━     ━┛" }
  for i, row in ipairs(icon) do put(ix, ey + 1 + i, row, C.accent, C.bg) end

  local tx, tw = ix + 12, ew - 17
  put(tx, ey + 2, T.errTitle, C.accent, C.bg, tw)
  put(tx, ey + 3, string.rep("─", tw), C.accent, C.bg)
  put(tx, ey + 4, string.format("MX-%d  %s", code, T["e" .. code] or T.e208),
    C.text, C.bg, tw)
  local text = tostring(detail or ""):gsub("%s+", " ")
  for n = 0, 2 do
    local part = usub(text, n * tw + 1, (n + 1) * tw)
    if ulen(part) > 0 then put(tx, ey + 5 + n, part, C.dim, C.bg, tw) end
  end
  put(ix, ey + eh - 4, string.rep("▞", ew - 6), C.accent, C.bg)
  put(ix, ey + eh - 2, T.failKeys, C.dim, C.bg)

  while true do
    local k = key()
    if k == 28 then return true end
    if k == 14 then return false end
  end
end

local function restartScreen()
  local total = 10
  local start = cp.uptime()
  local shown = -1
  while true do
    local elapsed = math.floor(cp.uptime() - start)
    if elapsed >= total then break end
    if elapsed ~= shown then
      shown = elapsed
      frame(3, T.installing)
      footer("Nitro OS")
      center(py + 2, T.done, C.ok, C.panel)
      center(py + 4, string.format(T.restartIn, total - elapsed), C.text, C.panel)
      rect(cx, py + 6, cw, 1, C.barbg)
      rect(cx, py + 6, math.floor(cw * elapsed / total), 1, C.accent)
      center(py + 8, T.restartNow, C.bg, C.accent)
    end
    local ev, _, _, code = cp.pullSignal(0.2)
    if ev == "key_down" and code == 28 then break end
  end
  cp.shutdown(true)
end

---------------------------------------------------------------- principal
splash("Installer")
while true do
  chooseLanguage()
  while true do
    local target = chooseDisk()
    if not target then break end
    local edition = chooseEdition()
    if edition then
      local ok, err, code = install(target, edition)
      while not ok do
        if not errorScreen(code or 208, err) then break end
        ok, err, code = install(target, edition)
      end
      if ok then
        restartScreen()
        return
      end
    end
  end
end
