--- 模块功能：MQTT客户端数据发送处理
-- @author wangziguan
-- @module mqtt.mqttOutMsg
-- @license MIT
-- @copyright wangziguan
-- @release 2018.06.04


module(...,package.seeall)

--加载常用的全局函数至本地
local ssub,schar,smatch,sbyte,slen = string.sub,string.char,string.match,string.byte,string.len

--数据发送的消息队列
local msgQuene = {}

local function insertMsg(topic,payload,qos,user)
    table.insert(msgQuene,{t=topic,p=payload,q=qos,user=user})
end

--- pub01回调函数
local function pub01Cb(result)
    log.info("mqttOutMsg.pub01Cb",result)
end

--- 上报pub01信息
function pub01()
    insertMsg("/v1/device/"..imei.."/out", func.hexstobins("0101"), 1, {cb=pub01Cb})
end

--- pub02回调函数
local function pub02Cb(result)
    log.info("mqttOutMsg.pub02Cb",result)
end

--- 上报pub02信息
function pub02()
    insertMsg("/v1/device/"..imei.."/out", func.hexstobins("0201"), 1, {cb=pub02Cb})
end

--[[
函数名：ver2hex
功能  ：版本号转换成十六进制字符串
参数  ：版本号ver
返回值：十六进制字符串hexs	
]]
local function ver2hexs(ver)
	local hexs = ""
    --确保输入为字符串
    if ver == nil or type(ver) ~= "string" then return nil,"nil input string" end
    --字符串模式为x.x.x，其中x为数字，例如2.1.23
    local v1, v2, v3 = smatch(ver, "(%d+)%.(%d+)%.(%d+)")
    --确保版本号正确  
    if v1==nil or v2==nil or v3==nil then return nil,"error input version!" end
	--合成一个大字符串，每个版本号用0填充缺失位
    local ver_string = string.format("%02u", tonumber(v1))
    ver_string = ver_string..string.format("%02u", tonumber(v2))
    ver_string = ver_string..string.format("%02u", tonumber(v3))
    --转换成16进制
    for i=1,slen(ver_string) do
        elem = ssub(ver_string,i,i)
        hexs = hexs..string.format("%02X",sbyte(elem))
    end
	
	return hexs
end

--- Online回调函数
local function pubOnlineCb(result)
    log.info("mqttOutMsg.pubOnlineCb",result)
end

--- 上报Online信息
function pubOnline()
    insertMsg("/v1/device/"..imei.."/out", func.hexstobins("0431"..ver2hexs(_G.VERSION)), 1, {cb=pubOnlineCb})
end

--- 初始化“MQTT客户端数据发送”
-- @return 无
-- @usage mqttOutMsg.init()
function init()
    pubOnline()
    timer=sys.timerLoopStart(pub01,600000)
end

--- 去初始化“MQTT客户端数据发送”
-- @return 无
-- @usage mqttOutMsg.unInit()
function unInit()
    sys.timerStopAll()
    while #msgQuene>0 do
        local outMsg = table.remove(msgQuene,1)
        if outMsg.user and outMsg.user.cb then outMsg.user.cb(false,outMsg.user.para) end
    end
end

--- MQTT客户端是否有数据等待发送
-- @return 有数据等待发送返回true，否则返回false
-- @usage mqttOutMsg.waitForSend()
function waitForSend()
    return #msgQuene > 0
end

--- MQTT客户端数据发送处理
-- @param mqttClient，MQTT客户端对象
-- @return 处理成功返回true，处理出错返回false
-- @usage mqttOutMsg.proc(mqttClient)
function proc(mqttClient)
    while #msgQuene>0 do
        local outMsg = table.remove(msgQuene,1)
        local result = mqttClient:publish(outMsg.t,outMsg.p,outMsg.q)
        if outMsg.user and outMsg.user.cb then outMsg.user.cb(result,outMsg.user.para) end
        if not result then return end
    end
    return true
end
