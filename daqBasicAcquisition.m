function [] = daqBasicAcquisition()
% A gui that aquires data from multiple channels of a NI-DAQ and saves it
% as a binary data file. It also displays the acquired data in real time.
%
% Version 0.9
% Last Modified On 6 August 2015
% Author: Dinesh Natesan

% Set Default Values
rundata = struct();
rundata.sampling_freq = 10e3; % Hz
rundata.viewTime = 5;  % Seconds
rundata.channels = arrayfun(@num2str,1:10,'UniformOutput',false);
rundata.deviceName = 'Dev1';
rundata.channelNum = 1;
rundata.saveFolder = pwd;
rundata.saveName = getFileName(rundata.saveFolder,rundata.channelNum);

% Initialize the control figure
handles = struct();
% --- CONTROL FIGURE -----------------------------

handles.controlfig = figure( ...
    'Tag', 'controlfig', ...
    'Units', 'Normalized', ...
    'Position', [0.005 0.5 0.200625 0.12083333333333333], ...
    'Name', 'DAQ Basic Acquisition', ...
    'MenuBar', 'none', ...
    'NumberTitle', 'off', ...
    'Color', get(0,'DefaultUicontrolBackgroundColor'));
% --- PANELS -------------------------------------

handles.basicAq = uipanel( ...
    'Parent', handles.controlfig, ...
    'Tag', 'uipanel2', ...
    'Units', 'Normalized', ...
    'Position', [0.0280373831775701,0.0896551724137931,0.937694704049844,0.841379310344828], ...
    'Title', 'Basic Acquisition');
% --- STATIC TEXTS -------------------------------------
handles.FileName = uicontrol( ...
    'Parent', handles.basicAq, ...
    'Tag', 'FileName', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.471380471380471,0.923809523809524,0.363636363636364,0.133333333333334], ...
    'String', 'FileName');

handles.setDir = uicontrol( ...
    'Parent', handles.basicAq, ...
    'Tag', 'setDir', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.286195286195286,0.580952380952381,0.683501683501684,0.314285714285715],...
    'HorizontalAlignment','left',...
    'String', {strjoin(strsplit(rundata.saveName(length(rundata.saveName)-...
    iff(length(rundata.saveName)-1>=75,75,length(rundata.saveName)-1):end),' '),'_')});

handles.channelNum = uicontrol( ...
    'Parent', handles.basicAq, ...
    'Tag', 'channelNum', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.0202020202020202,0.0666666666666665,0.306397306397306,0.152380952380952],...
    'String', {strcat('Input Channels: ',num2str(rundata.channelNum))});

handles.recordingStat = uicontrol( ...
    'Parent', handles.basicAq, ...
    'Tag', 'recordingStat', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.420875420875421,0.0571428571428572,0.548821548821549,0.133333333333334],...
    'ForegroundColor', [0.584 0.388 0.388], ...
    'String', {'Recording Status: Off'});


% --- PUSHBUTTONS -------------------------------------

handles.saveFolder = uicontrol( ...
    'Parent', handles.basicAq, ...
    'Tag', 'saveFolder', ...
    'Style', 'pushbutton', ...
    'Units', 'Normalized', ...
    'Position', [0.0202020202020202,0.571428571428572,0.255892255892256,0.352380952380953],...
    'String', 'Save Folder', ...
    'Callback', @saveFolder_Callback);

handles.start_basic = uicontrol( ...
    'Parent', handles.basicAq, ...
    'Tag', 'start_basic', ...
    'Style', 'pushbutton', ...
    'Units', 'Normalized', ...
    'Position', [0.414141414141414,0.219047619047619,0.245791245791246,0.333333333333333],...
    'ForegroundColor', [1 1 1], ...
    'BackgroundColor', [0 0.498 0], ...
    'String', 'Start', ...
    'Callback', @start_basic_Callback);

handles.stop_basic = uicontrol( ...
    'Parent', handles.basicAq, ...
    'Tag', 'stop_basic', ...
    'Style', 'pushbutton', ...
    'Units', 'Normalized', ...
    'Position', [0.713804713804714,0.219047619047619,0.245791245791246,0.333333333333333],...
    'ForegroundColor', [1 1 1], ...
    'BackgroundColor', [0.584 0.388 0.388], ...
    'String', 'Stop', ...
    'Callback', @stop_basic_Callback);


% --- POPUP MENU -------------------------------------
handles.channels = uicontrol( ...
    'Parent', handles.basicAq, ...
    'Tag', 'channels', ...
    'Style', 'popupmenu', ...
    'Units', 'Normalized', ...
    'Position', [0.0202020202020202,0.285714285714286,0.313131313131313,0.190476190476191],...
    'BackgroundColor', [1 1 1], ...
    'String', rundata.channels, ...
    'Callback', @channels_Callback, ...
    'CreateFcn', @channels_CreateFcn);

% Initializing done
% Save necessary data
setappdata(0,'handles',handles);
setappdata(0,'rundata',rundata);

end

%% Callback functions
%% ---------------------------------------------------------------------------
function saveFolder_Callback(hObject,evendata) %#ok<INUSD>
handles = getappdata(0,'handles');
rundata = getappdata(0,'rundata');
% Update folder and file
folder = uigetdir(rundata.saveFolder);
rundata.saveFolder = folder;
rundata.saveName = getFileName(folder,rundata.channelNum);
% Update file name
set(handles.setDir,'String', {strjoin(strsplit(rundata.saveName(length(rundata.saveName)-iff(length(rundata.saveName)-1>=75,75,length(rundata.saveName)-1):end),' '),'_')});
% Save necessary data
setappdata(0,'handles',handles);
setappdata(0,'rundata',rundata);
end

%% ---------------------------------------------------------------------------
function start_basic_Callback(hObject,evendata) %#ok<INUSD>
handles = getappdata(0,'handles');
rundata = getappdata(0,'rundata');
% Start the daq session
daq_session = daq.createSession('ni');
daq_session.addAnalogInputChannel(rundata.deviceName,0:rundata.channelNum-1,'Voltage');
daq_session.Rate = rundata.sampling_freq;
% Add plot data
fig_handle = figure('Units','Pixels','Position',[320 60 1260 960]);
if rundata.channelNum == 1
   plot_handles{1} = plot(0,0); 
else
    plot_handles = cell(rundata.channelNum,1);
   for i=1:rundata.channelNum
       subplot(rundata.channelNum,1,i);
       plot_handles{i} = plot(0,0);           
   end
end

% Open files
fid = fopen(rundata.saveName,'w');
lh = addlistener(daq_session,'DataAvailable',@(src, event)saveData(src, event, fid));

daq_session.IsContinuous = true;
daq_session.startBackground();
% Write into the ExperimentLogger file
experimentLogger(1);

% Set Status
set(handles.recordingStat,'ForegroundColor', [0 0.498 0], ...
    'String', {'Recording Status: ON'});    

handles.fig_handle = fig_handle;
handles.plot_handles = plot_handles;
rundata.daq_session = daq_session;
rundata.fid = fid;
rundata.lh = lh;
% Save necessary data
setappdata(0,'handles',handles);
setappdata(0,'rundata',rundata);

end

%% ---------------------------------------------------------------------------
function stop_basic_Callback(hObject,evendata) %#ok<INUSD>
handles = getappdata(0,'handles');
rundata = getappdata(0,'rundata');
% Stop the daq_session
daq_session = rundata.daq_session;
daq_session.stop();
% Close plots and delete handles
close(handles.fig_handle);
delete(rundata.lh);
fclose(rundata.fid);
% Write into the ExperimentLogger file
experimentLogger(0);

rundata = rmfield(rundata,'daq_session');
rundata = rmfield(rundata,'fid');
rundata = rmfield(rundata,'lh');
handles = rmfield(handles,'fig_handle');
handles = rmfield(handles,'plot_handles');

% Set Status
set(handles.recordingStat,'ForegroundColor', [0.584 0.388 0.388], ...
    'String', {'Recording Status: Off'});

% Update Filename
rundata.saveName = getFileName(rundata.saveFolder,rundata.channelNum);
% Update file name
set(handles.setDir,'String', {strjoin(strsplit(rundata.saveName(length(rundata.saveName)-iff(length(rundata.saveName)-1>=75,75,length(rundata.saveName)-1):end),' '),'_')});

% Save necessary data
setappdata(0,'handles',handles);
setappdata(0,'rundata',rundata);
end

%% ---------------------------------------------------------------------------
function channels_Callback(hObject,evendata) %#ok<INUSD>
handles = getappdata(0,'handles');
rundata = getappdata(0,'rundata');
% Get Channel Info
rundata.channelNum = str2double(rundata.channels(get(handles.channels,'Value')));
set(handles.channelNum,'String',{strcat('Input Channels: ',num2str(rundata.channelNum))});
rundata.saveName = getFileName(rundata.saveFolder,rundata.channelNum);
% Update file name
set(handles.setDir,'String', {strjoin(strsplit(rundata.saveName(length(rundata.saveName)-iff(length(rundata.saveName)-1>=75,75,length(rundata.saveName)-1):end),' '),'_')});
% Save necessary data
setappdata(0,'handles',handles);
setappdata(0,'rundata',rundata);
end

%% ---------------------------------------------------------------------------
function channels_CreateFcn(hObject,evendata) %#ok<INUSD>

end



%% Custom functions
function [file] = getFileName(folder,channelNum)
% function [file] = getFileName(folder)
list = dir(fullfile(folder,'*.bin'));
list = {list(:).name};
searchString = strcat('AcquisitionData_',date,'_(\d+)');
matchedTokens = regexp(list,searchString,'tokens');
numstrs = matchedTokens(~cellfun(@isempty,matchedTokens));
if isempty(numstrs)
    file = fullfile(folder,sprintf('AcquisitionData_%s_%04d_In-%02d.bin',date,1,channelNum));
else
    nums = sort(cellfun(@(x) str2double(x{:}),numstrs));
    file = fullfile(folder,sprintf('AcquisitionData_%s_%04d_In-%02d.bin',date,nums(end)+1,channelNum));
end

end

function saveData(src,event,fid)
% function plotData(src,event,fid)
% Logs and plots data

% Log data
logData(src,event,fid);
% Now plot data
handles = getappdata(0,'handles');
rundata = getappdata(0,'rundata');

time = event.TimeStamps';
for i=1:rundata.channelNum
    plot_data = event.Data(:,i)';
    plotDuration = rundata.viewTime*rundata.sampling_freq;
    % Obtain plotted data
    xdata = get(handles.plot_handles{i},'XData');
    ydata = get(handles.plot_handles{i},'YData');
    if (length(xdata)+length(plot_data))<=plotDuration
        newX = [xdata,time];
        newY = [ydata,plot_data];
    else
        newX = [xdata(length(xdata)-(plotDuration-length(time))+1:end),time];
        newY = [ydata(length(xdata)-(plotDuration-length(time))+1:end),plot_data];
    end
    set(handles.plot_handles{i},'XData',newX,'YData',newY);   
end
drawnow;

end

function [] = experimentLogger(status)
% function [] = experimentLogger()
% Log Stimulus Details and Start time
rundata = getappdata(0,'rundata');

% Determine filename
filename = fullfile(rundata.saveFolder,sprintf('AcquisitionLog_%s_.log',date));
fileid = fopen(filename,'at+');

if status == 1
    saveName = strsplit(rundata.saveName,filesep);
    saveName = saveName{end};
    % Save important initialization data
    fprintf(fileid,'%s: [Start] %s ', saveName, datestr(clock));
   
elseif status == 0
    fprintf(fileid,'[Stop] %s \n', datestr(clock));
end
fclose(fileid);

end

function [out] = iff(cond,a,b)
% function iff(cond,a,b)
% A custom written function that mimic the traditional C+ conditional 
% expression: out = cond?true:false
% 
% Dinesh Natesam, 6th Mar 2014

if cond
    out = a;
else
    out = b;
end

end