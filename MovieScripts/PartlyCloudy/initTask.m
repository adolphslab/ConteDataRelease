function h = initTask(h)

Screen('Preference', 'VisualDebuglevel', 3);
h.verbose = 0;
KbName('UnifyKeyNames');

% add path to helper functions
addpath(fullfile(pwd,'..','utilities','io64'));

% Obsolete flag from Bang - set to false
h.useConfidence = 0;

% set up the various devices to be used
switch h.mode
    case 2 % SU at Cedars
        h.useCedrus       = 2 - h.useConfidence;
        h.useEyelink      = 1;
    case 1 % fMRI at Caltech
        h.useCedrus       = 0;
        h.useEyelink      = 1;
    case {0,-1} % debug
        % h.useCedrus       = 2 - h.useConfidence;
        h.useCedrus       = 0;
        h.useEyelink      = 0;
end

h.useEyelink = h.useEyelinkOverride;

% are there any stuck keys on the keyboard that should be disabled?
if ~h.useCedrus
    h.disableKeys = [];
    % on some laptops, keys need to be disabled for proper KbCheck functioning
    if ~isempty(h.disableKeys)
        DisableKeysForKbCheck(h.disableKeys);
    end
end

h.LYES = 0;

% configure io
if h.mode==2
    config_io;
end

% set up the key mapping
if h.useCedrus == 1 % 6 in a row
    h.escKey     = 8;
    h.key1       = 2;
    h.key2       = 3;
elseif h.useCedrus == 2
    h.escKey     = 6;
    h.key1       = 4;
    h.key2    = 5;
elseif h.useCedrus == 0
    if h.mode == 1
        h.escKey     = KbName('ESCAPE');
        h.triggerKey = KbName('5%');
        h.key1       = KbName('1!');
        h.key2       = KbName('2@');
    elseif h.mode == 0
        h.escKey     = KbName('ESCAPE');
        h.triggerKey = KbName('5%');
        h.key1       = KbName('1!');
        h.key2       = KbName('2@');
    end
end

%% parameters
h.initRestDur = 10; % seconds
h.endRestDur  = 10; % seconds

% display parameters
h.crossSize     = 15;  % size of fixation cross
h.frameSize     = 500; % size of frame
h.bgColor       = [0 0 0];
h.fgColor       = [255 255 255];
h.textSize      = 60;
h.theFontSize   = 40;
h.wrapat        = 44;
h.theFont       = 'Arial';

h.soundtimeout  = 200; % in ms : when to beep to let the patient know that they need to be faster
h.space         = KbName('space');
h.afterTTLDelay = 0;  %in secs, wait till reset of TTL to 0
h.beep          = MakeBeep(350,0.3,44000);

h.filePrefix    = sprintf('sub-%s_task-Pixar_run-', h.subject);

h.userDir = char(java.lang.System.getProperty('user.home'));
h.dataDir = fullfile(h.userDir, 'Desktop', 'Data');
h.subjDataDir = fullfile(h.dataDir, sprintf('sub-%s', h.subject));
if ~exist(h.subjDataDir,'dir')
    mkdir(h.subjDataDir);
end

[h.fidLog, h.fname, h.timestampStr] = openLogfile(h.filePrefix, h.subjDataDir);
h.saveFile = fullfile([h.fname, '_design.mat']);

%%
% open a PTB window
switch h.mode
    case 0
        Screen('Preference', 'ConserveVRAM', 64);
        Screen('Preference','SkipSyncTests',1);
    otherwise
        [a,b,c,d]=Screen('Preference','SyncTestSettings', 0.005,50,0.3,5);
end

screenNumber = max(Screen('Screens'));
if screenNumber < 0 % does this ever happen??
    screenNumber = 0;
end

if h.mode > 0
    h.window = Screen('OpenWindow',screenNumber,0);
else
   h.window = Screen('OpenWindow',screenNumber,0,[0 0 800 600]);
end

Screen('TextSize',h.window,h.textSize);
Screen('TextFont',h.window,'Arial');
Screen('Preference', 'TextRenderer', 1);
Screen('Preference', 'TextAlphaBlending', 0);

[h.w,h.h] = WindowSize(h.window);
h.W       = h.w/2;
h.H       = h.h/2;

fprintf('Screen number : %d\n', screenNumber);
fprintf('Screen width x height : %d x %d\n', h.w, h.h);

% Black and white index levels
% Define black, white and grey
h.white = WhiteIndex(screenNumber);
h.grey = white / 2;
h.black = BlackIndex(screenNumber);

HideCursor;

%% Test Button Box %%
if h.useCedrus
    h.handle=[];
    while isempty(h.handle)
        try
            h.handle=initCEDRUS;
        catch
            CedrusResponseBox('CloseAll');
            h.handle=initCEDRUS;
        end
    end
end

%% LOAD MOVIE
h.usePsychAudio = 1;

h.stimDir = fullfile(pwd,'stimuli');

if h.playMovie
    
    h.movieFile = fullfile(h.stimDir,'movie','partly_cloudy_sd_nocredits.mov');
    
    % No downsampling
    downsample = 1;
    
    fprintf('Loading movie!...\n');
    fprintf('\t video... \t');
    tic
    
    % the PTB3 Video functions do not work on Windows
    % h.mov = Screen('OpenMovie', h.window, h.movieFile);
    % instead, we'll need to read the movie frame by frame with Matlab's VideoReader and make textures on the fly
    % open video object and read total number of frames
    try
        vidObj = VideoReader(h.movieFile);
    catch vidErr
        sca;
        rethrow(vidErr);
    end
    
    h.movieWidth  = vidObj.Width/downsample;
    h.movieHeight = vidObj.Height/downsample;
    h.frameRate   = vidObj.FrameRate;
    
    % Partly Cloudy movie without end credits is 5m13.81s @ 23.98 fps
    % nFrames from ffprobe = 7524
    nFrames  = 7524;
    h.mov    = struct('tex',cell(1,nFrames),'cdata',cell(1,nFrames));
    k = 1;
    
    while hasFrame(vidObj)
        if mod(k,120)==1
            DrawFormattedText(h.window,sprintf('LOADING VIDEO\n\n%d%% complete', ceil(100*k/nFrames)),'center','center',[255 255 255],42);
            Screen('Flip',h.window);
        end
        tmp = readFrame(vidObj);
        h.mov(k).cdata = tmp(downsample:downsample:end,downsample:downsample:end,:);
        k = k+1;
    end
    
    % correct nFrame if it was wrong
    h.nFrames = length(h.mov);
    h.mov = h.mov(1:h.nFrames);
    
    elapsed = toc;
    fprintf('done in %.3fs\n',elapsed);
    
    fprintf('\t buffering movie...');
    tic
    
    % how many frames to buffer
    h.nBuffered = 25;
    h.frameTime = (0:(h.nFrames-1))/h.frameRate;
    
    % load first 1s
    h.loaded = zeros(1,h.nFrames);
    for iFrame = 1:h.nFrames
        if iFrame <= h.nBuffered
            h.mov(iFrame).tex    = Screen('MakeTexture', h.window, h.mov(iFrame).cdata);
            h.loaded(iFrame) = 1;
        else
            h.mov(iFrame).tex = 0;
            h.loaded(iFrame) = 0;
        end
    end
    elapsed = toc;
    fprintf('done in %.1fs\n',elapsed);
    
    %% loading audio
    movieExt = h.movieFile(end-3:end);
    if ~h.usePsychAudio
        
        fprintf('\t audio... \t');
        DrawFormattedText(h.window,'LOADING AUDIO','center','center',[255 255 255],42);
        Screen('Flip',h.window);
        tic
        % open audio object
        switch h.mode
            case 1
                if exist(strrep(h.movieFile,movieExt,'_filt.wav'),'file')
                    [y, fs] = audioread(strrep(h.movieFile,movieExt,'_filt.wav'));
                else
                    [y, fs] = audioread(h.movieFile);
                    y = filter_audio(strrep(h.movieFile,movieExt,'_filt.wav'),y,fs);
                end
            otherwise
                if exist(strrep(h.movieFile,movieExt,'.wav'),'file')
                    [y, fs] = audioread(strrep(h.movieFile,movieExt,'.wav'));
                else
                    [y, fs] = audioread(h.movieFile);
                    audiowrite(strrep(h.movieFile,movieExt,'.wav'),y,fs);
                end
        end
        
        % need to add ~100ms of sound to the beginning of the audio file
        % to compensate for intractable delay...
        h.audioPrefixLength = ceil(fs*0.116);
        y = [zeros(h.audioPrefixLength,2);y];
        
        h.audObj = audioplayer(y,fs);
        clear y fs
        elapsed = toc;
        fprintf('done in %.3fs\n',elapsed);
        
        % initialize sound
        % may take 0.5s or so to start
        play(h.audObj);
        pause(h.audObj);
        
    else
        
        % Read WAV file from filesystem:
        switch h.mode
            case 1
                if exist(strrep(h.movieFile,movieExt,'_filt.wav'),'file'),
                    [y, fs] = psychwavread(strrep(h.movieFile,movieExt,'_filt.wav'));
                else
                    [y, fs] = audioread(h.movieFile);
                    y = filter_audio(strrep(h.movieFile,movieExt,'_filt.wav'),y,fs);
                    [y, fs] = psychwavread(strrep(h.movieFile,movieExt,'_filt.wav'));
                end
            otherwise
                if exist(strrep(h.movieFile,movieExt,'.wav'),'file'),
                    [y, fs] = psychwavread(strrep(h.movieFile,movieExt,'.wav'));
                else
                    [y, fs] = audioread(h.movieFile);
                    audiowrite(strrep(h.movieFile,movieExt,'.wav'),y,fs);
                    [y, fs] = psychwavread(strrep(h.movieFile,movieExt,'.wav'));
                end
        end
        h.fs = fs;
        nrchannels = size(y,2); % Number of rows == number of channels.
        % Perform basic initialization of the sound driver:
        InitializePsychSound;
        % This returns a handle to the audio device:
        try
            % Try with the 'freq'uency we wanted:
            h.audObj = PsychPortAudio('Open', [], [], 0, fs, nrchannels);
        catch
            % Failed. Retry with default frequency as suggested by device:
            fprintf('\nCould not open device at wanted playback frequency of %i Hz. Will retry with device default frequency.\n', fs);
            fprintf('Sound may sound a bit out of tune, ...\n\n');
            psychlasterror('reset');
            h.audObj = PsychPortAudio('Open', [], [], 0, [], nrchannels);
        end
        % Fill the audio playback buffer with the audio data 'wavedata':
        PsychPortAudio('FillBuffer', h.audObj, y');
        PsychPortAudio('Volume', h.audObj, h.masterVolume);
    end
else
    h.movieWidth  = 640;
    h.movieHeight = 360;
end

h.displayWidth  = h.w;
h.displayHeight = h.displayWidth / h.movieWidth * h.movieHeight;
if h.displayHeight > h.h % accommodates different aspect ratio for the presentation screen
    h.displayHeight = h.h;
    h.displayWidth  = h.displayHeight / h.movieHeight * h.movieWidth;
end
h.rect    = [h.W-ceil(h.displayWidth/2) h.H-ceil(h.displayHeight/2) h.W+ceil(h.displayWidth/2) h.H+ceil(h.displayHeight/2)];

%% instructions
% movie watching
if h.useCedrus
    img = imread(fullfile(h.stimDir,'instructions',sprintf('instructions1_SU%d.png',h.useCedrus)));
else
    if h.mode == 1
        img = imread(fullfile(h.stimDir,'instructions','instructions1_MRI.png'));
    else
        img = imread(fullfile(h.stimDir,'instructions','instructions1_db.png'));
    end
end
[h.instrH,h.instrW,~] = size(img);
h.instrDispW  = 8/10 * h.w;
h.instrDispH = h.instrDispW / h.instrW * h.instrH;
if h.instrDispH > h.h % accomodates different aspect ratio for the presentation screen
    h.instrDispH = 8/10 * h.h;
    h.instrDispW  = h.instrDispH / h.instrH * h.instrW;
end
h.instrRect = [h.W-ceil(h.instrDispW/2) h.H-ceil(h.instrDispH/2) h.W+ceil(h.instrDispW/2) h.H+ceil(h.instrDispH/2)];

h.instr(1)  = Screen('MakeTexture', h.window, img);

h.eyeLinkMode  = h.useEyelink;

%% triggers
h.TTL.trigger      = 33;

h.TTL.startExp     = 61;
h.TTL.endExp       = 66;
h.TTL.startInstr   = 51:59;
h.TTL.keypress     = 33;


h.TTL.startFix     = 1;
h.TTL.endFix       = 10;

h.TTL.video        = 4;
h.TTL.startQ       = 5;
h.TTL.resp         = 6;

h.TTL.startProbe   = 7;
h.TTL.endProbe     = 8;
h.TTL.startITI     = 9;

if h.eyeLinkMode
    h.edfFile     = datestr(now, 'ddHHMMSS');
    h.eyeLinkMode = ptb_eyelink_initialize(h.window,h.edfFile);
end

h.endSignal = 0;
h.curFrame  = 1;
h.curTrial  = 0;

priorityLevel=MaxPriority(h.window);
Priority(priorityLevel);

sendTTLsJD(h.TTL.startExp,0,h);
end

