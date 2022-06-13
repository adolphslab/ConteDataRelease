function y = filter_audio(outFile,y,fs)
dbstop if error

%% do sensimetrics specific filtering to remedy weird frequency response of hardware
addpath(fullfile(pwd,'..','utilities','EQfiltering_Matlab_Utility'));
tic
% filter left channel
[hL,FsL] = load_filter('EQF_103L.bin');
if FsL~= fs,keyboard;end
tmpL = filter(hL,1,y(:,1));
% filter right channel
[hR,FsR] = load_filter('EQF_103R.bin');
if FsR~= fs,keyboard;end
tmpR = filter(hR,1,y(:,2));

y = [tmpL tmpR];
elapsed = toc;
fprintf('Pre-Filtering for Sensimetrics: done in %.1fs\n',elapsed);
    
audiowrite(outFile,y,fs);

