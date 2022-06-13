function run_pixar()
% play PIXAR Clouds movie
% Julien Dubois
% 2018-03-20 JD  : adapted from Bang You're Dead code
% 2018-03-30 JD  : fixed bugs following live subject run-through
% 2018-04-04 JMT : Switch to SD version of movie
% 2018-04-05 JMT : Add audio back into SD and clip credits

cd(fileparts(mfilename('fullpath')));

%% Get info %%
addpath(fullfile(pwd,'..','utilities'));
subjID = ptb_get_input_string('\nEnter subject ID: ');
h.subject = subjID;

msg = '';
while isempty(msg)
    [~,msg] = system('hostname');
end

switch msg(1:(end-1))
    case 'DWA644104' % Julien's desktop Cedars (Windows 7)
        h.mode = 0; % debug mode
    case 'DWLA6600JK' % new stimulus laptop Cedars
        h.mode = 2; % cedars mode w/ Cedrus & Eyetracking
    case 'machine' % Julien's laptop (Ubuntu)
        h.mode = 0; % debug mode
    case 'StimPC' % MRI stimulus PC
        h.mode = 1; % Caltech StimPC mode
    otherwise
        h.mode = ptb_get_input_numeric('\nEnter mode (0:debug, with movie; 1:MRI; 2:Cedars): ', [0 1 2]);
end

% Force silent movie
h.masterVolume = 0.0;

switch h.mode
    case 0  % Debug
        h.useEyelinkOverride = 0;
        h.playMovie          = 0;
    case 1  % Caltech StimPC
        h.useEyelinkOverride = ptb_get_input_numeric('\nUse eyetracking? (0:no; 1:yes): ', [0 1]);
        h.playMovie          = 1;
    otherwise
        % Do nothing
end

% Initialize task parameter structure, h
h = initTask(h);

%% Saxelab-style analysis parameters
% Partly Cloudy movie without end credits is 5m13.81s @ 23.98 fps
restDur = h.initRestDur + h.endRestDur;  % Total resting-state time (seconds)
movieDur = 5 * 60 + 13.81; % Move duration without credits (seconds)
TR = 0.7;  % MB EPI TR for Conte Core 2 (seconds)
ips = fix((restDur + movieDur)/TR);

fprintf('\nTotal volumes (rounded down) : %d', ips);

% sending TTL / write info to log file
sendTTLsJD(h.TTL.startExp,0,h);

if h.playMovie
    
    %% Skip instructions
    % h = displayInstructions(h,1);
    % if h.endSignal,endTask(h);return;end
    
    if h.mode == 1
        
        %% "Waiting for experimenter" screen
        DrawFormattedText(h.window,'Waiting for experimenter...','center','center',[255 255 255],42);
        Screen('Flip', h.window);
    
        %% WAIT FOR TRIGGER
        [key,RT] = waitAndCheckKeys(h,inf,[h.escKey h.triggerKey],0);
        sendTTLsJD(h.TTL.keypress,[key,RT],h)
        if key == h.escKey
            h.endSignal = 1;
            endTask(h);
            return;
        end
    end
    
    % Timestamp immediately post-trigger
    h.startTime = GetSecs;
    
    % For Saxelab-style analysis
    experimentStart = h.startTime;
    
    %% Pre-movie resting state with black screen
    Screen('FillRect', h.window, h.black);
    [~, startPreRest] = Screen('Flip', h.window, 0);
    sendTTLsJD(h.TTL.startFix,0,h);
    keys = waitAndCheckKeys(h, h.initRestDur - (GetSecs-startPreRest), h.escKey, 1);
    if ~isempty(keys),h.endSignal = 1;endTask(h);return;end
    
    %% play movie!
    
    % For Saxelab-style analysis
    trialStart = GetSecs;
    
    h = playmovie(h);
    if h.endSignal
        return
    end
    
    %% Post-movie resting state with black screen
    Screen('FillRect', h.window, h.black);
    [~, startPostRest] = Screen('Flip', h.window, 0);
    sendTTLsJD(h.TTL.endFix,0,h);
    keys = waitAndCheckKeys(h, h.endRestDur - (GetSecs-startPostRest), h.escKey,1);
    if ~isempty(keys),h.endSignal = 1;endTask(h);return;end
    
    % For Saxelab-style analysis (includes end fixation)
    experimentEnd = GetSecs;

else
    
    % Debug mode without movie
    % Set all timestamps to current time
    h.startTime = GetSecs;
    experimentStart = h.startTime;
    trialStart = h.startTime;
    experimentEnd = h.startTime;
    
end

endTask(h);

%% Collate information for Saxelab-style MAT-file output
timing_adjustment   = trialStart - experimentStart;
experimentDuration	= experimentEnd - experimentStart;

%% Analysis Info

% Movie coding for official pixar file by conditions. 
% Original coding as we used in the analysis reported in Jacoby et al (2015). 
% All timings in seconds and assume 10 sec fixation before movie
conds(1).names = 'mental';
conds(2).names = 'pain';
conds(3).names = 'social';
conds(4).names = 'control';
conds(1).onsets = [182, 250, 270, 286]; % mental
conds(2).onsets = [122, 134, 156, 192, 206, 224, 312]; % pain
conds(3).onsets = [62, 86, 96, 110, 124]; % social
conds(4).onsets = [24, 48, 70]; % control
conds(1).durs = [8, 8, 10, 18]; % mental
conds(2).durs = [2, 6, 4, 2, 6, 4, 2]; % pain third one can be 10 sec
conds(3).durs = [6, 10, 2, 6, 4]; % social
conds(4).durs = [6, 10, 8]; % control

try
    
    bfname = conte_fname(h.dataDir, subjID, 'pixar', 'behavior.mat');
	save(bfname, 'subjID', ...
        'timing_adjustment', 'trialStart', ...
        'experimentStart', 'experimentEnd', 'experimentDuration', ...
        'ips', 'conds');

catch exception

    warndlg(sprintf('The experiment has encountered the following error while saving the behavioral data: %s',exception.message),'Error');

end


