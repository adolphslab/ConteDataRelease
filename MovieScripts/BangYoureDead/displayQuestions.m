function h = displayQuestions(h,offset,fontsize,spacing)

if nargin<2
    offset=0;
end
if nargin<3
    fontsize=18;
end
if nargin<4
    spacing=32;
end
sansSerifFont = 'Arial';
Screen(h.window, 'TextFont',sansSerifFont);
Screen(h.window,'TextSize',fontsize);
r=Screen(h.window,'Rect');

choices = {'    a) ','    b) ','    c) ','    d) '};

for i=1:length(h.questions)
    
    sentTTL  = 0;
    responded = 0;
    selected = 1;
    while 1
        Screen(h.window, 'FillRect', h.bgColor);
        j = 1;
        Screen(h.window,'DrawText', h.questions{i}{1}, r(3)/10, r(4)/21 + (j-1)*spacing + offset , h.fgColor);
        j = 2;
        for k = 1:4,
            j = j+1;
            if k == selected,
                if ~responded 
                    Screen(h.window,'DrawText', [choices{k},h.questions{i}{2}{k}], r(3)/10, r(4)/21 + (j-1)*spacing + offset , [0 127 255]);
                else
                    if selected == h.questions{i}{3}, % correct -- green
                        Screen(h.window,'DrawText', [choices{k},h.questions{i}{2}{k}], r(3)/10, r(4)/21 + (j-1)*spacing + offset , [0 255 0]);
                    else
                        Screen(h.window,'DrawText', [choices{k},h.questions{i}{2}{k}], r(3)/10, r(4)/21 + (j-1)*spacing + offset , [255 0 0]);
                    end
                end
            else
                Screen(h.window,'DrawText', [choices{k},h.questions{i}{2}{k}], r(3)/10, r(4)/21 + (j-1)*spacing + offset , h.fgColor);
            end
        end
        Screen(h.window, 'Flip', 0);
        if responded
            % display feedback for 1s
            WaitSecs(1);
            break
        end
        if ~sentTTL
            sendTTLsJD(h.TTL.startQ,[i h.questions{i}{3}],h);
            sentTTL = 1;
        end
        % wait for a keypress
        % 1/green goes down
        % 2/red confirms choice
        keys = waitAndCheckKeys(h,inf,[h.key1 h.key2 h.escKey],0);
        if ismember(h.escKey,keys),
            h.endSignal = 1;endTask(h);return
        end
        if ismember(h.key1,keys)
            selected = mod(selected + 1,4);
            if selected == 0, selected = 4;end
            sendTTLsJD(h.TTL.keypress,[1 selected],h);
        end
        if ismember(h.key2,keys)
            h.Qresponse(i) = selected;
            h.Qcorrect(i)  = (selected == h.questions{i}{3});
            sendTTLsJD(h.TTL.resp,[2 selected selected == h.questions{i}{3}],h);
            responded = 1;
        end
    end
end

Screen('TextSize',h.window,h.textSize);