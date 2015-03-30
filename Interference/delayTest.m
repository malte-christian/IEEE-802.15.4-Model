function [delayArray, logDataCell] = delayTest()

addpath StateMachines

% Test Configurations %

config = struct('minNodeNumber', 5,...
    'maxNodeNumber', 5);

% global halper variables for sending behavior
stopNoise = false;
payload = 0;

% node sending behavior
    function nodeSendHook(node, slot)
        switch node.getId()
            case 1  % delay test with increasing payload
                packetsSend = node.getSend();
                if packetsSend < 1300
                    if mod(packetsSend,100) == 0
                        payload = packetsSend / 10; % packetsSend [0-109]
                    end
                    node.sendPacket(slot, payload, 4, true);
                else
                    stopNoise = true;
                end
                if packetsSend == 0
                    stopNoise = false; % reset at start
                end
            otherwise  % make some noise...
                if ~stopNoise
                    node.sendPacket(slot, 100, 4, true);
                end
        end
    end

hookHandle = @nodeSendHook;  % register as function handle

logDataCell = ChannelStateMachine(config, hookHandle);

delayArray(13, 1) = 0;

for i = 0:100:1200
    delayArray(fix((i + 100) / 100)) =...
        mean(logDataCell{config.maxNodeNumber}{1}.delay((i + 1) : (i + 100)));
end

plot(delayArray)

end
