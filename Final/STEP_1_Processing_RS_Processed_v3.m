% Load processed file
load(input_path);

% Correct delay
EEG = correctDelay(EEG, 22);

% Correct DINs
EEG.event = cleanTriggers_v3(EEG.event);

% Calculate fractal dimensions and save the output to Excel spreadsheet
% Prepare table for output; allocate memory
tableOutput = struct2table(EEG.event);
% Remove columns introduced by automagic
tableOutput.value = [];
tableOutput.duration = [];
for jChan = 1:size(EEG.chanlocs, 2)
    tableOutput(1, strcat(EEG.chanlocs(jChan).labels, '_CD')) = {0};
    tableOutput(1, strcat(EEG.chanlocs(jChan).labels, '_PK')) = {0};
    tableOutput(1, strcat(EEG.chanlocs(jChan).labels, '_FNNB')) = {0};
    tableOutput(1, strcat(EEG.chanlocs(jChan).labels, '_D')) = {0};
    tableOutput(1, strcat(EEG.chanlocs(jChan).labels, '_LE')) = {0};
    tableOutput(1, strcat(EEG.chanlocs(jChan).labels, '_HFD')) = {0};
    for iMSE = 1:20
        tableOutput(1, strcat(EEG.chanlocs(jChan).labels, '_MSE_', num2str(iMSE))) = {0};
    end
    tableOutput(1, strcat(EEG.chanlocs(jChan).labels, '_MFDFA_DQFIRST')) = {0};
    tableOutput(1, strcat(EEG.chanlocs(jChan).labels, '_MFDFA_MAXDQ')) = {0};
    tableOutput(1, strcat(EEG.chanlocs(jChan).labels, '_MFDFA_DQLAST')) = {0};
    tableOutput(1, strcat(EEG.chanlocs(jChan).labels, '_MFDFA_MAXMIN')) = {0};
    tableOutput(1, strcat(EEG.chanlocs(jChan).labels, '_KC')) = {0};
end
% We process EOEC (RS) only
% EOEC;
eventVec = 1:3;

% Iterate through events
for iEvent = eventVec
    % Extract epochs
    if size(tableOutput,1) <= 5
        switch iEvent
            case 1 % [DIN1 - 15000 DIN1 + 15000],
                tempDataAll = EEG.data(:, EEG.event(2).latency - 15000:EEG.event(2).latency + 15000);
            case 2 % [DIN1-30000 DIN1]
                tempDataAll = EEG.data(:, EEG.event(2).latency - 30000:EEG.event(2).latency);
            case 3 % [DIN1 DIN1 + 30000]
                tempDataAll = EEG.data(:, EEG.event(2).latency:EEG.event(2).latency + 30000);
        end
    end
    
    % Store results in this matrix for parallel processing purposes
    resultMat = zeros(size(EEG.chanlocs, 2), 31);
    
    % Select channels accroding to flag1020
    channelVec = []; % Initiate the variable
    if flag1020 == 1
        channelVec = [7, 9, 12, 17, 19, 26, 29, 38, 43, 48, 58, 69, ...
            77, 80, 87, 90, 102, 104];
        % Channel 105 (Cz) is not included as it is vector of zeros
    else
        channelVec = 1:size(EEG.chanlocs,2);
    end
    
    % Iterate thorugh channels
    for jChan = 1:size(EEG.chanlocs, 2)
        tic;
        % Check if channel was selected and if it was rejected by
        % automagic
        if sum(channelVec==jChan)==1 && sum(automagic.autoBadChans==jChan)==0
            % CD, PK, FNNB, D
            tic;
            uf = 1; % Use fnn
            tt = 0; % Measure time - tic toc
            prt = 0; % Print results
            [CD, PK, FNNB, D] = fcnEMBED_v3(downsample(tempDataAll(jChan,:), downsampleRate), uf, tt, prt);
            time_CD_PK = time_CD_PK + toc;
            
            % Lyapunov Spectrum
            tic;
            LE = fcnLE(downsample(tempDataAll(jChan,:)', downsampleRate), 1);
            time_LE = time_LE + toc;
            
            % Higuchi FD
            tic;
            kmax = 5;
            HFD = fcnHFD(downsample(tempDataAll(jChan,:), downsampleRate), kmax);
            time_LE = time_LE + toc;
            
            % MSE
            tic;
            MSE = zeros(1, 20);
            for i = 1:20
                [MSE(i), ~, ~] = fcnSE(downsample(tempDataAll(jChan,:), downsampleRate)/i,...
                    3, 0.2, 1, i);
            end
            time_MSE = time_MSE + toc;
            
            % MFDFA
            scmin = 16;
            scmax = 1024;
            scres = 19;
            exponents = linspace(log2(scmin),log2(scmax),scres);
            scale = round(2.^exponents);
            q = linspace(-5,5,101);
            m = 1;
            
            tic;
            [Hq,tq,hq,Dq,Fq] = fcnMFDFA(downsample(tempDataAll(jChan,:), downsampleRate), scale, q, m, 0);
            time_MFDFA = time_MFDFA + toc;
            
            % Remove NaN and Inf in Dq and hq
            hq = hq(~isnan(hq) | ~isinf(hq));
            Dq = Dq(~isnan(Dq) | ~isinf(Dq));
            % Create vector for storing outputs
            MFDFA = zeros(1,4);
            if (~isempty(hq) && ~isempty(Dq))
                MFDFA(1) = Dq(1);
                MFDFA(2) = max(Dq);
                MFDFA(3) = Dq(end);
                MFDFA(4) = max(hq)-min(hq);
            end
            
            % KC
            tic;
            KC = fcnKC(downsample(tempDataAll(jChan,:),downsampleRate)...
                >= median(downsample(tempDataAll(jChan,:),downsampleRate)));
            time_KC = time_KC + toc;
            
            % Store results
            if FNNB==0
                FNNB = 1.0000e-16; % To avoid deleting the column later in the code
            end
            
            resultMat(jChan,:) = [CD, PK, FNNB, D, LE, HFD, MSE, MFDFA, KC];
        end
        
        % Show progress
        if rem(jChan, 10) == 1
            disp([' Channel: ', num2str(jChan)])
        end
        
        % Show times
        disp([' CD_PK: ', num2str(time_CD_PK),...
            ' LE: ', num2str(time_LE),...
            ' MSE: ', num2str(time_MSE),...
            ' MFDFA: ', num2str(time_MFDFA),...
            ' KC: ', num2str(time_KC),...
            ' total time: ', num2str(toc(time_tot)),...
            ' [secs]'])
    end
    
    % Save output to a table
    resultMatT = resultMat';
    tableOutput{iEvent, 4:4 + 105*31 - 1} = resultMatT(:)';
    
    % Perform a checksum and display
    disp(['check nansum: ', num2str(nansum(resultMat(:)))])
    
    % Save length of epoch
    tableOutput(iEvent, 'Epoch_length') = {size(tempDataAll,2)};
    disp([' Event: ', num2str(iEvent)])
end % loop for events

% Save output to Excel spreadsheet for checking and futher processing
% Leave only columns which have at least one non-zero value
tableOutput = tableOutput(:,4:end);
tableOutput = tableOutput(:,~all(tableOutput{:,:}==0));


