function masterVolume = checkSound()
% AUTHOR : Julien Dubois
%
% DATES : 2018-03-20 JMT Add scan trigger support

% Determine path to script
scriptDir = fileparts(mfilename('fullpath'));
fprintf('Script directory : %s\n', scriptDir);

stimDir = fullfile(scriptDir,'stimuli','movie');
movieFile = fullfile(stimDir,'short.avi');

% Read WAV file from filesystem:
if exist(strrep(movieFile,'.avi','_filt.wav'),'file')
    [y, fs] = psychwavread(strrep(movieFile,'.avi','_filt.wav'));
else
    [y, fs] = audioread(movieFile);
    y = filter_audio(strrep(movieFile,'.avi','_filt.wav'),y,fs);
    [y, fs] = psychwavread(strrep(movieFile,'.avi','_filt.wav'));
end
nrchannels = size(y,2); % Number of rows == number of channels.

% Perform basic initialization of the sound driver:
InitializePsychSound;

% This returns a handle to the audio device:
try
    % Try with the 'freq'uency we wanted:
    audObj = PsychPortAudio('Open', [], [], 0, fs, nrchannels);
catch
    % Failed. Retry with default frequency as suggested by device:
    fprintf('\nCould not open device at wanted playback frequency of %i Hz. Will retry with device default frequency.\n', fs);
    fprintf('Sound may sound a bit out of tune, ...\n\n');
    psychlasterror('reset');
    audObj = PsychPortAudio('Open', [], [], 0, [], nrchannels);
end
% Fill the audio playback buffer with the audio data 'wavedata':
PsychPortAudio('FillBuffer', audObj, y(floor(end/2):end,:)');
        
%% Keyboard setup
KbName('UnifyKeyNames');
escKey = KbName('ESCAPE');
triggerKey = KbName('5%');
acceptKey  = KbName('4$');
quieterKey = KbName('1!');
louderKey  = KbName('2@');

%% Setup PTB screen
Screen('Preference','SyncTestSettings', 0.005,50,0.3,5);
screenNumber = max(Screen('Screens'));
if screenNumber<0 % does this ever happen??
    screenNumber = 0;
end

window = Screen('OpenWindow',screenNumber,0);%,[0 0 800 600]);
Screen('TextSize',window,40);
Screen('TextFont',window,'Arial');
Screen('Preference', 'TextRenderer', 1);
Screen('Preference', 'TextAlphaBlending', 0);

% Include 4 : accept volume
DrawFormattedText(window, ...
    '1 : QUIETER\n\n2 : LOUDER\n\n4 : ACCEPT VOLUME', ...
    'center','center',[255 255 255],42);
Screen('Flip',window);

masterVolume = .5;
PsychPortAudio('Volume', audObj , masterVolume);

%% Wait for scan trigger
if conte_wait_trigger(triggerKey, escKey)
    fprintf('Trigger detected - starting audio playback\n');
else
    fprintf('Escape key pressed - cleaning up and exiting\n');
    sca
    return
end

%% Start audio playback
% Start audio playback for infinite repetitions of the sound data,
% start it immediately (0) and wait for the playback to start, return onset
% timestamp.
PsychPortAudio('Start', audObj, [], 0, 0);

keyIsDown = 0;

while 1
    
    if keyIsDown
        DrawFormattedText(window, ...
            '1 : QUIETER\n\n2 : LOUDER\n\n4 : ACCEPT VOLUME', ...
            'center','center',[255 255 255],42);
        Screen('Flip',window);
    else
        WaitSecs(0.01);
    end
    
    [keyIsDown, ~, keyCode, ~] = KbCheck;
    if keyIsDown
        
        if keyCode(quieterKey)
            masterVolume = max(masterVolume*0.95,0.1);
            fprintf('Volume decreased to %.2f\n',masterVolume);
            PsychPortAudio('Volume', audObj, masterVolume);
            DrawFormattedText(window,'-','center','center',[255 255 255],42);
            Screen('Flip',window);
            WaitSecs(0.2);
        
        elseif keyCode(louderKey)
            masterVolume = min(masterVolume*1.05,1);
            if masterVolume==1
                fprintf('Volume maxed out!\n');
                break
            else
                fprintf('Volume increased to %.2f\n',masterVolume);
            end
            PsychPortAudio('Volume', audObj, masterVolume);
            DrawFormattedText(window,'+',...
                'center','center',[255 255 255],42);
            Screen('Flip',window);
            WaitSecs(0.2);
        
        elseif keyCode(acceptKey)
            DrawFormattedText(window,'ACCEPTED VOLUME',...
                'center','center',[255 255 255],42);
            Screen('Flip',window);
            WaitSecs(0.2);
            break
            
        end
        
    end
end

if masterVolume == 1
    fprintf('--------------------------------------------------------\nEXPERIMENTER: increase volume on Sensimetrics dial, then relaunch this program\n--------------------------------------------------------\n'); 
else
    fprintf('--------------------------------------------------------\nEXPERIMENTER: set volume to %.2f\n--------------------------------------------------------\n',masterVolume);
end

PsychPortAudio('Stop', audObj);
sca;