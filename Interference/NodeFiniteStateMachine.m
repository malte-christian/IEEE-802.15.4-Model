classdef NodeFiniteStateMachine < handle
    
    properties(Constant)
        BE = 3;
        maxBE = 5;
        SymbolsPerSlot = 4;
        RData = 250 * 1000;
        maxCSMABackoffs = 4;
        TS = 0.000016; % Time per Slot
        LPhy = 6; % Length of the PHY header
        LMac_Hdr = 3; % Length of the MAC header
        LMac_Ftr = 2; % Length of the MAC footer
        LIFS = 40; % Long inter frame space
        SIFS = 12; % Short inter frame space
        TTa = 12; % Tournaround slots
        TBoSlots = 20; % Number of back off slot
    end
    
    properties
        logData = [];
        transfered = 0;
        state = 'idle';
        stateStartSlot = 0;
        stateEndSlot = 0;
        TTrans;
        TBo;
        currentPayload = 0;
        slots = 0;
        send = 0;
        notSend = 0;
        CSMABackoffs = 0;
    end
    
    methods
        function send = getSend(obj)
            send = obj.send;
        end
        
        function notSend = getNotSend(obj)
            notSend = obj.notSend;
        end
        
        function reset(obj)
            obj.transfered = 0;
            obj.slots = 0;
            obj.CSMABackoffs = 0;
        end
        
        function state = getState(obj)
            state = obj.state;
        end
        
        function nextStep(obj, slot, channelState)
            nextStep = obj.state;
            switch obj.state
                case 'cca'
                    if strcmp(channelState, 'clear')
                        nextStep = 'transmission';
                    else
                        obj.CSMABackoffs = obj.CSMABackoffs + 1;
                        if obj.CSMABackoffs > obj.maxCSMABackoffs
                            obj.notSend = obj.notSend + 1;
                            nextStep = 'idle';
                        else
                            nextStep = 'backoff';
                            obj.setBackOffTime();
                        end
                    end
                case 'backoff'
                    if slot - obj.stateStartSlot >= obj.TBo
                        nextStep = 'cca';
                    end
                case 'transmission'
                    if slot - obj.stateStartSlot >= obj.TTrans
                        nextStep = 'idle';
                        obj.send = obj.send + 1;
                        obj.transfered = obj.transfered + obj.currentPayload;
                    end
            end
            
            if ~strcmp(obj.state, nextStep)
                obj.state = nextStep;
                obj.stateStartSlot = slot + 1;
            end
        end
        
        function sleepSlots = getMaxSleepSlots(obj, slot)
            slot = slot + 1; % calculating for next slot
            
            switch obj.state
                case 'backoff'
                    sleepSlots = obj.stateStartSlot + obj.TBo - slot;
                case 'transmission'
                    sleepSlots = obj.stateStartSlot + obj.TTrans - slot;
                otherwise
                    sleepSlots = 0;
            end
            
        end
        
        function sendPacket(obj, payload, addressLength, ack)
            obj.state = 'backoff';
            obj.setBackOffTime();
            obj.setTransmissionTime(payload, addressLength, ack);
            obj.currentPayload = payload;
        end
        
        function setBackOffTime(obj)
            rng('shuffle'); % kann auch weg
            BE = min(obj.BE + obj.CSMABackoffs, obj.maxBE); %#ok<PROP>
            obj.TBo = randi([0 (2^BE -1)]) * obj.TBoSlots; %#ok<PROP>
            % obj.TBo = 3.5 * TBoSlots(obj.TS);
        end
        
        function setTransmissionTime(obj,payload, addressLength, ack)
            
            % Frame delay
            TFrame = @(x, RData, LAddress) 8 * ...
                (obj.LPhy + obj.LMac_Hdr + LAddress + x + obj.LMac_Ftr )...
                / obj.SymbolsPerSlot;
            
            % Acknowledgement delay
            TAck = @(RData) 8 * (obj.LPhy + obj.LMac_Hdr + obj.LMac_Ftr)...
                / obj.SymbolsPerSlot;
            
            % Inter frame space delay
            function y = TIfs(x, LAddress)
                if (obj.LPhy + obj.LMac_Hdr + LAddress + x...
                        + obj.LMac_Ftr <= 18) % TODO: CHECKEN! (ist nur geraten)
                    y = obj.SIFS;
                else
                    y = obj.LIFS;
                end
            end
            
            obj.TTrans = TFrame(payload, obj.RData, addressLength)...
                + TIfs(payload, addressLength) + obj.TTa;
            
            if ack
                obj.TTrans = obj.TTrans + + TAck(obj.RData);
            end
        end
        %
        %         function TP = getThroughput(obj)
        %             TP = 8 * obj.transfered / (obj.slots * obj.TS);
        %         end
        %
        %         function delay = getDelay(obj)
        %             delay = (obj.slots * obj.TS) / obj.send;
        %         end
    end
end

