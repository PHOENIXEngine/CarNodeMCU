-- CarControl

--GPIO Define
function initGPIO()
--1,2EN 	D1 GPIO5
--3,4EN 	D2 GPIO4
--1A  ~2A   D3 GPIO0
--3A  ~4A   D4 GPIO2

gpio.mode(0,gpio.OUTPUT);--LED Light on
gpio.write(0,gpio.LOW);

gpio.mode(1,gpio.OUTPUT);gpio.write(1,gpio.LOW);
gpio.mode(2,gpio.OUTPUT);gpio.write(2,gpio.LOW);

gpio.mode(3,gpio.OUTPUT);gpio.write(3,gpio.HIGH);
gpio.mode(4,gpio.OUTPUT);gpio.write(4,gpio.HIGH);

pwm.setup(1,1000,1023);--PWM 1KHz, Duty 1023
pwm.start(1);pwm.setduty(1,0);
pwm.setup(2,1000,1023);
pwm.start(2);pwm.setduty(2,0);
end

function setupAPMode()
print("Ready to start soft ap")
	
cfg={}
cfg.ssid="DoitWiFi";
cfg.pwd="12345678"
wifi.ap.config(cfg)

cfg={}
cfg.ip="192.168.1.1";
cfg.netmask="255.255.255.0";
cfg.gateway="192.168.1.1";
wifi.ap.setip(cfg);
wifi.setmode(wifi.SOFTAP)

str=nil;
ssidTemp=nil;
collectgarbage();

print("Soft AP started")
end

--Set up AP
setupAPMode();

print("Start CarNodeMCU_APMode Control");
initGPIO();

spdTargetA=1023;--target Speed
spdCurrentA=0;--current speed
spdTargetB=1023;--target Speed
spdCurrentB=0;--current speed
stopFlag=true;

--speed control procedure
tmr.alarm(1, 200, 1, function()
	if stopFlag==false then
		spdCurrentA=spdTargetA;
		spdCurrentB=spdTargetB;
		pwm.setduty(1,spdCurrentA);
		pwm.setduty(2,spdCurrentB);
	else
		pwm.setduty(1,0);
		pwm.setduty(2,0);
	end
end)

function processData(strMsg, msgDataIDLength)
	local msgID = string.byte(strMsg, 3, 3)
	local msg = string.sub(strMsg, 4, 4+msgDataIDLength-1)
	local msgLen = string.len(msg)
	print("msg:"..msg)
	if "w" == msg then
		gpio.write(3,gpio.HIGH)
		gpio.write(4,gpio.HIGH)
		stopFlag = false;
	elseif "s" == msg then
		gpio.write(3,gpio.LOW)
		gpio.write(4,gpio.LOW)
		stopFlag = false;
	elseif "a" == msg then
		gpio.write(3,gpio.LOW)
		gpio.write(4,gpio.HIGH)
		stopFlag = false;
	elseif "d" == msg then
		gpio.write(3,gpio.HIGH);
		gpio.write(4,gpio.LOW);
		stopFlag = false;
	elseif "x" == msg then
		pwm.setduty(1,0)
		pwm.setduty(2,0)
		stopFlag = true;
	end
end

recvStr = ""
--Setup tcp server at port 9003
s=net.createServer(net.TCP,60);
s:listen(9003,function(c) 
	print("listen")
    c:on("receive",function(c,d)
	  recvStr = recvStr..d
	  local dStrLen = string.len(d)
	  local recvStrLen = string.len(recvStr)
	  if recvStrLen > 2 then
		local curMsgLength0 = string.byte(recvStr, 1, 1) 
		local curMsgLength1 = string.byte(recvStr, 2, 2)
		local curMsgLength =  curMsgLength0 + curMsgLength1* 256
		if recvStrLen >= (curMsgLength+2) then
			-- now we get the whole package
			processData(recvStr, curMsgLength)
			recvStr = string.sub(recvStr, curMsgLength+2, recvStrLen-(curMsgLength+2))
		end
	  end
	  collectgarbage();
    end) --end c:on receive

    c:on("disconnection",function(c) 
		print("TCPSrv:Client disconnet");
		collectgarbage();
    end) 
    print("TCPSrv:Client connected")
end)