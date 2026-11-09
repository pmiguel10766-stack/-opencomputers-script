local c,p=component,computer
local B="https://raw.githubusercontent.com/pmiguel10766-stack/Atualizar_Nitro_OS/main/"
local L=B.."BIOS/BIOS_GUI.lua"
local I="https://raw.githubusercontent.com/pmiguel10766-stack/-opencomputers-script/refs/heads/main/installer.lua"
local HASH=3012683437
local G=c.list("gpu")()
local S=c.list("screen")()
local g=G and c.proxy(G)
if g and S then g.bind(S) end
local W,H=80,25
if g then W,H=g.getResolution() end
local function hash(s)
  local h=0
  for i=1,#s do h=(h*31+s:byte(i))%4294967296 end
  return h
end
local function msg(t,col)
  if not g then return end
  g.setBackground(0) g.fill(1,1,W,H," ")
  g.setForeground(col or 0xFFFFFF)
  g.set(math.max(1,math.floor((W-#t)/2)+1),math.floor(H/2),t)
end
local function get(u)
  local n=c.list("internet")()
  if not n then return nil,"Sem Internet Card" end
  local r,e=c.proxy(n).request(u)
  if not r then return nil,tostring(e) end
  local t=p.uptime()+15
  while not r.finishConnect() do
    if p.uptime()>t then r.close() return nil,"Tempo esgotado" end
    p.pullSignal(0)
  end
  local a={}
  while true do
    local x=r.read(math.huge)
    if not x then break end
    a[#a+1]=x
  end
  r.close()
  local d=table.concat(a)
  if d:sub(1,3)=="404" then return nil,"Nao encontrado no GitHub" end
  return d
end
local function wr(f,path,d)
  local h=f.open(path,"w")
  if not h then return false end
  f.write(h,d) f.close(h)
  return true
end
local function repair()
  local a=p.getBootAddress()
  local f=a and c.proxy(a)
  if not f or f.isReadOnly() then return "Disco sem gravacao." end
  local i,e1=get(B.."init.lua")
  if not i or #i<100 then return "Falha init.lua: "..tostring(e1) end
  local b,e2=get(B.."nitro/boot.lua")
  if not b or #b<100 then return "Falha boot.lua: "..tostring(e2) end
  f.makeDirectory("/nitro")
  if not wr(f,"/init.lua",i) or not wr(f,"/nitro/boot.lua",b) then return "Falha ao gravar." end
  return "Reparado. Reinicie."
end
local function installer()
  local d,e=get(I)
  if not d then return "Falha instalador: "..tostring(e) end
  local f,er=load(d,"=i")
  if not f then return "Erro instalador: "..tostring(er) end
  pcall(f)
  return ""
end
local function bootDisk()
  local a=p.getBootAddress()
  local o={a}
  for x in c.list("filesystem") do
    if x~=a then o[#o+1]=x end
  end
  for _,x in ipairs(o) do
    local f=c.proxy(x)
    if f.exists("/init.lua") then
      local h,d=f.open("/init.lua"),""
      repeat
        local k=f.read(h,math.huge)
        d=d..(k or "")
      until not k
      f.close(h)
      p.setBootAddress(x)
      local fn,e=load(d,"=init")
      if not fn then return "Erro init.lua: "..tostring(e) end
      fn()
      return nil
    end
  end
  return "Nenhum disco com /init.lua."
end
local function layout()
  local d,e=get(L)
  if not d then return "Layout indisponivel: "..tostring(e) end
  if hash(d)~=HASH then return "Layout recusado: verificacao falhou." end
  local f,er=load(d,"=layout")
  if not f then return "Layout com erro: "..tostring(er) end
  local ok,fn=pcall(f)
  if not ok or type(fn)~="function" then return "Layout invalido." end
  local api={gpu=g,w=W,h=H,cp=p,version="1.0",verified=true,
    bootAddr=function() return p.getBootAddress() end,
    hasInternet=function() return c.list("internet")()~=nil end,
    boot=bootDisk,repair=repair,installer=installer,
    reboot=function() p.shutdown(true) end,
    shutdown=function() p.shutdown(false) end}
  local ok2,e2=pcall(fn,api)
  if not ok2 then return "Erro no layout: "..tostring(e2) end
  return nil
end
msg("Nitro BIOS",0xFF2D2D)
local k
local t=p.uptime()+3
while p.uptime()<t do
  local ev,_,_,code=p.pullSignal(0.2)
  if ev=="key_down" and (code==67 or code==68) then k=code break end
end
local r
if k==67 then r=layout() elseif k==68 then r=repair() end
if r and r~="" then
  msg(r,0xFFFF55)
  p.pullSignal(3)
end
local err=bootDisk()
if err then
  msg(err,0xFF5555)
  while true do p.pullSignal(1) end
end
