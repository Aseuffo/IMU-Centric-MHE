function log = loadDataWithPrompt(logFolder, vehicle_type, vehicle, sim, Ts, varargin)
% loadDataWithPrompt  Load dataset with smart reuse/overwrite prompt.
%
% This function checks whether a variable (default: "log") already exists in a
% workspace (default: base). If it exists, it compares metadata:
%   log.vehicleType (string/char) and log.logName (string/char)
% and shows a popup:
%   - If same dataset: suggests "Reuse (no reload)" as default
%   - If different dataset: suggests "Overwrite (reload)" as default
%
% Usage:
%   log = loadDataWithPrompt(logFolder, vehicle_type, vehicle, sim, Ts);
%
% Name-Value options:
%   'VarName'    : variable name to check/store (default "log")
%   'Workspace'  : "base" or "caller" (default "base")
%   'Title'      : dialog title (default "Dataset already loaded")
%   'AutoReuseIfSame' : if true, skips popup when same dataset (default false)
%   'StoreInWorkspace': if true, assigns returned log to workspace var (default true)
%
% Note: Requires MATLAB desktop for questdlg. If desktop is unavailable, it
% falls back to a non-interactive behavior (by default: overwrite).

    % ---- Parse options ----
    p = inputParser;
    addParameter(p, 'VarName', "log", @(s)isstring(s) || ischar(s));
    addParameter(p, 'Workspace', "base", @(s) any(strcmpi(string(s), ["base","caller"])));
    addParameter(p, 'Title', "Dataset already loaded", @(s)isstring(s) || ischar(s));
    addParameter(p, 'AutoReuseIfSame', false, @(b)islogical(b) && isscalar(b));
    addParameter(p, 'StoreInWorkspace', true, @(b)islogical(b) && isscalar(b));
    addParameter(p, 'NoDesktopPolicy', "overwrite", @(s) any(strcmpi(string(s), ["overwrite","reuse","error"])));
    parse(p, varargin{:});

    varName = string(p.Results.VarName);
    ws      = string(lower(p.Results.Workspace));
    dlgTitle = string(p.Results.Title);
    autoReuseIfSame = p.Results.AutoReuseIfSame;
    storeInWs = p.Results.StoreInWorkspace;
    noDesktopPolicy = string(lower(p.Results.NoDesktopPolicy));

    % ---- Helper: safely to string ----
    toStr = @(x) string(x);

    % Requested dataset identity
    reqVehicle = toStr(vehicle_type);
    reqLogName = toStr(logFolder); % you can change to just the folder name if preferred
    reqInfo = reqVehicle + " / " + reqLogName;

    % ---- Check existing ----
    existsVar = evalin(ws, "exist('" + varName + "','var')") == 1;

    if existsVar
        oldLog = evalin(ws, char(varName));

        % Extract old identity if possible
        oldInfo = "unknown";
        oldVehicle = "";
        oldLogName = "";
        hasMeta = isstruct(oldLog) && isfield(oldLog,'vehicleType') && isfield(oldLog,'logName');

        if hasMeta
            try
                oldVehicle = toStr(oldLog.vehicleType);
                oldLogName = toStr(oldLog.logName);
                oldInfo = oldVehicle + " / " + oldLogName;
            catch
                hasMeta = false;
                oldInfo = "unknown";
            end
        end

        sameDataset = false;
        if hasMeta
            sameDataset = (oldVehicle == reqVehicle) && (oldLogName == reqLogName);
        end

        % If same dataset and user wants auto-reuse, return immediately
        if sameDataset && autoReuseIfSame
            log = oldLog;
            if storeInWs
                assignin(ws, char(varName), log);
            end
            return;
        end

        % If no desktop (no GUI), choose fallback behavior
        if ~usejava('desktop')
            switch noDesktopPolicy
                case "reuse"
                    log = oldLog;
                    if storeInWs
                        assignin(ws, char(varName), log);
                    end
                    return;
                case "overwrite"
                    % continue to reload
                otherwise
                    error("No desktop available for popup. Aborting (NoDesktopPolicy='error').");
            end
        else
            % Build message + default choice
            if sameDataset
                msg = "The same dataset is already loaded:" + newline + ...
                      "   " + oldInfo + newline + newline + ...
                      "Reloading will waste time." + newline + ...
                      "Do you want to reuse it?";
                defaultBtn = "Reuse (no reload)";
            else
                msg = "A dataset is already loaded:" + newline + ...
                      "   CURRENT : " + oldInfo + newline + ...
                      "   REQUEST : " + reqInfo + newline + newline + ...
                      "Do you want to reuse the current log (skip reloading) or overwrite it (reload from disk)?";
                defaultBtn = "Overwrite (reload)";
            end

            choice = questdlg( ...
                char(msg), ...
                char(dlgTitle), ...
                "Reuse (no reload)", "Overwrite (reload)", "Cancel", ...
                char(defaultBtn));

            switch choice
                case "Reuse (no reload)"
                    log = oldLog;
                    if storeInWs
                        assignin(ws, char(varName), log);
                    end
                    return;
                case "Overwrite (reload)"
                    % continue to reload below
                otherwise
                    error("Operation canceled by user.");
            end
        end
    end

    % ---- Reload path ----
    log = loadData(logFolder, vehicle_type, vehicle, sim, Ts);

    % Ensure metadata is present/updated
    try
        log.vehicleType = reqVehicle;
        log.logName     = reqLogName;
    catch
        % If log isn't a struct, skip metadata
    end

    if storeInWs
        assignin(ws, char(varName), log);
    end
end