--- 模块功能：MQTT客户端数据接收处理
-- @author wangziguan
-- @module mqtt.mqttInMsg
-- @license MIT
-- @copyright wangziguan
-- @release 2018.06.04

module(...,package.seeall)
local ssub,schar,smatch,sbyte,slen = string.sub,string.char,string.match,string.byte,string.len

--- MQTT客户端数据接收处理
-- @param mqttClient，MQTT客户端对象
-- @return 处理成功返回true，处理出错返回false
-- @usage mqttInMsg.proc(mqttClient)
function proc(mqttClient)
    local result,data
    while true do
        result,data = mqttClient:receive(2000)
        --接收到数据
        if result then
            log.info("mqttInMsg.proc",data.topic,string.toHex(data.payload))
                
            --TODO：根据需求自行处理data.payload
            if data.topic == "tmuWu35Wo4pJtYh5F/"..misc.getImei().."/in" then
                local payload = string.toHex(data.payload)
                --确保payload格式正确
                if payload == nil then log.info("PAYLOAD ERROR!") return end
                log.info("payload = ", payload)
                --获取控制字
                local cmd=ssub(payload,1,2)
                --根据控制字处理
                if cmd=="10" and ssub(payload,3)=="FF" then mqttOutMsg.pub01() 
                elseif cmd=="20" and ssub(payload,3)=="01" then mqttOutMsg.pub02()
                else log.info("CMD NOT SUPPORT!") end
            end
           
            --如果mqttOutMsg中有等待发送的数据，则立即退出本循环
            if mqttOutMsg.waitForSend() then return true end
        else
            break
        end
    end
	
    return result or data=="timeout"
end
