function resampledData = resampleData(dataStructs, timeWindow)
    % Input:
    %   dataStructs - a structure array containing your data (e.g., gpsData, etc.)
    %   timeWindow  - the new time vector for resampling (e.g., startTime:dt:stopTime)
    % Output:
    %   resampledData - structure array with resampled data
    
    % Initialize the resampled data structure array
    resampledData = struct();
    
    % Get the field names in the input data structure
    fields = fieldnames(dataStructs);
    
    % Loop through each field in the data structure
    for i = 1:numel(fields)
        fieldName = fields{i};
    
        % Check if the current field has a sub-field 'Time' and 'Data'
        if isfield(dataStructs.(fieldName), 'Time') && isfield(dataStructs.(fieldName), 'Data')
            % Remove duplicate Time points
            [uniqueTime, uniqueIdx] = unique(dataStructs.(fieldName).Time);

            discardingNPts = length(dataStructs.(fieldName).Time) - length(uniqueTime);
            if discardingNPts > 0
                disp(['Discarding ' num2str(discardingNPts) ' ' ...
                    fieldName ' measurements cause of duplicates ' ...
                    'in time vector.'])
            end
    
            % Get corresponding unique Data points
            uniqueData = dataStructs.(fieldName).Data(uniqueIdx);
    
            % Create new time vector for resampling
            resampledData.(fieldName).Time = timeWindow;  % Set the new time vector
    
            % Check if the Data field contains integer values
            if all(mod(uniqueData, 1) == 0)
                % Integer data: using the 'previous' method
                resampledData.(fieldName).Data = interp1(uniqueTime, ...
                    uniqueData, ...
                    timeWindow, 'previous');
            else
                % Non-integer data: use linear interpolation
                resampledData.(fieldName).Data = interp1(uniqueTime, ...
                    uniqueData, ...
                    timeWindow, 'pchip','extrap');  % Resample data
                resampledData.(fieldName).Data(timeWindow<uniqueTime(1)) = uniqueData(uniqueTime==uniqueTime(1));
                resampledData.(fieldName).Data(timeWindow>uniqueTime(end)) = uniqueData(uniqueTime==uniqueTime(end));
            end
            
            % No Inf or NaN in Data vector
            resampledData.(fieldName).Data = ...
                fillmissing([resampledData.(fieldName).Data],'previous');
            resampledData.(fieldName).Data = ...
                fillmissing([resampledData.(fieldName).Data],'next');
            resampledData.(fieldName).Data = ...
                fillmissing([resampledData.(fieldName).Data],'constant',0);
    
            % Create 'isNew' field
            isNew = false(size(timeWindow));  % Initialize isNew as false
            % First interval: check if there is data strictly before the first timeWindow value
            isNew(1) = any(uniqueTime <= timeWindow(1));
            for j = 2:numel(timeWindow)
                % Check if any original time value lies between timeWindow(j-1) and timeWindow(j)
                intervalStart = timeWindow(j-1);
                intervalEnd = timeWindow(j);
                isNew(j) = any(uniqueTime > intervalStart & uniqueTime <= intervalEnd);
            end
    
            resampledData.(fieldName).isNew = isNew; 
    
        else
            % If the field doesn't have 'Time' and 'Data', simply copy the original data
            resampledData.(fieldName) = dataStructs.(fieldName);
        end
    end
end

