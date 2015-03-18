function ChannelStateMachine()
%CHANNELSTATEMACHINE Summary of this function goes here
%   Detailed explanation goes here

% initialise nodes
minNodeNumber = 1;
maxNodeNumber = 5;
packageNumber = 100;

throughput(maxNodeNumber) = 0;
delay(maxNodeNumber) = 0;

for nNodes = minNodeNumber:maxNodeNumber
    fprintf('\nCalculating mean throughput of %d nodes...\n\n', nNodes)
    
    % preallocate memory with empty constructor
    clear nodes;
    nodeList(1,nNodes) = NodeFiniteStateMachine();
    for n=1:nNodes
        nodeList(n) = NodeFiniteStateMachine();
        nodeList(n).sendPackage(100,4);
    end
    
    run = true;
    % results(nodeNumber, packageNumber, 2) = 0;
    slots = 0;
    while run
        slots = slots + 1;
        channelState = 'clear';
        
        throughputSum = 0;
        delaySum = 0;
        ccaFailureSum = 0;
        for node = nodeList
            if strcmp(node.getState(), 'transmission')
                channelState = 'busy';
            end
            % Stop if all nodes are idle
            run = false;
            
            throughputSum = throughputSum + node.getThroughput();
            delaySum = delaySum + node.getDelay();
            ccaFailureSum = ccaFailureSum + node.getNotSend();
            
            if ~strcmp(node.getState(), 'idle')
                run = true;
            end
        end
        
        if ~run
            throughput(nNodes) = (throughputSum / nNodes) /  1000;
            delay(nNodes) = delaySum / nNodes;
            fprintf('CCA Failure sum: %d\n', ccaFailureSum)
            fprintf('Throughput mean: %f\n', throughput(nNodes))
            fprintf('Delay mean: %f\n', delay(nNodes))
        end
        
        for n = 1:nNodes
            nodeList(n).nextStep(channelState);
            if strcmp(nodeList(n).getState(), 'idle')
                packagesSend = nodeList(n).getSend() + nodeList(n).getNotSend();
                if packagesSend <= packageNumber
                    %                         results(n, packagesSend, 1) = slots * 0.000016;
                    %                         results(n, packagesSend, 2) = nodes(n).getThroughput();
                    %nodes(n).reset();
                    nodeList(n).sendPackage(100,4);
                end
            end
        end
    end
end
%    colorstring = 'kbgry';
%     for n = 1:nodeNumber
%         plot(results(n,:,1), results(n,:,2), colorstring(n)); hold on;
%     end
plot(1:maxNodeNumber, throughput);
xlabel('Number of nodes')
ylabel('mean throughput of all nodes [kbits]')
end

