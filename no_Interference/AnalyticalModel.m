function [result] = AnalyticalModel()
% Constants (in Byte)
LPhy     = 6; % Length of the PHY header
LMac_Hdr = 3; % Length of the MAC header
LMac_Ftr = 2; % Length of the MAC footer

% Variables
TS       = 0.000016;   % Slot length (in seconds)
LAddress = 4;          % Length of the MAC address info field (in byte)
BoSlots  = 3.5;        % Number of back off slots
RData    = 250 * 1000; % Raw data rate (Bit per second)

% Delays %

TTa      = @(TS) 12 * TS; % Tournaround time
LIFS     = @(TS) 40 * TS; % Long inter frame space
SIFS     = @(TS) 12 * TS; % Short inter frame space
TBoSlots = @(TS) 20 * TS; % Time for a back off slot

function y = checkSize(x, LAddress)
    if (LMac_Hdr + LAddress + x + LMac_Ftr > 127)
        y = NaN;
    else
        y = 1;
    end
end

% Frame delay
TFrame = @(x, RData, LAddress) 8 ...
    * (LPhy + LMac_Hdr + LAddress + x + LMac_Ftr) / RData;

% Acknowledgement delay
TAck = @(RData) 8 * (LPhy + LMac_Hdr + LMac_Ftr) / RData;

% Back off period delay
TBo = BoSlots * TBoSlots(TS);

% Inter frame space delay
function y = TIfs(x, TS, LAddress)
    if (LPhy + LMac_Hdr + LAddress + x + LMac_Ftr <= 18)
        y = SIFS(TS);
    else
        y = LIFS(TS);
    end
end

% Delay in total
delay = @(x, RData, TS, LAddress) (TBo + TFrame(x, RData, LAddress)...
    + TTa(TS) + TAck(RData) + TIfs(x, TS, LAddress))...
    * checkSize(x, LAddress);

% Throughput
TP = @(x, RData, TS, LAddress) 8 * x / delay(x, RData, TS, LAddress);

% Bandwidth efficiency
efficiency = @(x, RData, TS, LAddress) TP(x, RData, TS, LAddress)/RData;

intEnd = 120;
result = zeros(1, intEnd);
for i = 1:1:intEnd
    result(i) = delay(i, RData, TS, LAddress);
end
delay (110, RData, TS, LAddress)

plot(1:1:intEnd, result)
end