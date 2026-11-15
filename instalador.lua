-- Plasma OS - Instalador (estilo instalador do OS X Yosemite)
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
  text = 0x1A1A1A, sub = 0x6E6E6E, panel = 0xFFFFFF,
  blue = 0x0A84FF, barBg = 0xD6D6D6, white = 0xFFFFFF, red = 0xD93025,
  menuBg = 0xE8E8E8, title = 0xD9D9D9, side = 0xE3E7EC,
  shadow = 0x59636E, rule = 0xD0D0D0,
}

-- Utilidades (acentos e cores) ------------------------------------------

local len = (unicode and unicode.len) or function(s) return #s end
local function usub(s, i, j)
  if unicode and unicode.sub then return unicode.sub(s, i, j) end
  return s:sub(i, j)
end

local function mix(c1, c2, t)
  local r1, g1, b1 = math.floor(c1 / 65536) % 256, math.floor(c1 / 256) % 256, c1 % 256
  local r2, g2, b2 = math.floor(c2 / 65536) % 256, math.floor(c2 / 256) % 256, c2 % 256
  return math.floor(r1 + (r2 - r1) * t) * 65536
       + math.floor(g1 + (g2 - g1) * t) * 256
       + math.floor(b1 + (b2 - b1) * t)
end

-- Tela de carregamento (logo + barra fina) ------------------------------
-- Logo: Júpiter (faixas de cor, Grande Mancha Vermelha, sombra) com um "P" azul
-- 12x12 pixels = 12x6 células com meios-blocos
local ORB_P = {
  "####.",
  "#...#",
  "#...#",
  "####.",
  "#....",
  "#....",
  "#....",
}
local function drawOrb(x0, y0, bg)
  local N = 12
  local R = N / 2 - 0.2
  local cx, cy = (N - 1) / 2, (N - 1) / 2
  local CREAM, ORANGE, RED, PBLUE = 0xF2DDB8, 0xC9803F, 0xB5442E, 0x0A2F6B
  local function glyph(px, py)
    local gx, gy = px - 3, py - 2
    if gx >= 0 and gx < 5 and gy >= 0 and gy < 7 then
      return ORB_P[gy + 1]:sub(gx + 1, gx + 1) == "#"
    end
    return false
  end
  local function pix(px, py)
    local dx, dy = px - cx, py - cy
    local d = math.sqrt(dx * dx + dy * dy)
    if d > R then return nil end
    if glyph(px, py) then return PBLUE end
    local base = (math.sin(py * 1.6) > 0.15) and ORANGE or CREAM
    local sx, sy = px - 8, py - 7                       -- Grande Mancha Vermelha
    if sx * sx / 2.2 + sy * sy / 1.4 < 1 then base = RED end
    local t = d / R                                     -- sombra nas bordas
    return mix(base, 0x2A1A10, t * t * 0.55)
  end
  for cy2 = 0, N / 2 - 1 do
    for cx2 = 0, N - 1 do
      local a, b = pix(cx2, cy2 * 2), pix(cx2, cy2 * 2 + 1)
      if a or b then
        gpu.setBackground(bg)
        if a and b then
          gpu.setForeground(a); gpu.setBackground(b)
          gpu.set(x0 + cx2, y0 + cy2, "▀")
        elseif a then
          gpu.setForeground(a)
          gpu.set(x0 + cx2, y0 + cy2, "▀")
        else
          gpu.setForeground(b)
          gpu.set(x0 + cx2, y0 + cy2, "▄")
        end
      end
    end
  end
end

local SPL = { drawn = false }
local function splash(frac, msg)
  local SW, SH = W, H
  local BG = 0xF2F2F2
  local N = 12
  local x0 = math.floor((SW - N) / 2) + 1
  local y0 = math.max(2, math.floor(SH / 2) - 6)
  if not SPL.drawn then
    SPL.drawn = true
    gpu.setBackground(BG)
    gpu.fill(1, 1, SW, SH, " ")
    drawOrb(x0, y0, BG)
    local title = "Plasma OS"
    gpu.setBackground(BG)
    gpu.setForeground(0x1A1A1A)
    gpu.set(math.floor((SW - len(title)) / 2) + 1, y0 + 8, title)
  end

  -- barra fina de progresso
  local BW = 24
  local bx = math.floor((SW - BW) / 2) + 1
  gpu.setBackground(BG)
  gpu.setForeground(0xD0D0D0)
  gpu.set(bx, y0 + 10, string.rep("▄", BW))
  local filled = math.floor(BW * math.max(0, math.min(1, frac)))
  if filled > 0 then
    gpu.setForeground(0x555555)
    gpu.set(bx, y0 + 10, string.rep("▄", filled))
  end
  if msg then
    gpu.setBackground(BG)
    gpu.fill(1, y0 + 12, SW, 1, " ")
    gpu.setForeground(0x8A8A8A)
    gpu.set(math.floor((SW - len(msg)) / 2) + 1, y0 + 12, msg)
  end
end

-- Textos ----------------------------------------------------------------

local T = {
  pt = {
    steps = { "Introdução", "Idioma", "Destino", "Confirmação", "Instalação", "Resumo" },
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
    eta = "Tempo restante: cerca de %d s",
    error_title = "Erro na instalação", retry = "Tentar novamente",
    done_title = "Instalação concluída",
    done_sub = "O computador reiniciará em %d segundos.",
    restart = "Reiniciar agora",
    wipe_title = "Apagar disco", wipe_word = "APAGAR",
    wipe_warn = "Tudo em \"%s\" será apagado.",
    wipe_ask = "Digite %s para confirmar.",
    has_init = "Já existe um /init.lua aqui; será substituído.",
    boot_next = "O próximo boot será pelo disco %s.",
    menu_app = "Instalador", menu = "Editar   Janela   Ajuda",
  },
  en = {
    steps = { "Introduction", "Language", "Destination", "Confirmation", "Installation", "Summary" },
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
    eta = "Time remaining: about %d s",
    error_title = "Installation error", retry = "Try again",
    done_title = "Installation complete",
    done_sub = "The computer will restart in %d seconds.",
    restart = "Restart now",
    wipe_title = "Erase disk", wipe_word = "ERASE",
    wipe_warn = "Everything on \"%s\" will be erased.",
    wipe_ask = "Type %s to confirm.",
    has_init = "A /init.lua already exists here; it will be replaced.",
    boot_next = "The next boot will be from disk %s.",
    menu_app = "Installer", menu = "Edit   Window   Help",
  },
}

local STEP_OF = { welcome = 1, lang = 2, disk = 3, confirm = 4, wipe = 4, install = 5, error = 5, done = 6 }

local state = { screen = "welcome", lang = "pt" }
local buttons = {}
local P = {}
local t0 = nil

local function t(k, ...)
  local s = T[state.lang][k] or k
  if select("#", ...) > 0 then return string.format(s, ...) end
  return s
end

-- Barra de menu com RAM e bateria ---------------------------------------

local function statusCandidates()
  local total = computer.totalMemory()
  local ram = 0
  if total > 0 then
    ram = math.floor((total - computer.freeMemory()) / total * 100 + 0.5)
  end
  local maxE = computer.maxEnergy()
  local bat = 100
  if maxE > 0 and maxE < math.huge then
    bat = math.floor(computer.energy() / maxE * 100 + 0.5)
  end
  local ok, clk = pcall(os.date, "%H:%M")
  if not ok or not clk then clk = "--:--" end
  local bt = state.lang == "pt" and "Bateria" or "Battery"
  return {
    string.format("RAM: %d%%   %s: %d%%   %s", ram, bt, bat, clk),
    string.format("RAM %d%%  Bat %d%%  %s", ram, bat, clk),
    clk,
  }, bat
end

local function drawMenuBar()
  gpu.setBackground(C.menuBg)
  gpu.setForeground(C.text)
  gpu.fill(1, 1, W, 1, " ")
  local left = "●   " .. t("menu_app") .. "   " .. t("menu")
  gpu.set(2, 1, left)
  local limit = len(left) + 4
  local cands, bat = statusCandidates()
  for _, s in ipairs(cands) do
    local sx = W - len(s)
    if sx > limit then
      gpu.setForeground(bat <= 15 and C.red or C.text)
      gpu.set(sx, 1, s)
      break
    end
  end
end

-- Desenho ---------------------------------------------------------------

local function fmt(n)
  if n >= 1048576 then return string.format("%.1f MB", n / 1048576) end
  return string.format("%d KB", math.floor(n / 1024))
end

local SB = 20  -- largura da barra lateral

local function frame(screen)
  -- céu em degradê
  local rows = H - 1
  local bands = math.min(24, rows)
  for b = 0, bands - 1 do
    local y1 = 2 + math.floor(b * rows / bands)
    local y2 = 2 + math.floor((b + 1) * rows / bands) - 1
    gpu.setBackground(mix(0x4A90D9, 0xCFE3F5, (b + 0.5) / bands))
    gpu.fill(1, y1, W, y2 - y1 + 1, " ")
  end
  drawMenuBar()

  local ww = math.min(84, W - 2)
  local wh = math.min(22, H - 3)
  local wx = math.floor((W - ww) / 2) + 1
  local wy = math.floor((H - wh) / 2) + 1

  -- sombra
  gpu.setBackground(C.shadow)
  gpu.fill(wx + 2, wy + wh, ww, 1, " ")
  gpu.fill(wx + ww, wy + 1, 2, wh, " ")

  -- barra de título
  gpu.setBackground(C.title)
  gpu.fill(wx, wy, ww, 1, " ")
  gpu.setForeground(0xFF5F57); gpu.set(wx + 2, wy, "●")
  gpu.setForeground(0xFEBC2E); gpu.set(wx + 4, wy, "●")
  gpu.setForeground(0x28C840); gpu.set(wx + 6, wy, "●")
  local title = state.lang == "pt" and "Instalar Plasma OS" or "Install Plasma OS"
  gpu.setForeground(C.text)
  gpu.set(wx + math.floor((ww - len(title)) / 2), wy, title)

  -- barra lateral com as etapas
  gpu.setBackground(C.side)
  gpu.fill(wx, wy + 1, SB, wh - 1, " ")
  gpu.setForeground(C.blue)
  gpu.set(wx + 2, wy + 2, "PLASMA OS")
  local cur = STEP_OF[screen or state.screen] or 1
  for i, name in ipairs(T[state.lang].steps) do
    local y = wy + 4 + (i - 1) * 2
    gpu.setForeground(i == cur and C.blue or 0xA0A0A0)
    gpu.set(wx + 2, y, i == cur and "●" or "○")
    gpu.setForeground(i == cur and C.text or C.sub)
    gpu.set(wx + 4, y, name)
  end

  -- painel da direita (onde as telas desenham)
  P.x, P.y, P.w, P.h = wx + SB, wy + 1, ww - SB, wh - 1
  gpu.setBackground(C.panel)
  gpu.fill(P.x, P.y, P.w, P.h, " ")
end

local function center(y, s, fg)
  gpu.setBackground(C.panel)
  gpu.setForeground(fg or C.text)
  gpu.set(P.x + math.floor((P.w - len(s)) / 2), y, s)
end

local function bar(x, y, width, frac, track, fill)
  gpu.setBackground(track or C.barBg)
  gpu.fill(x, y, width, 1, " ")
  local filled = math.floor(width * math.max(0, math.min(1, frac)))
  if filled > 0 then
    gpu.setBackground(fill or C.blue)
    gpu.fill(x, y, filled, 1, " ")
  end
end

local function button(x, y, label, primary, action, w)
  local bw = w or (len(label) + 6)
  gpu.setBackground(primary and C.blue or C.barBg)
  gpu.setForeground(primary and C.white or C.text)
  gpu.fill(x, y, bw, 3, " ")
  gpu.set(x + math.floor((bw - len(label)) / 2), y + 1, label)
  table.insert(buttons, { x = x, y = y, w = bw, h = 3, action = action })
end

-- Botão centralizado no painel
local function cbtn(y, label, primary, action)
  local bw = len(label) + 8
  button(P.x + math.floor((P.w - bw) / 2), y, label, primary, action, bw)
end

-- Linha fina acima dos botões de navegação
local function rule()
  gpu.setBackground(C.panel)
  gpu.setForeground(C.rule)
  gpu.set(P.x, P.y + P.h - 5, string.rep("─", P.w))
end

-- Voltar à esquerda, avançar à direita
local function navButtons(backAction, label, action)
  rule()
  local y = P.y + P.h - 4
  if backAction then button(P.x + 3, y, t("back"), false, backAction) end
  if label then
    local bw = len(label) + 6
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
  frame("install")
  center(P.y + 4, t("install_title"))
  center(P.y + 8, msg, C.sub)
  bar(P.x + 4, P.y + 11, P.w - 8, frac)
  center(P.y + 13, string.format("%d%%", math.floor(frac * 100)), C.sub)
  t0 = t0 or computer.uptime()
  if frac > 0.05 and frac < 1 then
    local el = computer.uptime() - t0
    center(P.y + 15, t("eta", math.ceil(el / frac - el)), C.sub)
  end
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
        hasInit = fs.exists("/init.lua"),
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

-- Clique no disco só seleciona; "Continuar" avança
local function pick(d)
  if d.ro then
    state.msg = t("readonly_msg")
    state.dest = nil
    return
  end
  state.msg = nil
  state.dest = d.addr
  state.label = d.label
  state.hasInit = d.hasInit
end

local function runInstall(doWipe)
  state.doWipe = doWipe
  t0 = nil
  local ok, err = install(state.dest, doWipe)
  if ok then
    state.doneAt = computer.uptime() + 5
    state.lastLeft = nil
    pcall(computer.beep, 880, 0.1)
    state.bootSet = pcall(computer.setBootAddress, state.dest)
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
    local sel = state.dest == d.addr
    gpu.setBackground(sel and C.blue or C.panel)
    gpu.fill(P.x + 2, y, P.w - 4, 3, " ")
    gpu.setForeground(sel and C.white or C.text)
    local tag = d.ro and ("  [" .. t("readonly") .. "]") or ""
    gpu.set(P.x + 3, y, "▐█▌ " .. d.label .. tag)
    gpu.setForeground(sel and C.white or C.sub)
    gpu.set(P.x + 7, y + 1, fmt(d.used) .. " / " .. fmt(d.total))
    bar(P.x + 7, y + 2, P.w - 12, d.total > 0 and d.used / d.total or 0,
      sel and mix(C.blue, C.white, 0.4) or C.barBg,
      sel and C.white or C.blue)
    table.insert(buttons, {
      x = P.x + 2, y = y, w = P.w - 4, h = 3,
      action = function() pick(d) end,
    })
  end

  if state.msg then center(P.y + 14, state.msg, C.red) end
  navButtons(function() go("lang") end,
    state.dest and t("next") or nil,
    function() go("confirm") end)
end

local function drawConfirm()
  center(P.y + 3, t("confirm_title"))
  center(P.y + 5, state.label or "", C.sub)
  center(P.y + 6, t("confirm_sub"), C.sub)
  if state.hasInit then center(P.y + 7, t("has_init"), C.red) end
  cbtn(P.y + 9, t("wipe_yes"), true, function()
    state.typed = ""
    go("wipe")
  end)
  cbtn(P.y + 12, t("install_only"), false, function() runInstall(false) end)
  cbtn(P.y + 15, t("cancel"), false, function() go("disk") end)
end

local function drawWipe()
  local word = t("wipe_word")
  center(P.y + 3, t("wipe_title"), C.red)
  center(P.y + 5, t("wipe_warn", state.label or ""), C.text)
  center(P.y + 6, t("wipe_ask", word), C.sub)
  gpu.setBackground(C.barBg)
  gpu.setForeground(C.text)
  gpu.fill(P.x + 6, P.y + 8, P.w - 12, 3, " ")
  gpu.set(P.x + 8, P.y + 9, (state.typed or "") .. "_")
  rule()
  local y = P.y + P.h - 4
  button(P.x + 3, y, t("back"), false, function() go("confirm") end)
  if (state.typed or ""):upper() == word then
    local label = t("wipe_yes")
    local bw = len(label) + 6
    button(P.x + P.w - bw - 2, y, label, true, function() runInstall(true) end, bw)
  end
end

local function drawError()
  center(P.y + 4, t("error_title"), C.red)
  local msg = state.err or ""
  local lw = P.w - 6
  center(P.y + 7, usub(msg, 1, lw), C.text)
  if len(msg) > lw then
    center(P.y + 8, usub(msg, lw + 1, 2 * lw), C.sub)
  end
  rule()
  local y = P.y + P.h - 4
  button(P.x + 3, y, t("back"), false, function() go("disk") end)
  local label = t("retry")
  local bw = len(label) + 6
  button(P.x + P.w - bw - 2, y, label, true, function() runInstall(state.doWipe) end, bw)
end

local function drawDone()
  local left = math.max(0, math.ceil(state.doneAt - computer.uptime()))
  center(P.y + 4, t("done_title"))
  center(P.y + 7, t("done_sub", left), C.sub)
  if state.bootSet then
    center(P.y + 9, t("boot_next", state.label or ""), C.sub)
  end
  cbtn(P.y + 11, t("restart"), true, function() computer.shutdown(true) end)
end

local drawers = {
  welcome = drawWelcome, lang = drawLang, disk = drawDisk,
  confirm = drawConfirm, wipe = drawWipe, error = drawError, done = drawDone,
}

local function draw()
  buttons = {}
  frame()
  drawers[state.screen]()
end

-- Loop ------------------------------------------------------------------

-- Tela de carregamento: confere o que o instalador vai usar
splash(0.1, "Iniciando instalador...")
computer.pullSignal(0.3)
local nDisks = #listDisks()
splash(0.45, "Procurando discos... (" .. nDisks .. ")")
computer.pullSignal(0.3)
local hasNet = proxyOf("internet") ~= nil
splash(0.8, hasNet and "Rede encontrada." or "Sem placa de rede.")
computer.pullSignal(0.3)
splash(1, "Pronto.")
computer.pullSignal(0.4)

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
    if state.screen == "wipe" then
      state.typed = state.typed or ""
      if b == 14 then                                -- Backspace
        state.typed = state.typed:sub(1, -2)
      elseif b == 28 or b == 156 then                -- Enter
        if state.typed:upper() == t("wipe_word") then runInstall(true) end
      elseif a and a >= 32 and a < 127 and #state.typed < 12 then
        state.typed = state.typed .. string.char(a)
      end
      draw()
    elseif b == 28 and state.screen == "welcome" then  -- Enter
      go("lang")
      draw()
    end
  end
  drawMenuBar()  -- mantém RAM, bateria e hora atualizadas
end
