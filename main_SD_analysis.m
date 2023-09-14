function [] = main_SD_analysis()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function allows the semi-automatic selection of SDs from ECoG
% signals recorded in rats.
% 
% Author: Pippo
% 
% Review history: 
%        v1, created on 20230116
%        v1.1, edited on 20230914
%
% Matlab version: R2022b
% Matlab toolbox required: Signal Processing Toolbox, version 9.1
%       
% 
% analysis of only reliable data (i.e. not
% affected by stimulation artifact)
% Main features:
%               1) data loading 
%               2) automatic labelling of each SD and GUI to select which 
%                   SDs are included in the analysis and modify the 
%                    labelling in case of automated mis-labelling  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    clear, clc, close all

    %% Signal and SDs data loading 

    [matrix_ds, start_rec_ds, experiment_name] = load_downsampled_file();
    [matrix_SD, start_rec_SD, experiment_name, protocol_information] = load_SD_file();
   
    fs = matrix_ds.fs; % sampling frequency
    
    % SD parameters 
    SD_param_labels = {'Recording', 'Electrode', 'LeftBoundIndex', 'MiddleBoundIndex', 'RightBoundIndex', ...
        'FirstPeakIndex', 'SecondPeakIndex', 'ThirdPeakIndex', 'RecoveryIndex', 'FirstPeakAmplitude', ...
        'SecondPeakAmplitude', 'ThirdPeakAmplitude'};
    
    % Creating a table containing the SDs data, specifying the name of each parameter
    table_SD = array2table(matrix_SD, 'VariableNames', SD_param_labels); % ?referred to original signal 

    % Converting the peak amplitudes in mV
    table_SD{:,["FirstPeakAmplitude","SecondPeakAmplitude","ThirdPeakAmplitude"]} = table2array(table_SD(:,["FirstPeakAmplitude", ...
        "SecondPeakAmplitude","ThirdPeakAmplitude"]))*1000; 
   
    %% Automated SD labelling + Graphic User Interface to select SDs and modify labelling
    % Manual selection of the SDs to be included in the analysis and visual check on whether 
    % the automatically SD labelling is correct or not

    % Initialization
    sd_selection = [];
    sd_labelling = [];
    stim_artifact = [];


    for d = 1:size(matrix_ds,1) % loop over the total number of recordings included in the analysis
        
        % Initializations
        SD_tab = table_SD(table_SD.Recording == d,:); % selection of SDs detected on the recording under analysis
        fs = matrix_ds(d).fs; % sampling frequency of the signal recorded
        signal = matrix_ds(d).signal; 
        time = matrix_ds(d).time;
      
        % Compute moving average of the signal (1s average window)
        smooth_signal = movmean(signal,fs);

        % Automatic labelling of control (C) and stimulation (S) SDs considering stimulation artifacts detected on the signal
        stim_artifact_info = automatic_labelling(signal, fs, SD_tab);

        % GUI to check, modify and confirm the labelling 
        [sd_sel, sd_lab, ~, stim_artifact_info] = labelling_user_check(d, smooth_signal, time, fs, SD_tab, stim_artifact_info, protocol_information(d,1));

        rec_num = num2cell(repmat(d,size(sd_lab,1),1)); % number of the analysed recording

        sd_selection = [sd_selection; sd_sel]; % cell array, for each SD it indicates if the SD has been selected in the GUI (1) or not (0)
        
        sd_labelling = [sd_labelling; sd_lab rec_num]; % cell array, for each SD indicates:
                                    % column 1) if the SD has been marked as C or S 
                                    % column 2) the specific interval that includes the SD (beginning/end sample)
                                    % column 3) the number of the recording in which the SDs have been detected
                                    
        stim_artifact = [stim_artifact; stim_artifact_info]; % matrix, for each SD indicates:
                                    % column 1) whether the SD has been included in the analysis
                                    % column 2) the electrode on which the SD artifact has been detected
                                    % column 3-4) the beginning/end index of the stimulation artifact 
                                    % column 5) the labelling (1 for S, 0 for C)


    end

end