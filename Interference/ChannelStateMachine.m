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
        % node.sendPacket(100,4);
    end
    
    % Reset variables
    run = true;
    slot = 0;
    
    while run
        clear maxSleepSlots;
        
        slot = slot + 1;
        channelState = 'clear';
        run = false;
         
        % Determine current channel state
        for node = nodeList
            if strcmp(node.getState(), 'transmission')
                channelState = 'busy';
            end
        end
        
        % Determine next channel state
        for node = nodeList
            node.nextStep(slot, channelState);
            
            % Invoke next transmission
            if strcmp(node.getState(), 'idle')
                packetsSend = node.getSend()...
                    + node.getNotSend();
                if packetsSend <= packetNumber
                    node.sendPacket(slot, 100, 4, true);
                end
            end
            
            % Stop if all nodes are idle
           
            if ~strcmp(node.getState(), 'idle')
                run = true;
            end
            
            %  Determine max sleep slots
            if ~exist('maxSleepSlots', 'var')...
                    || node.getMaxSleepSlots(slot) < maxSleepSlots
                maxSleepSlots = node.getMaxSleepSlots(slot);
            end
        end
        
        % sleep...
        slot = slot + maxSleepSlots;
        
        % Make CLI Ouput after test run
        if ~run
            ccaFailureSum = 0;
            througputSum = 0;
            for node = nodeList
                througputSum = througputSum + node.getThroughput();
                ccaFailureSum = ccaFailureSum + node.getNotSend();
            end
            throughputLog(nNodes) = througputSum / nNodes;
            fprintf('Throughput mean: %f kbits\n', throughputLog(nNodes))
            fprintf('CCA Failure sum: %d\n', ccaFailureSum)
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

