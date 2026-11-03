function varargout = launchVegMitra()
% launchVegMitra.m
% Launcher script for VegMitra AI Based Smart Traffic Light Management System
% Phase 1 MATLAB App Designer Dashboard

disp('----------------------------------------------------');
disp('Launching VegMitra App...');
disp('Title: VegMitra - AI Based Smart Traffic Light Management System');
disp('----------------------------------------------------');

% Add current folder to MATLAB path
appPath = fileparts(mfilename('fullpath'));
addpath(appPath);

% Instantiate and display App
app = VegMitraApp();
assignin('base', 'app', app);

if nargout > 0
    varargout{1} = app;
end
end

