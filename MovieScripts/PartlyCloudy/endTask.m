function endTask(h)

if h.endSignal
    writeLog(h.fidLog,0,'aborted by user');
end

sendTTLsJD(h.TTL.endExp,0,h)

if h.eyeLinkMode
    %disp(['Receving file and store to:' edffilename ' to ' edffilename_local]);
    Eyelink('ReceiveFile', h.edfFile, [h.fname,'_gaze.edf']);
    Eyelink('Message', 'Regular Stop');
    Eyelink('StopRecording');
    Eyelink('CloseFile');    
    Eyelink('Shutdown');  
end

if h.playMovie
    if ~h.usePsychAudio
        stop(h.audObj);
    else
        PsychPortAudio('Stop',h.audObj);
        PsychPortAudio('Close', h.audObj);
    end
end

% Final cleanup of PTB and file streams
Priority(0);
ShowCursor;
sca
fclose('all');

if h.useCedrus
    CedrusResponseBox('CloseAll');
end

% if h.useMotionSensor
%     sensor_disconnect(h.deviceManager,h.myDevice);
% end
% clear unnecessary fields
if h.playMovie
    h = rmfield(h,'mov');
    h = rmfield(h,'audObj');
end
save(h.saveFile,'h','-v7.3');

if h.mode==1 && ~strcmp(h.subject,'test')
    try
        disp('Backing up data... please wait.');
        if h.eyeLinkMode
            bob_sendemail({'conte3@caltech.edu','jcrdubois@gmail.com'},sprintf('%s : Pixar run %d, mode %d',h.subject,h.run,h.mode),'see attached', {h.saveFile, strrep(h.saveFile,'_design.mat','_events.txt'), strrep(h.saveFile,'_design.mat','_gaze.edf')});
        else
            bob_sendemail({'conte3@caltech.edu','jcrdubois@gmail.com'},sprintf('%s : Pixar run %d, mode %d',h.subject,h.run,h.mode),'see attached', {h.saveFile, strrep(h.saveFile,'_design.mat','_events.txt')});
        end
        disp('All done!');
    catch
        disp('Could not email data... internet may not be connected.');
    end
end
