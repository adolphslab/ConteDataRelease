function h = initTask(h)

Screen('Preference', 'VisualDebuglevel', 3);
h.verbose = 0;
KbName('UnifyKeyNames');

% add path to helper functions
addpath(fullfile(pwd,'..','utilities','io64'));

if ismember(h.run,[3 4])
    h.useConfidence=1; % use confidence for new/old task
else
    h.useConfidence=0;
end

% set up the various devices to be used
switch h.mode
    case 2 % SU at Cedars
        h.useCedrus       = 2 - h.useConfidence;
        h.useEyelink      = 1;
    case 1 % fMRI at Caltech
        h.useCedrus       = 0;
        h.useEyelink      = 1;
    case {0,-1} % debug
        h.useCedrus       = 2 - h.useConfidence;
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
    if h.run <=2
        h.key2    = 3;
    else
        if h.useConfidence
            switch h.LYES
                case 0
                    h.NEWhighKey = 2;
                    h.NEWmedKey  = 3;
                    h.NEWlowKey  = 4;
                    h.OLDlowKey  = 5;
                    h.OLDmedKey  = 6;
                    h.OLDhighKey = 7;
                case 1
                    h.NEWhighKey = 7;
                    h.NEWmedKey  = 6;
                    h.NEWlowKey  = 5;
                    h.OLDlowKey  = 4;
                    h.OLDmedKey  = 3;
                    h.OLDhighKey = 2;
            end
        else
            switch h.LYES
                case 0
                    h.NEWKey = 2;
                    h.OLDKey = 7;
                case 1
                    h.NEWKey = 7;
                    h.OLDKey = 2;
            end
        end
    end
elseif h.useCedrus == 2
    h.useConfidence = 0;
    h.escKey     = 6;
    h.key1       = 4;
    if h.run <=2
        h.key2    = 5;
    else
        switch h.LYES
            case 0
                h.NEWKey = 4;
                h.OLDKey = 5;
            case 1
                h.NEWKey = 5;
                h.OLDKey = 4;
        end
    end
elseif h.useCedrus == 0
    if h.mode == 1
        h.escKey     = KbName('ESCAPE');
        h.triggerKey = KbName('5%');
        h.key1       = KbName('1!');
        if h.run <=2
            h.key2       = KbName('2@');
        else
            h.useConfidence = 0;
            switch h.LYES
                case 0
                    h.NEWKey = KbName('1!');
                    h.OLDKey = KbName('2@');
                case 1
                    h.NEWKey = KbName('2@');
                    h.OLDKey = KbName('1!');
            end
        end
    elseif h.mode == 0
        h.escKey     = KbName('ESCAPE');
        h.triggerKey = KbName('5%');
        h.key1       = KbName('1!');
        if h.run <= 2
            h.key2       = KbName('2@');
        else
            if h.useConfidence
                % new/old task with confidence
                switch h.LYES
                    case 0
                        h.NEWhighKey = KbName('q');
                        h.NEWmedKey  = KbName('w');
                        h.NEWlowKey  = KbName('e');
                        h.OLDlowKey  = KbName('i');
                        h.OLDmedKey  = KbName('o');
                        h.OLDhighKey = KbName('p');
                    case 1
                        h.NEWhighKey = KbName('p');
                        h.NEWmedKey  = KbName('o');
                        h.NEWlowKey  = KbName('i');
                        h.OLDlowKey  = KbName('e');
                        h.OLDmedKey  = KbName('w');
                        h.OLDhighKey = KbName('q');
                end
            else
                switch h.LYES
                    case 0
                        h.NEWKey = KbName('q');
                        h.OLDKey = KbName('p');
                    case 1
                        h.NEWKey = KbName('p');
                        h.OLDKey = KbName('q');
                end
            end
        end
    end
end

%% parameters
h.initFixDur = 10;
h.endFixDur  = 10;
if ismember(h.run,[3 4])
    h.probeDur = inf;
    h.ITI      = 1;
end

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

h.filePrefix    = sprintf('sub-%s_task-Bang_run-', h.subject);

userDir = char(java.lang.System.getProperty('user.home'));
logDir  = fullfile(userDir, 'Desktop', 'Data', sprintf('sub-%s', h.subject));
if ~exist(logDir,'dir')
    mkdir(logDir);
end

[h.fidLog, h.fname, h.timestampStr] = openLogfile(h.filePrefix,logDir);
h.saveFile = fullfile([h.fname,'_design.mat']);

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
if screenNumber<0 % does this ever happen??
    screenNumber = 0;
end

if h.mode>0
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
    h.movieFile  = fullfile(h.stimDir,'movie','short.avi');
    fprintf('Loading movie!...\n');
    fprintf('\t video... \t');
    tic
    % the PTB3 Video functions do not work on Windows
    % h.mov = Screen('OpenMovie', h.window, h.movieFile);
    % instead, we'll need to read the movie frame by frame with Matlab's VideoReader and make textures on the fly
    % open video object and read total number of frames
    vidObj        = VideoReader(h.movieFile);
    h.movieWidth  = vidObj.Width;
    h.movieHeight = vidObj.Height;
    h.frameRate   = vidObj.FrameRate;
    
    nFrames  = 11971;
    h.mov    = struct('tex',cell(1,nFrames),'cdata',cell(1,nFrames));
    k = 1;
    while hasFrame(vidObj)
        if mod(k,120)==1
            DrawFormattedText(h.window,sprintf('LOADING VIDEO\n\n%d%% complete', ceil(100*k/nFrames)),'center','center',[255 255 255],42);
            Screen('Flip',h.window);
        end
        tmp = readFrame(vidObj);
        % memory saving trick: since grayscale, only put 1 frame in memory
        h.mov(k).cdata = tmp(:,:,1);
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
    for iFrame = 1:h.nFrames,
        if iFrame <= h.nBuffered,
            h.mov(iFrame).tex    = Screen('MakeTexture', h.window, repmat(h.mov(iFrame).cdata,[1 1 3]));
            h.loaded(iFrame) = 1;
        else
            h.mov(iFrame).tex = 0;
            h.loaded(iFrame) = 0;
        end
    end
    elapsed = toc;
    fprintf('done in %.1fs\n',elapsed);
    
    %% loading audio
    if ~h.usePsychAudio
        
        fprintf('\t audio... \t');
        DrawFormattedText(h.window,'LOADING AUDIO','center','center',[255 255 255],42);
        Screen('Flip',h.window);
        tic
        % open audio object
        switch h.mode
            case 1
                if exist(strrep(h.movieFile,'.avi','_filt.wav'),'file'),
                    [y, fs] = audioread(strrep(h.movieFile,'.avi','_filt.wav'));
                else
                    [y, fs] = audioread(h.movieFile);
                    y = filter_audio(strrep(h.movieFile,'.avi','_filt.wav'),y,fs);
                end
            otherwise
                if exist(strrep(h.movieFile,'.avi','.wav'),'file'),
                    [y, fs] = audioread(strrep(h.movieFile,'.avi','.wav'));
                else
                    [y, fs] = audioread(h.movieFile);
                    audiowrite(strrep(h.movieFile,'.avi','.wav'),y,fs);
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
                if exist(strrep(h.movieFile,'.avi','_filt.wav'),'file'),
                    [y, fs] = psychwavread(strrep(h.movieFile,'.avi','_filt.wav'));
                else
                    [y, fs] = audioread(h.movieFile);
                    y = filter_audio(strrep(h.movieFile,'.avi','_filt.wav'),y,fs);
                    [y, fs] = psychwavread(strrep(h.movieFile,'.avi','_filt.wav'));
                end
            otherwise
                if exist(strrep(h.movieFile,'.avi','.wav'),'file'),
                    [y, fs] = psychwavread(strrep(h.movieFile,'.avi','.wav'));
                else
                    [y, fs] = audioread(h.movieFile);
                    audiowrite(strrep(h.movieFile,'.avi','.wav'),y,fs);
                    [y, fs] = psychwavread(strrep(h.movieFile,'.avi','.wav'));
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
    h.movieHeight = 480;
end

h.displayWidth  = 8/10 * h.w;
h.displayHeight = h.displayWidth / h.movieWidth * h.movieHeight;
if h.displayHeight > h.h, % accomodates different aspect ratio for the presentation screen
    h.displayHeight = 8/10 * h.h;
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
if h.instrDispH > h.h, % accomodates different aspect ratio for the presentation screen
    h.instrDispH = 8/10 * h.h;
    h.instrDispW  = h.instrDispH / h.instrH * h.instrW;
end
h.instrRect = [h.W-ceil(h.instrDispW/2) h.H-ceil(h.instrDispH/2) h.W+ceil(h.instrDispW/2) h.H+ceil(h.instrDispH/2)];

h.instr(1)  = Screen('MakeTexture', h.window, img);

if ismember(h.run,[1 2]), % after fMRI: questions
    % questions
    if h.useCedrus
        img = imread(fullfile(h.stimDir,'instructions',sprintf('instructionsQ_SU%d.png',h.useCedrus)));
    else
        if h.mode == 1
            img = imread(fullfile(h.stimDir,'instructions','instructionsQ_MRI.png'));
        else
            img = imread(fullfile(h.stimDir,'instructions','instructionsQ_db.png'));
        end
    end
elseif ismember(h.run,[3 4]), % after SU: new/old task
    % new/old
    if h.useCedrus
        img = imread(fullfile(h.stimDir,'instructions',sprintf('instructionsNO_LYES%d_SU%d.png',h.LYES,h.useCedrus)));
    else
        if h.mode == 1
            img = imread(fullfile(h.stimDir,'instructions',sprintf('instructionsNO_LYES%d_MRI.png',h.LYES)));
        else
            img = imread(fullfile(h.stimDir,'instructions',sprintf('instructionsNO_LYES%d_db%d.png',h.LYES,h.useConfidence)));
        end
    end
end
h.instr(2)  = Screen('MakeTexture', h.window, img);

%% QUESTIONS
if ismember(h.run,[1 2]),
    h.questions{1}{1}     = 'What are the boys standing behind when they shoot their toy guns?';
    h.questions{1}{2}{1}  = 'Tree';
    h.questions{1}{2}{2}  = 'Bush';
    h.questions{1}{2}{3}  = 'House';
    h.questions{1}{2}{4}  = 'Fence';
    h.questions{1}{3}     = 1;
    %
    h.questions{2}{1}     = 'What kind of hat is the boy wearing throughout the movie?';
    h.questions{2}{2}{1}  = 'Baseball Cap';
    h.questions{2}{2}{2}  = 'Private Hat';
    h.questions{2}{2}{3}  = 'Cowboy Hat';
    h.questions{2}{2}{4}  = 'Newsboy Hat';
    h.questions{2}{3}     = 3;
    %
    h.questions{3}{1}     = 'What does the boy find in the uncle’s luggage when he’s unpacking?';
    h.questions{3}{2}{1}  = 'Knife';
    h.questions{3}{2}{2}  = 'Baseball';
    h.questions{3}{2}{3}  = 'New hat';
    h.questions{3}{2}{4}  = 'Real gun';
    h.questions{3}{3}     = 4;
    %
    h.questions{4}{1}     = 'Which toy animal does the boy ride in front of the supermarket?';
    h.questions{4}{2}{1}  = 'Cow';
    h.questions{4}{2}{2}  = 'Elephant';
    h.questions{4}{2}{3}  = 'Unicorn';
    h.questions{4}{2}{4}  = 'Horse';
    h.questions{4}{3}     = 4;
    %
    h.questions{5}{1}     = 'What does the supermarket clerk tell the boy to do? ';
    h.questions{5}{2}{1}  = 'Feed the meter';
    h.questions{5}{2}{2}  = 'Get off';
    h.questions{5}{2}{3}  = 'Find your parents';
    h.questions{5}{2}{4}  = 'Be careful';
    h.questions{5}{3}     = 1;
    %
    h.questions{6}{1}     = 'When the boy is on the ride, what does he drop on the ground?';
    h.questions{6}{2}{1}  = 'Dimes';
    h.questions{6}{2}{2}  = 'Bullet';
    h.questions{6}{2}{3}  = 'Gun';
    h.questions{6}{2}{4}  = 'Hat';
    h.questions{6}{3}     = 2;
    %
    h.questions{7}{1}     = 'What does the girl’s father give the boy to get him to get off the ride? ';
    h.questions{7}{2}{1}  = 'Lollipop';
    h.questions{7}{2}{2}  = 'Money';
    h.questions{7}{2}{3}  = 'Chocolate';
    h.questions{7}{2}{4}  = 'Nothing';
    h.questions{7}{3}     = 1;
    %
    h.questions{8}{1}     = 'What reason does the boy give for not getting off the ride?';
    h.questions{8}{2}{1}  = 'He paid for it';
    h.questions{8}{2}{2}  = 'It was his';
    h.questions{8}{2}{3}  = 'He got there first';
    h.questions{8}{2}{4}  = 'He wanted to play';
    h.questions{8}{3}     = 3;
    %
    h.questions{9}{1}     = 'What is the maid’s name?';
    h.questions{9}{2}{1}  = 'Mary';
    h.questions{9}{2}{2}  = 'Jackie';
    h.questions{9}{2}{3}  = 'Cleo';
    h.questions{9}{2}{4}  = 'Susan';
    h.questions{9}{3}     = 3;
    %
    h.questions{10}{1}     = 'What breaks when the boy shoots the gun at the end?';
    h.questions{10}{2}{1}  = 'Statue';
    h.questions{10}{2}{2}  = 'Mirror';
    h.questions{10}{2}{3}  = 'Mask';
    h.questions{10}{2}{4}  = 'Picture frame';
    h.questions{10}{3}     = 2;
    %
    h.questions{11}{1}     = 'The father is holding the gun at the end of the movie; what is the uncle holding?';
    h.questions{11}{2}{1}  = 'Mask';
    h.questions{11}{2}{2}  = 'Glass of wine';
    h.questions{11}{2}{3}  = 'His hat';
    h.questions{11}{2}{4}  = 'The bullet';
    h.questions{11}{3}     = 1;
    %
    h.questions{12}{1}     = 'What is the boy standing behind when he shoots the gun at the end?';
    h.questions{12}{2}{1}  = 'Door frame';
    h.questions{12}{2}{2}  = 'Kitchen table';
    h.questions{12}{2}{3}  = 'Dining room chair';
    h.questions{12}{2}{4}  = 'Couch';
    h.questions{12}{3}     = 4;
    %
    h.questions{13}{1}     = 'What is the supermarket clerk pushing when the boy is on the ride?';
    h.questions{13}{2}{1}  = 'Milk crates';
    h.questions{13}{2}{2}  = 'Shopping carts';
    h.questions{13}{2}{3}  = 'A floor display';
    h.questions{13}{2}{4}  = 'Cart full of apples';
    h.questions{13}{3}     = 2;
    %
    h.questions{14}{1}     = ' Who does the boy run toward at the end, after shooting the gun?';
    h.questions{14}{2}{1}  = 'The maid';
    h.questions{14}{2}{2}  = 'The father';
    h.questions{14}{2}{3}  = 'The mother';
    h.questions{14}{2}{4}  = 'The uncle';
    h.questions{14}{3}     = 3; % correct answer
    
    h.questions = h.questions(h.run:2:end);
    
elseif ismember(h.run,[3 4]),
    
    h.NO         = mod(randperm(40),2); % 0 new, 1 old
    h.NOfileList = cell(1,40);
    h.NOtexList  = zeros(1,40);
    % prepare textures for NO task
    switch h.run
        case 3
            oldInds = [4 23 40 21 20 22  9 29 15 12 18 27  1  8 25 34 38 14 32 36];
            newInds = [10 11 31 38 30  8 22 12 27 28 18 24 26  4 16 20 29 34 40 21];
        case 4
            oldInds = [35 30 16  2 10  5 24  6  3 13 19 31  7 17 26 37 11 28 33 39];
            newInds = [2  6 14  9 17  7 35 13 39  1  3 25 37  5 19 23 32 36 15 33];
    end
    oldOrder = oldInds(randperm(length(oldInds)));
    newOrder = newInds(randperm(length(newInds)));
    for i = 1:length(h.NOtexList),
        switch h.NO(i)
            case 0 % new
                h.NOfileList{i} = fullfile(h.stimDir,'newold',sprintf('new%03d.png',newOrder(sum(h.NO(1:i)==0))));
            case 1 % old
                h.NOfileList{i} = fullfile(h.stimDir,'newold',sprintf('old%03d.png',oldOrder(sum(h.NO(1:i)==1))));
        end
        img = imread(h.NOfileList{i});
        h.NOtexList(i) = Screen('MakeTexture', h.window, img);
    end
    
    % make 2 or 6 rectangles to display text
    if h.useConfidence
        h.rectText{1} = [0.00*h.w 0 0.15*h.w 0.1*h.h];
        h.rectText{2} = [0.15*h.w 0 0.30*h.w 0.1*h.h];
        h.rectText{3} = [0.30*h.w 0 0.45*h.w 0.1*h.h];
        h.rectText{4} = [0.55*h.w 0 0.70*h.w 0.1*h.h];
        h.rectText{5} = [0.70*h.w 0 0.85*h.w 0.1*h.h];
        h.rectText{6} = [0.85*h.w 0 1.0*h.w 0.1*h.h];
    else
        h.rectText{1} = [0.0*h.w 0 0.2*h.w 0.1*h.h];
        h.rectText{2} = [0.8*h.w 0 1.0*h.w 0.1*h.h];
    end
end

h.eyeLinkMode  = h.useEyelink;

h.TTL.trigger     = 33;
%% triggers
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
