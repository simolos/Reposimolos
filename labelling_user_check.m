% This function creates a GUI for the user to 

% How to use the GUI:
%   - to do ... : 
%

function [selection_vector, label_vector, new_SD_tab, stim_artifact_info] = labelling_user_check(rec, smooth_signal, time, fs, SD_tab, stim_artifact_info, protocol_info)     
        
        % INPUTS
        % - rec: index of recording under analysis (in case SDs from different recordings are analysed together)
        % - smooth_signal: smooth_signal of the recording under analysis
        % - time: time vector of the recording under analysis
        % - fs: sampling frequency of the recording under analysis
        % - SD_tab: table containing the SDs info in the recording under analysis
        % - stim_artifact_info: stimulation artifact window, as automatically detected by automatic_labelling.m
        % - protocol_info

        % OUTPUTS                                                         
        % - selection_vector: 1 for selected SD, to be included in the analysis (0 if not)
        % - label_vector: 'S' for stimulation, 'C' for control SD, followed by index of beginning/end of stimulation window (from left boundary to 3 minutes after it)
        % - new_SD_tab: new table after correction of possible wrong boundary selected by mistake through main_detect_SD
        % - stim_artifact_info: returned after modification (i.e. false stimulation artifact detected by automatic_labelling.m)

        if ~isnan(protocol_info)
            time_offset = protocol_info/(60*fs); 
        else
            time_offset = 0;
        end
         
        %% GUI setup
        % Create UIFigure and hide until all components are created
        app.UIFigure = uifigure('Visible', 'off');
        app.UIFigure.Position = [100 100 710 532];  
        app.UIFigure.WindowState = 'maximized';
        app.UIFigure.Name = 'MATLAB App';
    
    
        % Create UIAxes
        app.UIAxes = uiaxes(app.UIFigure);
        xlabel(app.UIAxes, 'X')
        ylabel(app.UIAxes, 'Y')
        zlabel(app.UIAxes, 'Z')
        app.UIAxes.Position = [2 224 1500 238];
    
         % Show the figure after all components are created
        app.UIFigure.Visible = 'on';
    
        % Plot the signal
        selected_electrode = 10;
        plot(app.UIAxes, time/60, smooth_signal(:,selected_electrode)*1000) % *1000 --> mV
        hold(app.UIAxes, 'on' )
        scatter(app.UIAxes, SD_tab.SecondPeakIndex(SD_tab.Electrode == selected_electrode)/(100*60), SD_tab.SecondPeakAmplitude(SD_tab.Electrode == selected_electrode))
        app.UIAxes.YLim = [-10 10];
    
        
    
        % Create ChangeelectrodeDropDown - to change the electrode showed
        ChangeelectrodeDropDown = uidropdown(app.UIFigure, "ValueChangedFcn", @(CEDD,el) ElectrodeChanged(CEDD,selected_electrode));
        electrodes = 1:size(smooth_signal,2);
        ChangeelectrodeDropDown.Items = cat(length(electrodes), string(electrodes));
        ChangeelectrodeDropDown.Position = [151 481 103 35];
        ChangeelectrodeDropDown.Value = string(selected_electrode);
        ChangeelectrodeDropDownLabel= uilabel(app.UIFigure);
        ChangeelectrodeDropDownLabel.HorizontalAlignment = 'right';
        ChangeelectrodeDropDownLabel.Position = [29 488 99 22];
        ChangeelectrodeDropDownLabel.Text = 'Change electrode';
        
        
        
        % Create CheckBox and DropDown to change the label
    
        selected_electrode_SD = SD_tab((SD_tab.Electrode == selected_electrode),:);

        if isempty(selected_electrode_SD)
            selected_electrode_SD = SD_tab((SD_tab.Electrode == 4),:);
        end

      
    
        for i = 1:size(selected_electrode_SD,1)
    
            x_coord = selected_electrode_SD(i,:).SecondPeakIndex;
            y_coord = smooth_signal(x_coord,selected_electrode)*1000;

            [xfigure, yfigure] = axescoord2figurecoord(x_coord/(fs*60), y_coord, app.UIAxes);

            
            % DropDown to change the label
            DropDown(i) = uidropdown(app.UIFigure);
            labels = [{'C'}, {'S'}];
            DropDown(i).Items = cat(2, string(labels)); 
            if ~isempty(stim_artifact_info)
                if stim_artifact_info(i,5) == 1
                    DropDown(i).Value = 'S';
                else
                    DropDown(i).Value = 'C';
                end
            else
                DropDown(i).Value = 'C';
            end
            DropDown(i).Position = [xfigure+25 150 40 22]; % 25 start axis 
          
    
            % CheckBox to consider the SD
         
            CheckBox(i) = uicheckbox(app.UIFigure,'ValueChangedFcn',@(CheckBox,event) cBoxChanged(CheckBox, DropDown(i)));
            CheckBox(i).Position = [xfigure+25 180 100 22]; % 25 start axis 
            CheckBox(i).Value = true; % all SD included by default
            CheckBox(i).Text = 'Select SD';

            % MinuteLabel
            MinuteLabel(i) = uilabel(app.UIFigure);
            MinuteLabel(i).Position = [xfigure+25 210 70 25];
            MinuteLabel(i).Text = sprintf('Min %f', selected_electrode_SD(i,:).LeftBoundIndex/(60*100)+time_offset); % left bound index (+ time_offset to display the correct time index referred to the excel experiment file)
           
        end
    
        % Create ModifySDButton
        ModifySDButton = uibutton(app.UIFigure, 'push', 'ButtonPushedFcn', @ModifySDBpushed);
        ModifySDButton.Position = [300 481 103 35];
        ModifySDButton.Text = 'Modify SDs';
    
        new_SD_tab = [];
    
        
    
    
        % Create DoneButton
        DoneButton = uibutton(app.UIFigure, 'push', 'ButtonPushedFcn', @DoneBpushed);
        DoneButton.Position = [614 482 62 34];
        DoneButton.Text = 'Done';
    
    
    
        waitfor(app.UIFigure)

   
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Functions
    
        % If CheckBox not selected, disable the DropDown 
        function cBoxChanged(CheckBox, DD)
            val = CheckBox.Value;
            if val
                DD.Enable = 'on';
            else
                DD.Enable = 'off';
            end
        end
    
    
        function ElectrodeChanged(CEDD, el)
            e = CEDD.Value;
            if e ~= el
    %         new_el = CEDD.Value;
    %         CEDD.Value
            end
            
            update_plot()
        end
    
        
        function update_plot() 
            % update plot in the external window
            % get electrode value from dropdown
            e = str2double(get(ChangeelectrodeDropDown,'Value'));
            % update plot in the GUI window
            hold(app.UIAxes,'off')
            plot(app.UIAxes, time/60, smooth_signal(:,e)*1000) % *1000 --> mV
            hold(app.UIAxes,'on')
            scatter(app.UIAxes, SD_tab.SecondPeakIndex(SD_tab.Electrode == e)/(100*60), SD_tab.SecondPeakAmplitude(SD_tab.Electrode == e))
            app.UIAxes.XLabel.String = 'Time [min]';
            app.UIAxes.YLabel.String = 'Voltage [mV]';
            app.UIAxes.YLim = [-10 10];
        end


        function ModifySDBpushed(~,~)
            modify_el = str2double(get(ChangeelectrodeDropDown(:),'Value'));

            % Select SD that needs to be modified
            modify_el_SDs = SD_tab.SecondPeakIndex(SD_tab.Electrode == modify_el);
            list = modify_el_SDs/(60*100) + time_offset;
            [modify_sd_indx,~] = listdlg('PromptString','Min','ListString',string(list));
            
            % Call extract_SD.mat to change SD limits 
            idx_start = max([modify_el_SDs(modify_sd_indx)-2*60*fs, 1]);
            idx_end = min([modify_el_SDs(modify_sd_indx)+2*60*fs, size(smooth_signal,1)]);      
            [peak_idx1, peak_idx2, peak_idx3, lb_idx, mid_idx, rb_idx, recovery_idx, peak_amp1, peak_amp2, peak_amp3] = extract_SD(smooth_signal(:,modify_el), idx_start, idx_end, fs, modify_el, modify_sd_indx);
            new_SD = [rec, modify_el, lb_idx, mid_idx, rb_idx, peak_idx1, peak_idx2, peak_idx3, recovery_idx, peak_amp1, peak_amp2, peak_amp3];
            SD_param_labels = {'Recording', 'Electrode', 'LeftBoundIndex', 'MiddleBoundIndex', 'RightBoundIndex', 'FirstPeakIndex', 'SecondPeakIndex', 'ThirdPeakIndex', 'RecoveryIndex', 'FirstPeakAmplitude', 'SecondPeakAmplitude', 'ThirdPeakAmplitude'};
            replace_SD_tab = array2table(new_SD, 'VariableNames', SD_param_labels); % referred to original signal 
            replace_SD_tab{:,["FirstPeakAmplitude","SecondPeakAmplitude","ThirdPeakAmplitude"]} = table2array(replace_SD_tab(:,["FirstPeakAmplitude","SecondPeakAmplitude","ThirdPeakAmplitude"]))*1000; % mV
            SD_tab(SD_tab.SecondPeakIndex == modify_el_SDs(modify_sd_indx),:)
            % Overwrite table_SD
            SD_tab(SD_tab.SecondPeakIndex == modify_el_SDs(modify_sd_indx),:) = replace_SD_tab;            
            update_plot()
            new_SD_tab = SD_tab;

            uiwait
        end
    
    
        function DoneBpushed(~,~)
            selection_vector = get(CheckBox(:),'Value');
            if length(selection_vector) == 1
                label_vector(:,1) = {get(DropDown(:),'Value')}; % 'C' or 'S'
                label_vector(:,2) = num2cell(cellfun(@str2num, extractAfter({get(MinuteLabel(:), 'Text')}, 'Min '))*60*fs - time_offset*60*fs); % inf window (left boundary)
                label_vector(:,3) = num2cell(cellfun(@str2num, extractAfter({get(MinuteLabel(:), 'Text')}, 'Min '))*60*fs + 3*60*fs - time_offset*60*fs); % sup window (3 minute after left boundary)
            else
                label_vector(:,1) = get(DropDown(:),'Value'); % 'C' or 'S'
                label_vector(:,2) = num2cell(cellfun(@str2num, extractAfter(get(MinuteLabel(:), 'Text'), 'Min '))*60*fs - time_offset*60*fs); % inf window (left boundary)
                label_vector(:,3) = num2cell(cellfun(@str2num, extractAfter(get(MinuteLabel(:), 'Text'), 'Min '))*60*fs + 3*60*fs - time_offset*60*fs); % sup window (3 minute after left boundary)
            end
            
            % delete stimulation artifact index wrongly detected in case of
            % control recording
            stim_artifact_info(strcmp(label_vector(:,1), 'C'),3) = NaN;
            stim_artifact_info(strcmp(label_vector(:,1), 'C'),4) = NaN;
            stim_artifact_info(strcmp(label_vector(:,1), 'C'),5) = 0;


            delete(app.UIFigure);
        end
    
     
end
