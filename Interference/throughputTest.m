function [throughputArray, logDataCell] = throughputTest()

addpath StateMachines

% Test Configurations %
payload = 110;
ack = true;

config = struct('minNodeNumber', 1,...
    'maxNodeNumber', 5);

% node sending behavior
    function nodeSendHook(node, slot)
        if node.getSend() < 100
            node.sendPacket(slot, payload, 4, ack);
        end
    end

hookHandle = @nodeSendHook;  % register as function handle

logDataCell = ChannelStateMachine(config, hookHandle);

throughputArray(config.maxNodeNumber, 1) = 0;

for i = config.minNodeNumber:config.maxNodeNumber 
    temp(i) = 0;
    for j = 1:i
        temp(j) = mean(logDataCell{i}{j}.throughput());
    end
    throughputArray(i) = mean(temp);
end

plot(throughputArray)

plot(1:config.maxNodeNumber, throughputArray);
xlabel('Number of nodes')
ylabel('mean throughput of all nodes [kbits]')

end
