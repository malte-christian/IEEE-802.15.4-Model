function logDataCell =  ChannelStateMachine(config, nodeSendHook)
                  
logDataCell = cell(config.maxNodeNumber, 1);

for nNodes = config.minNodeNumber:config.maxNodeNumber
    fprintf('\nCalculating mean throughput of %d nodes...\n\n', nNodes)
    
    clear nodeList;
    
    % preallocate memory with empty constructor
    nodeList(1,nNodes) = NodeFiniteStateMachine(); %#ok<AGROW>
    
    for n=1:nNodes
        nodeList(n) = NodeFiniteStateMachine(n);
    end
    
    % Reset variables
    run = true;
    slot = 0;
    
    % prepare logData
    logDataCell{nNodes} = cell(nNodes, 1);
    
    while run
        clear maxSleepSlots;
        
        slot = slot + 1;
        channelState = 'clear';
        run = false;
        
        % Determine current channel state
        for node = nodeList
            if strcmp(node.getState(), 'transmission') || strcmp(node.getState(), 'ACK')
                channelState = 'busy';
            end
        end
        
        % Determine next channel state
        for node = nodeList
            node.nextStep(slot, channelState);
            
            % Invoke next transmission
            if strcmp(node.getState(), 'idle')
                nodeSendHook(node, slot);  % defined above for better readability
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
            throughoutSum = 0;
            delaySum = 0;
            
            for node = nodeList
                
                throughoutList = node.getThroughput();
                delayList = node.getDelay();
                
                throughoutSum = throughoutSum + mean(throughoutList);
                delaySum = delaySum + mean(delayList);
                ccaFailureSum = ccaFailureSum + node.getNotSend();
            
                if node.getId() ~= 0
                    logDataCell{nNodes}{node.getId()} = struct('throughput',...
                                                        throughoutList,...
                                                        'delay',...
                                                        delayList);
                end
            end
            
            fprintf('Throughput mean: %f kbits\n', throughoutSum / nNodes)
            fprintf('Delay mean: %f s\n', delaySum / nNodes)
            fprintf('CCA Failure sum: %d\n', ccaFailureSum)
        end
    end
end

end

