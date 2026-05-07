function value = getField(data, fields, keyword)
    % Look for an exact match first
    exactMatchIdx = find(strcmp(fields, keyword));
    
    if ~isempty(exactMatchIdx)
        % If an exact match is found, return the corresponding value
        value = data.(fields{exactMatchIdx});
    else
        % If no exact match, find all fields containing the keyword
        containsMatchIdx = find(contains(fields, keyword));
        
        if ~isempty(containsMatchIdx)
            if length(containsMatchIdx) == 1
                % If only one match is found, return it directly
                value = data.(fields{containsMatchIdx});
            else
                % If multiple matches are found, return a struct with all values
                value = struct();
                for i = 1:length(containsMatchIdx)
                    fieldName = fields{containsMatchIdx(i)};
                    
                    % Extract the part of the field name after the keyword
                    keywordStartIdx = strfind(fieldName, keyword);
                    newFieldName = fieldName((keywordStartIdx + length(keyword)):end);
                    
                    % Remove any leading underscores or numbers
                    newFieldName = regexprep(newFieldName, '^[^a-zA-Z]+', '');

                    % Check if the new field name is a valid MATLAB variable name
                    if ~isvarname(newFieldName)
                        % If not, assign a default name with a unique suffix
                        newFieldName = ['value', num2str(i)];
                    end
                    
                    % Assign the value to the new field name in the struct
                    value.(newFieldName) = data.(fieldName);
                end
            end
        else
            error(['No field containing "', keyword, '" found.']);
        end
    end
end