function run_bang()
% play Bang You're Dead movie
% Julien Dubois
% 06/20/2016 from scratch
% 08/09/2016: cleaned up code
cd(fileparts(mfilename('fullpath')));
dbstop if error

%% Get info %%

addpath(fullfile(pwd,'..','utilities'));
h.subject   = ptb_get_input_string('\nEnter subject ID: ');
h.run       = ptb_get_input_numeric('\nEnter run number: ', [1 2 3 4]);

msg = '';
while isempty(msg),
    [~,msg] = system('hostname');
end
switch msg(1:(end-1))
    case 'DWA644104' % Julien's desktop Cedars (Windows 7)
        h.mode = 0; % debug mode
    case 'DWLA6600JK' % new stimulus laptop Cedars
        h.mode = 2; % cedars mode w/ Cedrus & Eyetracking
    case 'machine' % Julien's laptop (Ubuntu)
        h.mode = 0; % debug mode
    case 'Stim-PC' % MRI stimulus PC
        h.mode = 1; % debug mode
    otherwise
        h.mode      = ptb_get_input_numeric('\nEnter mode (0:debug, with movie; 1:MRI; 2:Cedars): ', [0 1 2]);
end

if h.mode ==1
    h.masterVolume = input('Enter volume: ');
    if isempty(h.masterVolume)
        h.masterVolume = 1;
    end
    h.useEyelinkOverride = ptb_get_input_numeric('\nUse eyetracking? (0:no; 1:yes): ', [0 1]);
end


h.playMovie = 1;%ptb_get_input_numeric('\nPlay Movie? (0:no; 1:yes): ', [0 1]);

h = initTask(h);

% turn off keyboard input to Matlab
% ListenChar(2);

% sending TTL / write info to log file
sendTTLsJD(h.TTL.startExp,0,h);

if h.playMovie
    
    %% instructions for movie watching
    h = displayInstructions(h,1);
    if h.endSignal,endTask(h);return;end
    
    if h.mode == 1
        %% show waiting for experimenter screen
        DrawFormattedText(h.window,'Waiting for experimenter...','center','center',[255 255 255],42);
        Screen('Flip',h.window);
    
        %% WAIT FOR TRIGGER
        [key,RT] = waitAndCheckKeys(h,inf,[h.escKey h.triggerKey],0);
        sendTTLsJD(h.TTL.keypress,[key,RT],h)
        if key == h.escKey,h.endSignal = 1;endTask(h);return;end
    end
    h.startTime = GetSecs;
    
    prepare_fixationCross(h.window, [255 255 255],h.crossSize, h.W, h.H);
    Screen('Flip',h.window,0);
    sendTTLsJD(h.TTL.startFix,0,h);
    %% wait for h.initFixDur
    keys = waitAndCheckKeys(h,h.initFixDur - (GetSecs-h.startTime),h.escKey,1);
    if ~isempty(keys),h.endSignal = 1;endTask(h);return;end
    
    %% play movie!
    h = playmovie(h);
    if h.endSignal
        return
    end
    
    %% wait for h.endFixDur
    prepare_fixationCross(h.window, [255 255 255],h.crossSize, h.W, h.H);
    [~,startFIX] = Screen('Flip',h.window,0);
    sendTTLsJD(h.TTL.endFix,0,h);
    keys = waitAndCheckKeys(h,h.endFixDur - (GetSecs-startFIX),h.escKey,1);
    if ~isempty(keys),h.endSignal = 1;endTask(h);return;end
end

%% instructions for questions
displayInstructions(h,2);
if h.endSignal,endTask(h);return;end

% SHOW QUESTIONS!
switch h.run
    case {1,2}
        testBBox(h,[h.key1 h.key2],{'1','2'});
        h = displayQuestions(h,h.h/4,32,44);
    case {3,4}
        if h.useConfidence
            testBBox(h,[h.OLDlowKey h.OLDmedKey h.OLDhighKey h.NEWlowKey h.NEWmedKey h.NEWhighKey],{'YES +','YES ++','YES +++','NO +','NO ++','NO +++'});
        else
            testBBox(h,[h.OLDKey h.NEWKey],{'YES','NO'});
        end
        h = showNO(h);
end
if h.endSignal,return;end

endTask(h);
