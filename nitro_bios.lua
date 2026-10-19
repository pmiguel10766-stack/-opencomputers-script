local c,p=component,computer
local B="https://raw.githubusercontent.com/pmiguel10766-stack/Atualizar_Nitro_OS/main/init.lua"
local G=c.list("gpu")()
local function halt()while true do p.pullSignal()end end
local function say(t)
if not G then return end
local g=c.proxy(G)
local s=c.list("screen")()
if s and not g.getScreen()then g.bind(s)end
local w,h=g.getResolution()
g.setBackground(0x050505)
g.fill(1,1,w,h," ")
g.setForeground(0xFF2D2D)
g.set(2,2,"NITRO BIOS")
g.setForeground(0xFFFFFF)
g.set(2,4,tostring(t))
end
local function run(d)
local f,e=load(d,"=init")
if not f then say(e)halt()end
f()
halt()
end
local function try(a)
if not a or c.type(a)~="filesystem" then return end
local fs=c.proxy(a)
local h=fs.open("/init.lua")
if not h then return end
local d=""
repeat local x=fs.read(h,math.huge)d=d..(x or "")until not x
fs.close(h)
p.setBootAddress(a)
run(d)
end
try(p.getBootAddress())
for a in c.list("filesystem")do
if a~=p.tmpAddress()then try(a)end
end
say("Baixando...")
local n=c.list("internet")()
if not n then say("Sem Internet Card")halt()end
local r,e=c.proxy(n).request(B)
if not r then say(e)halt()end
local t=p.uptime()+20
while not r.finishConnect()do
if p.uptime()>t then say("Tempo esgotado")halt()end
p.pullSignal(0)
end
local d=""
while true do
local x=r.read(math.huge)
if not x then break end
d=d..x
end
r.close()
run(d)
