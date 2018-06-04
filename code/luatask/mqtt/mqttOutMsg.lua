--- 模块功能：MQTT客户端数据发送处理
-- @author wangziguan
-- @module mqtt.mqttOutMsg
-- @license MIT
-- @copyright wangziguan
-- @release 2018.06.04


module(...,package.seeall)

--数据发送的消息队列
local msgQuene = {}

local function insertMsg(topic,payload,qos,user)
    table.insert(msgQuene,{t=topic,p=payload,q=qos,user=user})
end

--- Online回调函数
local function pubOnlineCb(result)
    log.info("mqttOutMsg.pubOnlineCb",result)
end

--- 上报Online信息
function pubOnline()
    insertMsg("/v1/device"..misc.getImei().."/out","online",1,{cb=pubOnlineCb})
end

--- 初始化“MQTT客户端数据发送”
-- @return 无
-- @usage mqttOutMsg.init()
function init()
    pubOnline()
end

--- 去初始化“MQTT客户端数据发送”
-- @return 无
-- @usage mqttOutMsg.unInit()
function unInit()
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
