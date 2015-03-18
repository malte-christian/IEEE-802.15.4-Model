function ChannelStateMachine()
%CHANNELSTATEMACHINE Summary of this function goes here
%   Detailed explanation goes here
   
    % initialise nodes
    minNodeNumber = 1;
    maxNodeNumber = 5;
    packageNumber = 100;
    
    throughput(maxNodeNumber) = 0;
    delay(maxNodeNumber) = 0;
    
    for nodeNumber = minNodeNumber:maxNodeNumber
        fprintf('\nCalculating mean throughput of %d nodes...\n\n', nodeNumber)
        
        % preallocate memory with empty constructor
        clear nodes;
        nodes(1,nodeNumber) = NodeFiniteStateMachine();
        for n=1:nodeNumber
            nodes(n) = NodeFiniteStateMachine();
            nodes(n).sendPackage(100,4);
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
            for node = nodes
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
                throughput(nodeNumber) = (throughputSum / nodeNumber) /  1000;
                delay(nodeNumber) = delaySum / nodeNumber;
                fprintf('CCA Failure sum: %d\n', ccaFailureSum)
                fprintf('Throughput mean: %f\n', throughput(nodeNumber))
                fprintf('Delay mean: %f\n', delay(nodeNumber))
            end
            
            for n = 1:nodeNumber 
                nodes(n).nextStep(channelState);
                if strcmp(nodes(n).getState(), 'idle')
                    packagesSend = nodes(n).getSend() + nodes(n).getNotSend();
                    if packagesSend <= packageNumber
%                         results(n, packagesSend, 1) = slots * 0.000016;
%                         results(n, packagesSend, 2) = nodes(n).getThroughput();
                        %nodes(n).reset();
                        nodes(n).sendPackage(100,4);
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

