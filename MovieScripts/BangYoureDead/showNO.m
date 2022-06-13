function h = showNO(h)

h.NOcorrect = NaN(1,length(h.NO));
h.NORT      = NaN(1,length(h.NO));
if h.useConfidence
    h.NOconf = NaN(1,length(h.NO));
end

for i = 1:length(h.NO),
    
    %% PRESENT IMAGE
    Screen('DrawTexture', h.window,  h.NOtexList(i), [], h.rect);
    if h.LYES==1
        if h.useCedrus
            if ~h.useConfidence
                DrawFormattedText(h.window,'YES','center','center',[0,255,0],[],[],[],[],[],h.rectText{1});
                %Screen('DrawText',h.window, 'OLD', h.w*0.09 , h.h*0.1  , [0,255,0]);
            else
                DrawFormattedText(h.window,'YES\n+++','center','center',[0,255,0],[],[],[],[],[],h.rectText{1});
                DrawFormattedText(h.window,'YES\n++','center','center',[0,255,0],[],[],[],[],[],h.rectText{2});
                DrawFormattedText(h.window,'YES\n+','center','center',[0,255,0],[],[],[],[],[],h.rectText{3});
            end
        else
            if h.mode == 1
                DrawFormattedText(h.window,'YES','center','center',[0,127,255],[],[],[],[],[],h.rectText{1});
                %Screen('DrawText',h.window, 'OLD', h.w*0.09 , h.h*0.1  , [0,127,255]);
            else
                DrawFormattedText(h.window,'YES','center','center',[255,255,255],[],[],[],[],[],h.rectText{1});
                %Screen('DrawText',h.window, 'OLD', h.w*0.09 , h.h*0.1  , [255,255,255]);
            end
        end
        if h.useCedrus
            if ~h.useConfidence
                DrawFormattedText(h.window,'NO','center','center',[255,0,0],[],[],[],[],[],h.rectText{2});
                %Screen('DrawText',h.window, 'NEW' , h.w*0.76 , h.h*0.1  , [255,0,0]);
            else
                DrawFormattedText(h.window,'NO\n-','center','center',[255,0,0],[],[],[],[],[],h.rectText{4});
                DrawFormattedText(h.window,'NO\n--','center','center',[255,0,0],[],[],[],[],[],h.rectText{5});
                DrawFormattedText(h.window,'NO\n---','center','center',[255,0,0],[],[],[],[],[],h.rectText{6});
            end
        else
            if h.mode == 1
                DrawFormattedText(h.window,'NO','center','center',[255,255,0],[],[],[],[],[],h.rectText{2});
                %Screen('DrawText',h.window, 'NEW' , h.w*0.76 , h.h*0.1  , [255,255,0]);
            else
                DrawFormattedText(h.window,'NO','center','center',[255,255,255],[],[],[],[],[],h.rectText{2});
                %Screen('DrawText',h.window, 'NEW' , h.w*0.76 , h.h*0.1  , [255,255,255]);
            end
        end
        %Screen('DrawText',h.window, '??' , h.w*0.465, h.h*0.20 , [255,255,255]);
    else
        if h.useCedrus
            if ~h.useConfidence
                DrawFormattedText(h.window,'NO','center','center',[0,255,0],[],[],[],[],[],h.rectText{1});
                %Screen('DrawText',h.window, 'NEW' , h.w*0.09 , h.h*0.1  , [0,255,0]);
            else
                DrawFormattedText(h.window,'NO\n---','center','center',[255,0,0],[],[],[],[],[],h.rectText{1});
                DrawFormattedText(h.window,'NO\n--','center','center',[255,0,0],[],[],[],[],[],h.rectText{2});
                DrawFormattedText(h.window,'NO\n-','center','center',[255,0,0],[],[],[],[],[],h.rectText{3});
            end
        else
            if h.mode == 1
                DrawFormattedText(h.window,'NO','center','center',[0,127,255],[],[],[],[],[],h.rectText{1});
                %Screen('DrawText',h.window, 'NEW' , h.w*0.09 , h.h*0.1  , [0,127,255]);
            else
                DrawFormattedText(h.window,'NO','center','center',[255,255,255],[],[],[],[],[],h.rectText{1});
                %Screen('DrawText',h.window, 'NEW' , h.w*0.09 , h.h*0.1  , [255,255,255]);
            end
        end
        if h.useCedrus
            if ~h.useConfidence
                DrawFormattedText(h.window,'YES','center','center',[255,0,0],[],[],[],[],[],h.rectText{2});
                %Screen('DrawText',h.window, 'OLD', h.w*0.76 , h.h*0.1  , [255,0,0]);
            else
                DrawFormattedText(h.window,'YES\n+','center','center',[0,255,0],[],[],[],[],[],h.rectText{4});
                DrawFormattedText(h.window,'YES\n++','center','center',[0,255,0],[],[],[],[],[],h.rectText{5});
                DrawFormattedText(h.window,'YES\n+++','center','center',[0,255,0],[],[],[],[],[],h.rectText{6});
            end
        else
            if h.mode == 1
                DrawFormattedText(h.window,'YES','center','center',[255,255,0],[],[],[],[],[],h.rectText{2});
                %Screen('DrawText',h.window, 'OLD', h.w*0.76 , h.h*0.1  , [255,255,0]);
            else
                DrawFormattedText(h.window,'YES','center','center',[255,255,255],[],[],[],[],[],h.rectText{2});
                %Screen('DrawText',h.window, 'OLD', h.w*0.76 , h.h*0.1  , [255,255,255]);
            end
        end
        %Screen('DrawText',h.window, '??' , h.w*0.465, h.h*0.20 , [255,255,255]);
    end
    [~,startPROBE] = Screen('Flip',h.window,0,0);
    sendTTLsJD(h.TTL.startProbe,{num2str(i),num2str(h.NO(i)),h.NOfileList{i}},h);
    
    %% WAIT FOR RESPONSE
    if h.useConfidence
        [keys,RT,~] = waitAndCheckKeys(h,h.probeDur - (GetSecs - startPROBE),[h.NEWhighKey h.NEWmedKey h.NEWlowKey h.OLDlowKey h.OLDmedKey h.OLDhighKey h.escKey],1);
    else
        [keys,RT,~] = waitAndCheckKeys(h,h.probeDur - (GetSecs - startPROBE),[h.NEWKey h.OLDKey h.escKey],1);
    end
    if ~isempty(keys)
        sendTTLsJD(h.TTL.keypress,[keys(1) RT(1)],h);
        RT  = RT(1);
        key = keys(1);
        if ismember(h.escKey,keys),h.endSignal = 1;endTask(h);return;end
    else
        % give patient infinite time to answer if they haven't responded
        % yet
        prepare_fixationCross(h.window, [255 255 255],h.crossSize, h.W, h.H);
        if h.LYES==1
            if h.useCedrus
                if ~h.useConfidence
                    DrawFormattedText(h.window,'YES','center','center',[0,255,0],[],[],[],[],[],h.rectText{1});
                    %Screen('DrawText',h.window, 'OLD', h.w*0.09 , h.h*0.1  , [0,255,0]);
                else
                    DrawFormattedText(h.window,'YES\n+++','center','center',[0,255,0],[],[],[],[],[],h.rectText{1});
                    DrawFormattedText(h.window,'YES\n++','center','center',[0,255,0],[],[],[],[],[],h.rectText{2});
                    DrawFormattedText(h.window,'YES\n+','center','center',[0,255,0],[],[],[],[],[],h.rectText{3});
                end
            else
                if h.mode == 1
                    DrawFormattedText(h.window,'YES','center','center',[0,127,255],[],[],[],[],[],h.rectText{1});
                    %Screen('DrawText',h.window, 'OLD', h.w*0.09 , h.h*0.1  , [0,127,255]);
                else
                    DrawFormattedText(h.window,'YES','center','center',[255,255,255],[],[],[],[],[],h.rectText{1});
                    %Screen('DrawText',h.window, 'OLD', h.w*0.09 , h.h*0.1  , [255,255,255]);
                end
            end
            if h.useCedrus
                if ~h.useConfidence
                    DrawFormattedText(h.window,'NO','center','center',[255,0,0],[],[],[],[],[],h.rectText{2});
                    %Screen('DrawText',h.window, 'NEW' , h.w*0.76 , h.h*0.1  , [255,0,0]);
                else
                    DrawFormattedText(h.window,'NO\n-','center','center',[255,0,0],[],[],[],[],[],h.rectText{4});
                    DrawFormattedText(h.window,'NO\n--','center','center',[255,0,0],[],[],[],[],[],h.rectText{5});
                    DrawFormattedText(h.window,'NO\n---','center','center',[255,0,0],[],[],[],[],[],h.rectText{6});
                end
            else
                if h.mode == 1
                    DrawFormattedText(h.window,'NO','center','center',[255,255,0],[],[],[],[],[],h.rectText{2});
                    %Screen('DrawText',h.window, 'NEW' , h.w*0.76 , h.h*0.1  , [255,255,0]);
                else
                    DrawFormattedText(h.window,'NO','center','center',[255,255,255],[],[],[],[],[],h.rectText{2});
                    %Screen('DrawText',h.window, 'NEW' , h.w*0.76 , h.h*0.1  , [255,255,255]);
                end
            end
            %Screen('DrawText',h.window, '??' , h.w*0.465, h.h*0.20 , [255,255,255]);
        else
            if h.useCedrus
                if ~h.useConfidence
                    DrawFormattedText(h.window,'NO','center','center',[0,255,0],[],[],[],[],[],h.rectText{1});
                    %Screen('DrawText',h.window, 'NEW' , h.w*0.09 , h.h*0.1  , [0,255,0]);
                else
                    DrawFormattedText(h.window,'NO\n---','center','center',[0,255,0],[],[],[],[],[],h.rectText{1});
                    DrawFormattedText(h.window,'NO\n--','center','center',[0,255,0],[],[],[],[],[],h.rectText{2});
                    DrawFormattedText(h.window,'NO\n-','center','center',[0,255,0],[],[],[],[],[],h.rectText{3});
                end
            else
                if h.mode == 1
                    DrawFormattedText(h.window,'NO','center','center',[0,127,255],[],[],[],[],[],h.rectText{1});
                    %Screen('DrawText',h.window, 'NEW' , h.w*0.09 , h.h*0.1  , [0,127,255]);
                else
                    DrawFormattedText(h.window,'NO','center','center',[255,255,255],[],[],[],[],[],h.rectText{1});
                    %Screen('DrawText',h.window, 'NEW' , h.w*0.09 , h.h*0.1  , [255,255,255]);
                end
            end
            if h.useCedrus
                if ~h.useConfidence
                    DrawFormattedText(h.window,'YES','center','center',[255,0,0],[],[],[],[],[],h.rectText{2});
                    %Screen('DrawText',h.window, 'OLD', h.w*0.76 , h.h*0.1  , [255,0,0]);
                else
                    DrawFormattedText(h.window,'YES\n+','center','center',[255,0,0],[],[],[],[],[],h.rectText{4});
                    DrawFormattedText(h.window,'YES\n++','center','center',[255,0,0],[],[],[],[],[],h.rectText{5});
                    DrawFormattedText(h.window,'YES\n+++','center','center',[255,0,0],[],[],[],[],[],h.rectText{6});
                end
            else
                if h.mode == 1
                    DrawFormattedText(h.window,'YES','center','center',[255,255,0],[],[],[],[],[],h.rectText{2});
                    %Screen('DrawText',h.window, 'OLD', h.w*0.76 , h.h*0.1  , [255,255,0]);
                else
                    DrawFormattedText(h.window,'YES','center','center',[255,255,255],[],[],[],[],[],h.rectText{2});
                    %Screen('DrawText',h.window, 'OLD', h.w*0.76 , h.h*0.1  , [255,255,255]);
                end
            end
            %Screen('DrawText',h.window, '??' , h.w*0.465, h.h*0.20 , [255,255,255]);
        end
        Screen('Flip',h.window,0);
        sendTTLsJD(h.TTL.endProbe,0,h);
        % sending TTL / write info to log file
        if h.useConfidence
            [keys,RT,~] = waitAndCheckKeys(h,inf,[h.NEWhighKey h.NEWmedKey h.NEWlowKey h.OLDlowKey h.OLDmedKey h.OLDhighKey h.escKey],1);
        else
            [keys,RT,~] = waitAndCheckKeys(h,inf,[h.NEWKey h.OLDKey h.escKey],1);
        end
        RT  = RT(1) + h.probeDur;
        key = keys(1);
    end
    h.NORT(i) = RT;
    
    %% DETERMINE IF CORRECT
    correct = NaN;
    if h.NO(i)==1
        if h.useConfidence
            if ismember(key,[h.OLDlowKey h.OLDmedKey h.OLDhighKey]),
                correct=1;
            else
                correct=0;
            end
        else
            if key == h.OLDKey,
                correct=1;
            else
                correct=0;
            end
        end
    elseif h.NO(i)==0
        if h.useConfidence
            if ismember(key,[h.NEWlowKey h.NEWmedKey h.NEWhighKey]),
                correct=1;
            else
                correct=0;
            end
        else
            if key == h.NEWKey,
                correct=1;
            else
                correct=0;
            end
        end
    end
    h.NOcorrect(i) = correct;
    
    conf = NaN;
    if h.useConfidence
        switch key
            case {h.NEWlowKey,h.OLDlowKey}
                conf = 1;
            case {h.NEWmedKey,h.OLDmedKey}
                conf = 2;
            case {h.NEWhighKey,h.OLDhighKey}
                conf = 3;
        end
    end
    h.NOconf(i) = conf;
    sendTTLsJD(h.TTL.keypress,[i key RT correct conf],h);
    
    prepare_fixationCross(h.window, [255 255 255],h.crossSize, h.W, h.H);
    Screen('Flip',h.window,0);
    sendTTLsJD(h.TTL.startITI,0,h);
    WaitSecs(h.ITI);
    
end
