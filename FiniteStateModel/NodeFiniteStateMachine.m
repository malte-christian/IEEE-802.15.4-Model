classdef NodeFiniteStateMachine < handle
    %NODECLASS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        transfered = 0;
        state;
        TTrans;
        TBo;
        currentPayload = 0;
        BE = 3;
        maxBE = 5;
        slots = 0;
        TS = 0.000016;
        SymbolsPerSlot = 4;
        RData = 250 *1000;
        send = 0;
        notSend = 0;
        maxCSMABackoffs = 4;
        CSMABackoffs = 0;
        LPhy     = 6; % Length of the PHY header
        LMac_Hdr = 3; % Length of the MAC header
        LMac_Ftr = 2; % Length of the MAC footer
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
        
        function nextStep(obj, channelState)
            nextStep = obj.state;
            switch obj.state
                case 'cca'
                    obj.slots = obj.slots + 1;
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
                    obj.slots = obj.slots + 1;
                    obj.TBo = obj.TBo - 1;
                    if obj.TBo <= 0
                        nextStep = 'cca';
                    end
                case 'transmission'
                    obj.slots = obj.slots + 1;
                    obj.TTrans = obj.TTrans - 1;
                    if obj.TTrans <= 0
                        nextStep = 'idle';
                        obj.send = obj.send + 1;
                        obj.transfered = obj.transfered + obj.currentPayload;
                    end
            end
            obj.state = nextStep;
        end
        
        function sendPackage(obj, payload, addressLength)
            obj.state = 'backoff';
            obj.setBackOffTime();
            obj.setTransmissionTime(payload, addressLength);
            obj.currentPayload = payload;
        end
        
        function setBackOffTime(obj)
            rng('shuffle'); % kann auch weg
            TBoSlots = @(TS) 20; % Time for a back off slot
            BE = min(obj.BE + obj.CSMABackoffs, obj.maxBE);
            obj.TBo = randi([0 (2^BE -1)]) * TBoSlots(obj.TS);
            % obj.TBo = 3.5 * TBoSlots(obj.TS);
        end
        
        function setTransmissionTime(obj,payload, addressLength)
            
            % Frame delay
            TFrame = @(x, RData, LAddress) 8 * (obj.LPhy + obj.LMac_Hdr + LAddress + x + obj.LMac_Ftr ) / obj.SymbolsPerSlot;
            % Acknowledgement delay
            TAck = @(RData) 8 * (obj.LPhy + obj.LMac_Hdr + obj.LMac_Ftr) / obj.SymbolsPerSlot;
            
            % Inter frame space delay
            function y = TIfs(x, TS, LAddress)
                LIFS = @(TS) 40; % Long inter frame space
                SIFS = @(TS) 12; % Short inter frame space
                if (obj.LPhy + obj.LMac_Hdr + LAddress + x + obj.LMac_Ftr <= 18) % CHECKEN! (ist nur geraten)
                    y = SIFS(TS);
                else
                    y = LIFS(TS);
                end
            end
            TTa = @(TS) 12; % Tournaround time
            
            obj.TTrans = TFrame(payload, obj.RData, addressLength) + TAck(obj.RData) + TIfs(payload, obj.TS, addressLength) + TTa(obj.TS);
        end
        
        function TP = getThroughput(obj)
            TP = 8 * obj.transfered / (obj.slots * obj.TS);
        end
        
        function delay = getDelay(obj)
            delay = (obj.slots * obj.TS) / obj.send;
        end
    end
end

