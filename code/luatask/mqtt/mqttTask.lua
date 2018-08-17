--- 模块功能：MQTT客户端处理框架
-- @author wangziguan
-- @module mqtt.mqttTask
-- @license MIT
-- @copyright wangziugan    
-- @release 2018.06.04

module(...,package.seeall)

require"misc"
require"mqtt"
require"net"
require"mqttOutMsg"
require"mqttInMsg"

local ready = false

--- MQTT连接是否处于激活状态
-- @return 激活状态返回true，非激活状态返回false
-- @usage mqttTask.isReady()
function isReady()
    return ready
end

--启动MQTT客户端任务
sys.taskInit(
    function()
        while true do
            if not socket.isReady() then
                --等待网络环境准备就绪，超时时间是5分钟
                sys.waitUntil("IP_READY_IND",300000)
            end
            
            if socket.isReady() then
                imei = misc.getImei()
                local will = {
                    qos = 1,
                    retain = 0,
                    topic = "tmuWu35Wo4pJtYh5F/"..imei.."/out",
                    payload = string.fromHex("0430")
                }
                
                --创建一个MQTT客户端
                local mqttClient = mqtt.client(imei,30,"","",0,will)
                --阻塞执行MQTT CONNECT动作，直至成功
                --如果使用ssl连接，打开mqttClient:connect("lbsmqtt.airm2m.com",1884,"tcp_ssl",{caCert="ca.crt"})，根据自己的需求配置
                --mqttClient:connect("lbsmqtt.airm2m.com",1884,"tcp_ssl",{caCert="ca.crt"})
                if mqttClient:connect("mqtt3.heytz.com",2883,"tcp") then
                -- if mqttClient:connect("www.kevincc.com",1883,"tcp") then
                    ready = true
                    --订阅主题
                    if mqttClient:subscribe({["tmuWu35Wo4pJtYh5F/"..imei.."/in"]=1}) then
                        mqttOutMsg.init()
                        --循环处理接收和发送的数据
                        while true do
                            if not mqttInMsg.proc(mqttClient) then log.error("mqttTask.mqttInMsg.proc error") break end
                            if not mqttOutMsg.proc(mqttClient) then log.error("mqttTask.mqttOutMsg proc error") break end
                        end
                        mqttOutMsg.unInit()
                    end
                    ready = false
                end
                --断开MQTT连接
                mqttClient:disconnect()
                sys.wait(5000)
            else
                --进入飞行模式，20秒之后，退出飞行模式
                net.switchFly(true)
                sys.wait(20000)
                net.switchFly(false)
            end
        end
    end
)
