function EEG = correctDelay(EEG, delaySize)
%Corrects trigger latencies to account for the netstation amp delay.
%Inputs:    EEG = EEG structure produced by eeglab
%           delaySize = size of the timing delay in milliseconds
%Outputs:   EEG = updated EEG structure for eeglab

%Converts ms delay to sampling point delay
samplingRateFix = 1000/EEG.srate;
adjustedDelaySize = delaySize/samplingRateFix;

%Move trigger latencies by required number of data points
for i = 1:size(EEG.event,2)
    EEG.event(i).latency = EEG.event(i).latency + adjustedDelaySize;
end

end