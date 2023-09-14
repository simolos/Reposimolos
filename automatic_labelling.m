% This function is needed to identify the start/end stimulation artifact
% index from the spectrogram of the signal (enlarged considering 2s before
% and 5s after the detected window)

function [artifact_matrix] = automatic_labelling(signal, fs, SD_tab)

    
    % Artifact matrix to keep track of unreliable peaks/boundaries
    artifact_matrix = [SD_tab.Recording SD_tab.Electrode NaN(size(SD_tab,1),2)];
    
    for i = 1:size(SD_tab,1)

        % Isolate SD signal (from left to right boundary)
        current_SD = signal(max(SD_tab.LeftBoundIndex(i)-fs*5, 1):SD_tab.RightBoundIndex(i)+fs*5,SD_tab.Electrode(i));
%         hpf_current_SD = highpass(current_SD,1/fs);

        [p,f,t] = pspectrum(current_SD,fs,'spectrogram');
%         figure
%         pspectrum(current_SD,fs,'spectrogram');
        idx = findchangepts(sum(p((f>45),:)),MaxNumChanges=2); 

       
        if isempty(idx) || length(idx) == 1 
            continue

        elseif (pow2db(max(p((f==50),idx(1):idx(2)))) > -70 || pow2db(max(p((f==0),idx(1):idx(2)))) > -50) 
            
              % debugging code
%             disp(i)
%             disp(std(current_SD(t(idx(1))*fs : t(idx(2))*fs)))
% 
%             figure
%             pspectrum(current_SD,fs,'spectrogram');
% 
%             figure; plot(current_SD); hold on; title(sprintf('electrode %d - sd %d',SD_tab.Electrode(i), i))
%             xline(t(idx(1))*fs)
%             xline(t(idx(2))*fs)
%     
%             figure; plot(hpf_current_SD); hold on; title(sprintf('electrode %d - sd %d',SD_tab.Electrode(i), i))
%             xline(t(idx(1))*fs)
%             xline(t(idx(2))*fs)


            % update artifact matrix 
            start_artifact = t(idx(1))*fs + SD_tab.LeftBoundIndex(i)-fs*5 - fs*2; % consider 2 s before artifact detection
            end_artifact = t(idx(2))*fs + SD_tab.LeftBoundIndex(i)-fs*5 + 5*fs; % 5 s to recover from artifact
            artifact_matrix(i,3) = start_artifact; 
            artifact_matrix(i,4) = end_artifact;

          % debugging code
%         figure; plot(signal(:,SD_tab.Electrode(i))); hold on; title(sprintf('electrode %d - sd %d',SD_tab.Electrode(i)))
%         xline(start_artifact)
%         xline(end_artifact)
            
        else
             continue
           
        end
       
    end


    % Identify the electrode on which most of the artifact are detected
    [stim_ref_electrode, ~] = mode(artifact_matrix(~isnan(artifact_matrix(:,3)),2));
   
%     if rep == 1 || stim_ref_electrode == 4
%         stim_ref_electrode = 10;
%     end

    artifact_matrix(artifact_matrix(:,2) ~= stim_ref_electrode,:) = [];
    artifact_matrix(~isnan(artifact_matrix(:,3)),5) = 1;
    artifact_matrix(isnan(artifact_matrix(:,3)),5) = 0;

    % debugging code
%     if ~isempty(artifact_matrix) 
        % Uncomment to plot stimulation artifact 
%         figure
%         plot(signal(:,stim_ref_electrode))
%         title(sprintf('Stimulation Artifact detected on electrode %d', stim_ref_electrode))
%         hold on   
%         for i=1:size(artifact_matrix,1)
%             if artifact_matrix(i,5) == 1
%             xline(artifact_matrix(i,3))
%             xline(artifact_matrix(i,4))
%             end
%         end
%     end

end