EEG = pop_readegi(input_path, [], [], 'auto');

% Correct delay 
    EEG = correctDelay(EEG, 22);

    % Edit channel locations 
    myChanLocs = 'GSN-HydroCel-129.sfp';
    EEG = pop_chanedit(EEG, 'load', {myChanLocs 'filetype' 'autodetect'},'setref',{'4:128' 'Cz'},'changefield',{132 'datachan' 0});

    % Re-reference and add 'Cz' back to the data
    EEG = pop_reref( EEG, [], 'refloc', struct('labels',{'Cz'},'Y',{0},'X',{5.4492e-16},'Z',{8.8992},'sph_theta',{0},'sph_phi',{90},'sph_radius',{8.8992},'theta',{0},'radius',{0},'type',{''},'ref',{'Cz'},'urchan',{132},'datachan',{0}));

    % Filter the data; 0.1 for low and 50 for high
    if flagFiltered == 1
        EEG = pop_eegfiltnew(EEG, 0.1,50,33000,0,[],1);    
    end
    
    % Correct DINs
    EEG.event = cleanTriggers_v3(EEG.event);

    % Plot for checking
    %pop_eegplot( EEG, 1, 1, 1);

    % Run ICA
    %EEG = pop_runica(EEG, 'extended',1,'interupt','on');

    % Use for checking consistency of dataset
    EEG = eeg_checkset(EEG);

    %% Save dataset; 
    %EEG = pop_saveset( EEG, 'filename',strrep(filename,'.RAW','RS.set'),'filepath',filepathName);

    % Calculate fractal dimensions and save the output to Excel spreadsheet
    % Prepare table for output; allocate memory
    tableOutput = struct2table(EEG.event);
    for jChan = 1:size(EEG.chanlocs,2)
        tableOutput(1, strcat(EEG.chanlocs(jChan).labels,'_CD')) = {0}; 
        tableOutput(1, strcat(EEG.chanlocs(jChan).labels,'_PK')) = {0}; 
        tableOutput(1, strcat(EEG.chanlocs(jChan).labels,'_FNNB')) = {0}; 
        tableOutput(1, strcat(EEG.chanlocs(jChan).labels,'_D')) = {0}; 
        tableOutput(1, strcat(EEG.chanlocs(jChan).labels,'_LE')) = {0}; 
        tableOutput(1, strcat(EEG.chanlocs(jChan).labels,'_HFD')) = {0}; 
        for iMSE = 1:20
            tableOutput(1, strcat(EEG.chanlocs(jChan).labels, '_MSE_', num2str(iMSE))) = {0}; 
        end
        tableOutput(1, strcat(EEG.chanlocs(jChan).labels,'_MFDFA_DQFIRST')) = {0}; 
        tableOutput(1, strcat(EEG.chanlocs(jChan).labels,'_MFDFA_MAXDQ')) = {0}; 
        tableOutput(1, strcat(EEG.chanlocs(jChan).labels,'_MFDFA_DQLAST')) = {0}; 
        tableOutput(1, strcat(EEG.chanlocs(jChan).labels,'_MFDFA_MAXMIN')) = {0}; 
        tableOutput(1, strcat(EEG.chanlocs(jChan).labels, '_KC')) = {0}; 
    end
    %% We process RS, BCST and RMET 
    % Check if RMET and then iterate through DIN8 events [DIN8 DIN8]
    % Check if BCST and then iterate through [DIN1 DIN4(8)+100]
    % Check if RS and then iterate through [DIN1 - 2500 DIN1 + 2500], [DIN1 - 5000 DIN1], [DIN1 DIN1 + 5000]
    
    % Initialise vector with events for processing
    eventVec = []; 
    disp(['Run type = ', filename(end-1:end)])
    switch filename(end-1:end)
    case 'et' % RMET
        disp('RMET file selected.')
        eventVec = find(arrayfun(@(x) strcmp(x.type, 'DIN8'), EEG.event));
    case 'st' % BCST
        disp('BCST file selected.')
        eventVec = find(arrayfun(@(x) strcmp(x.type, 'DIN1'), EEG.event));
    case 'rs' %RS
        disp('RS file selected.')
        eventVec = find(arrayfun(@(x) strcmp(x.type, 'DIN1') || strcmp(x.type, 'DIN0'), EEG.event));
    otherwise
        disp('TYPE OF FILE NOT RECOGNISED - FILENAMES MUST END WITH rs, bcst or rmet. ')
        return
    end

    %% Iterate through events
    for iEvent = eventVec
        % Extract epochs
        switch filename(end-1:end)
            case 'et' % RMET
                tempDataAll = EEG.data(:, EEG.event(iEvent).latency:EEG.event(iEvent + 1).latency);
            case 'st' % BCST
                tempDataAll = EEG.data(:, EEG.event(iEvent).latency:EEG.event(iEvent + 1).latency+100);
            case 'rs' %RS
                switch iEvent
                    case 1 % [DIN1 - 2500 DIN1 + 2500],
                         tempDataAll = EEG.data(:, EEG.event(2).latency - 2500:EEG.event(2).latency + 2500);
                    case 2 % [DIN1 - 5000 DIN1]
                         tempDataAll = EEG.data(:, EEG.event(2).latency - 5000:EEG.event(2).latency);
                    case 3 % [DIN1 DIN1 + 5000]
                         tempDataAll = EEG.data(:, EEG.event(2).latency:EEG.event(2).latency + 5000);
                end
        end
  
        % Store results in this matrix for parallel processing purposes
        resultMat = zeros(size(EEG.chanlocs, 2), 31);
           
        % Select channels accroding to flag1020
        channelVec = []; % Initiate the variable
        if flag1020 == 1
            channelVec = [36, 104, 129, 24, 124, 33, 122, 22, 9, 14, 21, ...
                15, 11, 70, 83, 52, 92, 58, 96, 45, 108];
        else
            channelVec = 1:size(EEG.chanlocs, 2);
        end
            
        for jChan = 1:size(EEG.chanlocs, 2)
            tic;
            
            if sum(channelVec==jChan)==1
                % CD, PK, FNNB, D
                tic;
                uf = 1; % Use fnn
                tt = 0; % Measure time - tic toc
                prt = 0; % Print results
                [CD, PK, FNNB, D] = fcnEMBED_v3(downsample(tempDataAll(jChan,:),downsampleRate),uf,tt,prt); 
                time_CD_PK = time_CD_PK + toc;	

                % Lyapunov Spectrum
                tic;
                LE = fcnLE(downsample(tempDataAll(jChan,:)',downsampleRate),1);
                time_LE = time_LE + toc;	
                
                % Higuchi FD
                tic;
                kmax = 5;
                HFD = fcnHFD(downsample(tempDataAll(jChan,:),downsampleRate), kmax);
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
                % Check if enough length of signal is available
                if length(downsample(tempDataAll(jChan,:),downsampleRate)) >= 1024
                    [Hq,tq,hq,Dq,Fq] = fcnMFDFA(downsample(tempDataAll(jChan,:),downsampleRate),scale,q,m,0);
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
                else
                    MFDFA = ones(1,4) * 1.0000e-16;
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
                VG = 0;
                resultMat(jChan,:) = [CD, PK, FNNB, D, LE, HFD, MSE, MFDFA, KC];
            end
            
            % Show progress
            if rem(jChan, 10)==1
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
        tableOutput{iEvent, 4:4 + 129*31 - 1} = resultMatT(:)'; 

        % Perform a checksum and display
        disp(['check nansum: ', num2str(nansum(resultMat(:)))])

	% Time stats
	disp([' CD_PK_v2 timing: ', num2str(time_CD_PK),...
	      ' MFDFA timing: ', num2str(time_MFDFA),...
	      ' total time: ', num2str(toc(time_tot)),...
	      ' [secs]'])
        
        % Save length of epoch
        tableOutput(iEvent, 'Epoch_length') = {size(tempDataAll, 2)}; 
        disp([' Event: ', num2str(iEvent)])
    end % loop for events

    % Save output to Excel spreadsheet for checking and futher processing
    % Leave only columns which have at least one non-zero value
    tableOutput = tableOutput(:,4:end);
    tableOutput = tableOutput(:,~all(tableOutput{:,:}==0));