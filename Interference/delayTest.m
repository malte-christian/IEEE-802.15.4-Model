function logData = delayTest()

addpath StateMachines

% Test Configurations %

config = struct('minNodeNumber', 3,...
                'maxNodeNumber', 3);

% global halper variables for sending behavior
stopNoise = false;
payload = 0;

% node sending behavior
    function nodeSendHook(node, slot)
        switch node.getId()
            case 1  % delay test with increasing payload
                packetsSend = node.getSend();
                if packetsSend < 110
                    if mod(packetsSend,10) == 0
                        payload = packetsSend; % packetsSend [0-109]
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

hookHandle = @nodeSendHook;  % create a function handle

logData = ChannelStateMachine(config, hookHandle);

%    colorstring = 'kbgry';
%     for n = 1:nodeNumber
%         plot(results(n,:,1), results(n,:,2), colorstring(n)); hold on;
%     end
% 
% plot(1:config.maxNodeNumber, throughputLog);
% xlabel('Number of nodes')
% ylabel('mean throughput of all nodes [kbits]')

end
