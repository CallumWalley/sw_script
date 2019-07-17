%% launch.m
% Provides a wrapper for the other scripts. I don't like typing more than necessary.

%% This will suppress al Matlab warnings
warning('off','all')

%% Add path to use EEGLAB Matlab functions; Change path to your local copy of EEGLab
addpath(genpath('../eeglab14_1_2b/'));

%% Flag indicating number of channels for processing
% If flag1020 = 1 then we process only 10/20 channels according to p. 7 in HydroCelGSN_10-10.pdf
% If flag1020 = 0 then we process all channels accordingly.
flag1020 = 1;  

%% Flag indicating whether to use FIR
% If flagFiltered = 1 then FIR is applied.
% If flagFiltered = 0 then FIR is not used.
flagFiltered = 0; 

%% Downsample rate only samples every x values to reduce computation time for testing. Make '1' for max.
if exist('downsampleRate', 'var')
    disp(['downsampleRate = ', num2str(downsampleRate)])
else
    downsampleRate = 1;
    disp(['downsampleRate not set... will use ', num2str(downsampleRate)])
end

% time stats
time_CD_PK = 0;
time_LE = 0;
time_MSE = 0;
time_MFDFA = 0;
time_KC = 0;
time_tot = tic;

disp(['Input= ',input_path]);

%RUN FUNCTION HERE
run(script_name);

disp(output_path);

%Remove Tempfile
delete(output_path);

% Save to xlsx spreadsheet
writetable(tableOutput, output_path, 'Sheet', 1, 'Range', 'A1');

% Time stats
disp([' CD_PK_v2 timing: ', num2str(time_CD_PK),...
    ' MFDFA timing: ', num2str(time_MFDFA),...
    ' total time: ', num2str(toc(time_tot)),...
    ' [secs]']);
