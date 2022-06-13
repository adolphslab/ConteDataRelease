function h = playmovie(h)
% use checkTiming.m to take a look at audio/video synchrony

if ~h.useCedrus
    keyList = zeros(1,256);
    keyList([h.escKey h.triggerKey])=1;
    KbQueueCreate([],keyList);
    KbQueueStart([]);
else
    % reset internal Cedrus timer
    CedrusResponseBox('ResetRTTimer', h.handle);
    % flush Cedrus buffer
    buttons = 1;
    while any(buttons(1,:))
        buttons = CedrusResponseBox('FlushEvents', h.handle);
    end
end

%% display first frame
if ~h.usePsychAudio
    resume(h.audObj);
else
    % Start audio playback for 1 repetitions of the sound data,
    % start it immediately (0) and wait for the playback to start, return onset
    % timestamp.
    PsychPortAudio('Start', h.audObj, [], 0, 1);
end
Screen('DrawTexture', h.window,  h.mov(h.curFrame).tex,[],h.rect);
[~,h.actualFrameTime(h.curFrame)]=Screen('Flip',h.window,0);
% log
if ~h.usePsychAudio
    sendTTLsJD(h.TTL.video,[h.curFrame h.audObj.CurrentSample],h);
else
    s = PsychPortAudio('GetStatus', h.audObj);
    sendTTLsJD(h.TTL.video,[h.curFrame s.ElapsedOutSamples],h);
end

h.curFrame   = h.curFrame + 1;
while h.curFrame <= h.nFrames
    if ~h.useCedrus
        % quick check for key escape or trigger
        [pressed, firstPress] = ...
            KbQueueCheck([]);
        if pressed
            % which keys were pressed?
            keys = find(firstPress>0);
            if ismember(h.triggerKey,keys)
                sendTTLsJD(h.TTL.keypress,h.triggerKey,h)
                keys = keys(~ismember(keys,h.triggerKey));
                firstPress(h.triggerKey) = 0;
            end
            if ~isempty(keys)
                KbQueueStop([]);h.endSignal = 1;endTask(h);return
            end
        end
    else
        evt = CedrusResponseBox('GetButtons', h.handle);
        if ~isempty(evt)
            while ~isempty(evt)
                if ismember(evt.button,h.escKey)
                    if evt.action==1
                        h.endSignal = 1;endTask(h);return
                    end
                end
            end
        end
    end
    
    if GetSecs - h.actualFrameTime(1) >= h.frameTime(h.curFrame)
        % don't have time to load, need to display immediately
        Screen('DrawTexture', h.window,  h.mov(h.curFrame).tex,[],h.rect);
        [~,h.actualFrameTime(h.curFrame)]=Screen('Flip',h.window,0);
    else
        nextFrame = find(h.loaded((h.curFrame+1):end)==0,1,'first');
        if ~isempty(nextFrame)
            nextFrame = h.curFrame + nextFrame;
            if h.curFrame>2
                % close texture to prevent memory overload
                Screen('Close',h.mov(h.curFrame-2).tex);
            end
            % make a new texture
            h.mov(nextFrame).tex    = Screen('MakeTexture', h.window, h.mov(nextFrame).cdata);
            h.loaded(nextFrame) = 1;
        end
        Screen('DrawTexture', h.window,  h.mov(h.curFrame).tex,[],h.rect);
        
        % set flip to happen at the right time
        when = h.actualFrameTime(1) + h.frameTime(h.curFrame);
        [~,h.actualFrameTime(h.curFrame)]=Screen('Flip',h.window,when);
        
        % log frame number approximately every second
        if round(mod(h.curFrame,h.frameRate))==1
            if ~h.usePsychAudio
                sendTTLsJD(h.TTL.video*10+mod(floor(h.curFrame/h.frameRate),10),[h.curFrame h.audObj.CurrentSample],h);
            else
                s = PsychPortAudio('GetStatus', h.audObj);
                sendTTLsJD(h.TTL.video*10+mod(floor(h.curFrame/h.frameRate),10),[h.curFrame s.ElapsedOutSamples],h);
            end
        end
    end
    h.curFrame = h.curFrame + 1;
end

if ~h.useCedrus
    KbQueueStop([]);
end
