function data = processTireTemp(badeniaData)
    if nargin < 2
            movmean_window_size = 0.1;
    
    end
    
    % Extract field names from the input structure
    fields = fieldnames(badeniaData);

    % Get "headstamp" (stamp from message)
    headstamp = getField(badeniaData, fields, 'stamp');

    tyreSurfaceTempFront = getField(badeniaData, fields, 'tpmsFront');
    tyreSurfaceTempRear  = getField(badeniaData, fields, 'tpmsRear');

    % Get Time (convert headstamp to seconds)
    time = headstamp.value1 ./ 1e9;
    
    %% Get Tyre temperature 
    % Front 
    TempFront_Left  =  tyreSurfaceTempFront.left; 
    TempFront_Right =  tyreSurfaceTempFront.right; 
     
    % Rear 
    TempRear_Left  =   tyreSurfaceTempRear.left; 
    TempRear_Right =   tyreSurfaceTempRear.right; 
   
     
    % Causal Filtering
    dt = mean(diff(time));
    window_size = round(movmean_window_size / dt);
    TempFront_Left = movmean(TempFront_Left, [window_size 1]);
    TempFront_Right= movmean(TempFront_Right, [window_size 1]);
    TempRear_Left = movmean(TempRear_Left, [window_size 1]);
    TempRear_Right= movmean(TempRear_Right,[window_size 1]);
   

    % Front temperatures
    TempFront_Left_ts.Time   = time;
    TempFront_Left_ts.Data   = TempFront_Left;
    TempFront_Right_ts.Time  = time;
    TempFront_Right_ts.Data  = TempFront_Right;
    
    % Rear temperatures
    TempRear_Left_ts.Time    = time;
    TempRear_Left_ts.Data    = TempRear_Left;
    TempRear_Right_ts.Time   = time;
    TempRear_Right_ts.Data   = TempRear_Right;
    
    % Assemble the output structure for temperatures
    data.TempFrontLeft = TempFront_Left_ts;
    data.TempFrontRight= TempFront_Right_ts;  
    data.TempRearLeft = TempRear_Left_ts;
    data.TempRearRight= TempRear_Right_ts;
   

end 