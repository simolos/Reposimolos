function [matrix, start_rec,experiment_name] = load_downsampled_file()


% % Select the data in .mat format after downsampling
%     disp('Select the downsampled data file');
%     [file, path] = uigetfile('*.mat', 'Select the downsampled data file');
%     addpath(path);
%     load([path,file],'exp_ds');
%     file_name = split(string(extractBetween(file, 'data_', '_ds')), '_');
%     signal = exp_ds.signal;
%     time = exp_ds.time;
%     fs = exp_ds.fs;
%     nb_elec = size(signal,2);

 % select files
    fprintf('\nSelect the downsampled data files (data_********_******_ds)');
    [data.file_name, data.path] = uigetfile('*.mat', 'Select the downsampled data files (data_********_******_ds)', 'MultiSelect', 'on');
    if ~iscell(data.file_name)
        assert(length(data.file_name) ~= 1, 'You must select at least one file');
    end
    addpath(data.path);
    data.multi_files = iscell(data.file_name);
    
    % extract the number of files
    data.nb_files = 1;
    if data.multi_files
       data.nb_files = length(data.file_name);
    end
    fprintf('\n\t%d file(s) selected\n', data.nb_files)
    
    start_rec = zeros(1,data.nb_files);
    start_rec(1) = 1;

    % load data in one matrix
    if data.nb_files > 1
        load(data.file_name{1});
        matrix = exp_ds;
        experiment_name = reshape(split(string(extractBetween(data.file_name, 'data_', '_ds')), '_'),[data.nb_files,2]);
    else
        load(data.file_name);
        matrix = exp_ds;
        experiment_name = reshape(split(string(extractBetween(data.file_name, 'data_', '_ds')), '_'),[data.nb_files,2]);
    end



    data.file_length = zeros(1, data.nb_files);
    data.file_length(1) = size(matrix, 1);
    if data.nb_files > 1 
        for n = 2:data.nb_files
            load(data.file_name{n});
            new_matrix = exp_ds;
            data.file_length(n) = size(new_matrix, 1);
            start_rec(n) = size(matrix,1) + 1; 
            matrix = vertcat(matrix, new_matrix);
           
            clear new_matrix
            clear SD
        end
    end
    
end
