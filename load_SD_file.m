function [matrix, start_rec,experiment_name, protocol_information] = load_SD_file() 
    % Loading SD file
        
    % select files
    fprintf('\nSelect the SD data files (data_********_******_SD)');
    [data.file_name, data.path] = uigetfile('*.mat', 'Select the SD data files (data_********_******_SD)', 'MultiSelect', 'on');
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

    protocol_information = NaN(data.nb_files,2); 

    
    start_rec = zeros(1,data.nb_files);
    start_rec(1) = 1;

    % load data in one matrix
    if data.nb_files > 1
        load(data.file_name{1});
        matrix = SD;
        matrix = [ones(size(SD,1),1) matrix];
        experiment_name = reshape(split(string(extractBetween(data.file_name, 'data_', '_SD')), '_'),[data.nb_files,2]);
        
    else
        load(data.file_name);
        matrix = SD;
        matrix = [ones(size(SD,1),1) matrix];
        experiment_name = reshape(split(string(extractBetween(data.file_name, 'data_', '_SD')), '_'),[data.nb_files,2]);
    end

    if exist("protocol_info")
        protocol_information(1,:) = [protocol_info.cut_from_idx protocol_info.cut_to_idx];
        clear protocol_info
    end

    data.file_length = zeros(1, data.nb_files);
    data.file_length(1) = size(matrix, 1);
    if data.nb_files > 1 
        for n = 2:data.nb_files
            load(data.file_name{n});
            new_matrix = SD;
            new_matrix = [ones(size(SD,1),1)*n new_matrix];
            data.file_length(n) = size(new_matrix, 1);
            start_rec(n) = size(matrix,1) + 1; 
            matrix = vertcat(matrix, new_matrix);
            if exist("protocol_info")
                protocol_information(n,:) = [protocol_info.cut_from_idx protocol_info.cut_to_idx];
                clear protocol_info
            end
           
            clear new_matrix
            clear SD
        end
    end

end