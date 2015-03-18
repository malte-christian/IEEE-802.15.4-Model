function ChannelStateMachine()

% initialise nodes
minNodeNumber = 1;
maxNodeNumber = 5;
packetNumber = 100;

throughputLog(maxNodeNumber) = 0;
delayLog(maxNodeNumber) = 0;

for nNodes = minNodeNumber:maxNodeNumber
    fprintf('\nCalculating mean throughput of %d nodes...\n\n', nNodes)
    
    clear nodeList;
    
    % preallocate memory with empty constructor
    nodeList(1,nNodes) = NodeFiniteStateMachine(); %#ok<AGROW>
    
    for n=1:nNodes
        nodeList(n) = NodeFiniteStateMachine(); %#ok<AGROW>
        nodeList(n).sendPacket(100,4);
    end
    
    % Reset variables
    run = true;
    slot = 0;
    
    while run
        clear maxSleepSlots;
        
        slot = slot + 1;
        channelState = 'clear';
        
        % Determine current channel state
        for node = nodeList
            if strcmp(node.getState(), 'transmission')
                channelState = 'busy';
            end
            
            throughputSum = throughputSum + node.getThroughput();
            delaySum = delaySum + node.getDelay();
            ccaFailureSum = ccaFailureSum + node.getNotSend();
            
            % Stop if all nodes are idle
            run = false;  
            if ~strcmp(node.getState(), 'idle')
                run = true;
            end
        end
        
        % Determine next channel state
        for n = 1:nNodes
            nodeList(n).nextStep(slot, channelState);
            
            % Invoke next transmission
            if strcmp(nodeList(n).getState(), 'idle')
                packetsSend = nodeList(n).getSend()...
                    + nodeList(n).getNotSend();
                if packetsSend <= packetNumber
                    nodeList(n).sendPacket(100,4);
                end
            end
            
            %  Determine max sleep slots
            if ~exists('maxSleepSlots', 'var')...
                    || nodeList(n).getMaxSleepSlots(slot) < maxSleepSlots
               maxSleepSlots = nodeList(n).getMaxSleepSlots(slot);
            end
        end
        
        % sleep...
        slot = slot + maxSleepSlots;
        
        % Make CLI Ouput after test run
        if ~run
            throughputLog(nNodes) = (throughputSum / nNodes) /  1000;
            delayLog(nNodes) = delaySum / nNodes;
            fprintf('CCA Failure sum: %d\n', ccaFailureSum)
            fprintf('Throughput mean: %f\n', throughputLog(nNodes))
            fprintf('Delay mean: %f\n', delayLog(nNodes))
        end
    end
end

%    colorstring = 'kbgry';
%     for n = 1:nodeNumber
%         plot(results(n,:,1), results(n,:,2), colorstring(n)); hold on;
%     end
plot(1:maxNodeNumber, throughputLog);
xlabel('Number of nodes')
ylabel('mean throughput of all nodes [kbits]')
end

