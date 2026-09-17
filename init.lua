-- ===================================================
--    NITRO OS v6.5 - SPECIAL SECRETS & CMD EDITION
-- ===================================================

local component = require("component")
local computer = require("computer")
local event = require("event")
local filesystem = require("filesystem")

local function analyzeHardware()
  local gpuOk = component.isAvailable("gpu")
  if not gpuOk then return false end
  return true
end

if not analyzeHardware() then return end

local gpu = component.gpu
local isInstalled = filesystem.exists("/.nitro_installed")
local installStep = 1
local selectedLang = "PT-BR"

local rawUpdateUrl = "https://raw.githubusercontent.com/pmiguel10766-stack/-opencomputers-script/main/init.lua"

gpu.setResolution(80, 25)
local maxW, maxH = 80, 25

-- Cores do Sistema
local COLOR_BG       = 0x101014
local COLOR_CARD     = 0x1B1B22
local COLOR_ACCENT   = 0x00E676  -- Verde Nitro
local COLOR_TEXT     = 0xFFFFFF
local COLOR_SUBTEXT  = 0x6E6E7E
local COLOR_MENU_BG  = 0x15151C
local COLOR_RED      = 0xB71C1C
local COLOR_C_STRIPE = 0x22222E

-- LOGO "CO" MINIMALISTA
local function drawCOLogo(cx, cy)
  gpu.setBackground(COLOR_BG)
  gpu.setForeground(COLOR_C_STRIPE)
  gpu.set(cx - 15, cy - 3, "------------------------")
  gpu.set(cx - 15, cy - 2, "|                      |")
  gpu.set(cx - 15, cy - 1, "|  ||||||||||||||||||  |")
  gpu.set(cx - 15, cy,     "|  ||")
  gpu.set(cx - 15, cy + 1, "|  ||")
  gpu.set(cx - 15, cy + 2, "|  ||")
  gpu.set(cx - 15, cy + 3, "|  ||")
  gpu.set(cx - 15, cy + 4, "|  ||")
  gpu.set(cx - 15, cy + 5, "|  ||||||||||||||||||  |")
  gpu.set(cx - 15, cy + 6, "|                      |")
  gpu.set(cx - 15, cy + 7, "------------------------")

  gpu.setBackground(COLOR_RED)
  gpu.setForeground(COLOR_TEXT)
  gpu.fill(cx + 1, cy, 9, 5, " ")
  gpu.set(cx + 3, cy + 1, ">  <")
  gpu.set(cx + 3, cy + 3, "\\__/")
end

-- TELA DE BOOT
local function showOfficialBootScreen(statusMsg)
  gpu.setBackground(COLOR_BG)
  gpu.fill(1, 1, maxW, maxH, " ")
  local cx, cy = math.floor(maxW / 2) - 2, 6
  drawCOLogo(cx, cy)
  local barX, barY, barWidth = cx - 18, cy + 10, 40
  gpu.setBackground(COLOR_BG)
  gpu.setForeground(COLOR_SUBTEXT)
  gpu.set(barX, barY - 1, string.format("%-36s", statusMsg or "Carregando..."))
  gpu.setBackground(0x08080A)
  gpu.fill(barX, barY, barWidth, 1, " ")
  for pct = 0, 100, 5 do
    local filled = math.floor((barWidth * pct) / 100)
    if filled > 0 then
      gpu.setBackground(COLOR_ACCENT)
      gpu.fill(barX, barY, filled, 1, " ")
    end
    gpu.setBackground(COLOR_BG)
    gpu.setForeground(COLOR_ACCENT)
    gpu.set(barX + barWidth + 2, barY, string.format("%3d%%", pct))
    os.sleep(0.01)
  end
  os.sleep(0.1)
end
