function [] = daqBasicEMG()
%
%
%
%
% Version 0.1
% Last Modified On 6 August 2014
% Author: Dinesh Natesan (dinesh@ncbs.res.in)
%
default_stimulus_protocol = 'chirp:10,0,100;sine:10,1:4,5:5:100;buffer:10';

% Set Default Values
rundata = struct();
rundata.sampling_freq = 10e3; % Hz
rundata.deviceName = 'Dev2';
rundata.viewTime = 5;  % Seconds
rundata.inputchannels = arrayfun(@num2str,1:10,'UniformOutput',false);
rundata.inputchannelNum = 1;
rundata.outputchannel = 0;
rundata.saveFolder = uigetdir;
rundata.saveName = getFileName(rundata.saveFolder,rundata.inputchannelNum,rundata.outputchannel);
rundata.expt_log = sprintf('EMGLog_%s_.log',date);
rundata.amplitude_input = 1;
% Calibration constants
rundata.speaker_input = [3,4];
rundata.speaker_output = [5,6];
rundata.calibrate_ao0 = false;
rundata.calibrate_ao1 = false;
rundata.calibrated_ao0 = false;    
rundata.calibrated_ao1 = false;    
rundata.use_calibration = false;
rundata.calibration_curve_ao0 = [];
rundata.calibration_curve_ao1 = [];
rundata.chirp_calibration_parameters.sam_freq = rundata.sampling_freq;
rundata.chirp_calibration_parameters.run_duration = 30;
rundata.chirp_calibration_parameters.start_freq = 0;
rundata.chirp_calibration_parameters.stop_freq = 100;
rundata.chirp_calibration_parameters.chirp_input_cutoff = 10;
% Check and obtain Calibration
[~,currentfile] = getCalibFile(rundata.saveFolder,'AO0');
if ~isempty(currentfile)
    rundata.calibfilename_ao0 = currentfile;
    disp('AO0 Calibration File found. Assuming standard calibration parameters and importing the curve');
    filename = fullfile(rundata.saveFolder,rundata.expt_log);
    fileid = fopen(filename,'at+');
    fprintf(fileid,'AO0 Calibration File found in the save folder: %s. Assuming standard calibration parameters and importing the curve.\n',currentfile);
    fclose(fileid);
    rundata.calibration_curve_ao0 = generateCalibrationCurve(currentfile,0,rundata.chirp_calibration_parameters);
    rundata.calibrated_ao0 = true;  
else
    rundata.calibfilename_ao0 = '';
end
[~,currentfile] = getCalibFile(rundata.saveFolder,'AO1');
if ~isempty(currentfile)
    rundata.calibfilename_ao1 = currentfile;
    disp('AO1 Calibration File found. Assuming standard calibration parameters and importing the curve');
    filename = fullfile(rundata.saveFolder,rundata.expt_log);
    fileid = fopen(filename,'at+');
    fprintf(fileid,'AO1 Calibration File found in the save folder: %s. Assuming standard calibration parameters and importing the curve.\n',currentfile);
    fclose(fileid);
    rundata.calibration_curve_ao1 = generateCalibrationCurve(currentfile,1,rundata.chirp_calibration_parameters);
    rundata.calibrated_ao1 = true;    
else
    rundata.calibfilename_ao1 = '';
end    
    
if rundata.calibrated_ao0 || rundata.calibrated_ao1
    rundata.use_calibration = true;    
end    
    
    

% Initialize the control figure
handles = struct();
% --- CONTROL FIGURE -----------------------------
handles.controlfig = figure( ...
    'Tag', 'controlfig', ...
    'Units', 'Pixels', ...
    'Position', [24,188,294,537],...
    'Name', 'Basic EMG Stimulus', ...
    'MenuBar', 'none', ...
    'NumberTitle', 'off', ...
    'Color', get(0,'DefaultUicontrolBackgroundColor'));
% --- PANELS -------------------------------------
handles.controlpanel = uipanel( ...
    'Parent', handles.controlfig, ...
    'Tag', 'controlpanel', ...
    'Units', 'Normalized', ...
    'Position', [0.023809523809524,0.662819089900111,0.948979591836735,0.325490196078431],...
    'Title', 'Control Panel');

handles.outputchannels = uibuttongroup( ...
    'Parent', handles.controlpanel, ...
    'Tag', 'outputchannels', ...
    'Units', 'Normalized', ...
    'Position', [0.0254545454545455,0.0469798657718121,0.545454545454545,0.315436241610739],...
    'Title', 'Output Channels',...
    'SelectionChangeFcn',@outputchannels_Callback);

handles.stimuluspanel = uipanel( ...
    'Parent', handles.controlfig, ...
    'Tag', 'stimuluspanel', ...
    'Units', 'Normalized', ...
    'Position', [0.023809523809524,0.207156308851224,0.952380952380952,0.451977401129944],...
    'Title', 'Stimulus');

handles.speakercalibration = uipanel( ...
    'Parent', handles.controlfig, ...
    'Tag', 'speakercalibration', ...
    'Units', 'Normalized', ...
    'Position', [0.023809523809524,0.011299435028249,0.948979591836735,0.193973634651601],...
    'Title', 'Speaker Calibration');

% --- STATIC TEXTS -------------------------------------
handles.FileName = uicontrol( ...
    'Parent', handles.controlpanel, ...
    'Tag', 'FileName', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.0145454545454545,0.570469798657718,0.392727272727273,0.0939597315436244],...
    'String', 'FileName');

handles.recordingStat = uicontrol( ...
    'Parent', handles.controlpanel, ...
    'Tag', 'recordingStat', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.363636363636364,0.939597315436244,0.592727272727273,0.0939597315436244],...
    'ForegroundColor', [0.584 0.388 0.388], ...
    'String', {'Recording Status: Off'});

handles.channelNum = uicontrol( ...
    'Parent', handles.controlpanel, ...
    'Tag', 'channelNum', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.487272727272727,0.563758389261745,0.330909090909091,0.107382550335570],...
    'String', {strcat('Input Channels: ',num2str(rundata.inputchannelNum))});

handles.setDir = uicontrol( ...
    'Parent', handles.controlpanel, ...
    'Tag', 'setDir', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.0181818181818182,0.342281879194631,0.952727272727273,0.221476510067114],...
    'String', {strjoin(strsplit(rundata.saveName(length(rundata.saveName)-...
    iff(length(rundata.saveName)-1>=90,90,length(rundata.saveName)-1):end),' '),'_')});

% Rest all text boxes are all static tags
handles.text16 = uicontrol( ...
    'Parent', handles.controlpanel, ...
    'Tag', 'text16', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.603636363636364,0.241610738255034,0.269090909090909,0.0939597315436244],...
    'String', 'Input Channels');

handles.text5 = uicontrol( ...
    'Parent', handles.stimuluspanel, ...
    'Tag', 'text5', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.0144927536231884,0.937219730941706,0.326086956521739,0.0627802690582962],...
    'String', 'Stimulus Protocol');

handles.text8 = uicontrol( ...
    'Parent', handles.stimuluspanel, ...
    'Tag', 'text8', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.0398550724637681,0.470852017937220,0.188405797101449,0.0627802690582962],...
    'String', 'Duration');

handles.text9 = uicontrol( ...
    'Parent', handles.stimuluspanel, ...
    'Tag', 'text9', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.318840579710145,0.470852017937220,0.293478260869565,0.0627802690582962],...
    'String', 'Start Frequency');

handles.text10 = uicontrol( ...
    'Parent', handles.stimuluspanel, ...
    'Tag', 'text10', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.652173913043478,0.470852017937220,0.293478260869565,0.0627802690582962],...
    'String', 'Stop Frequency');

handles.text11 = uicontrol( ...
    'Parent', handles.stimuluspanel, ...
    'Tag', 'text11', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.0398550724637681,0.215246636771300,0.188405797101449,0.0627802690582962],...
    'String', 'Duration');

handles.text14 = uicontrol( ...
    'Parent', handles.stimuluspanel, ...
    'Tag', 'text14', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.282608695652174,0.156950672645740,0.105072463768116,0.0852017937219730],...
    'String', 'Freq');

handles.text15 = uicontrol( ...
    'Parent', handles.stimuluspanel, ...
    'Tag', 'text15', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.463768115942029,0.0493273542600895,0.188405797101449,0.0627802690582962],...
    'String', 'Duration');

% --- PUSHBUTTONS -------------------------------------
handles.saveFolder = uicontrol( ...
    'Parent', handles.controlpanel, ...
    'Tag', 'saveFolder', ...
    'Style', 'pushbutton', ...
    'Units', 'Normalized', ...
    'Position', [0.0218181818181818,0.684563758389262,0.276363636363636,0.248322147651007],...
    'String', 'Save Folder', ...
    'Callback', @saveFolder_Callback);

handles.start_protocol = uicontrol( ...
    'Parent', handles.controlpanel, ...
    'Tag', 'start_protocol', ...
    'Style', 'pushbutton', ...
    'Units', 'Normalized', ...
    'Position', [0.360000000000000,0.697986577181208,0.265454545454545,0.234899328859060],...
    'ForegroundColor', [1 1 1], ...
    'BackgroundColor', [0 0.498 0], ...
    'String', 'Start', ...
    'Callback', @start_protocol_Callback);

handles.stop_protocol = uicontrol( ...
    'Parent', handles.controlpanel, ...
    'Tag', 'stop_protocol', ...
    'Style', 'pushbutton', ...
    'Units', 'Normalized', ...
    'Position', [0.680000000000000,0.697986577181208,0.265454545454545,0.234899328859060],...
    'ForegroundColor', [1 1 1], ...
    'BackgroundColor', [0.584 0.388 0.388], ...
    'String', 'Stop', ...
    'Callback', @stop_protocol_Callback);

% --- RADIO BUTTONS -------------------------------------
handles.ao0_channel = uicontrol( ...
    'Parent', handles.outputchannels, ...
    'Tag', 'ao0_channel', ...
    'Style', 'radiobutton', ...
    'Units', 'Normalized', ...
    'Position', [0.0273972602739726,0.310344827586207,0.335616438356164,0.793103448275862],...
    'String', 'AO0');

handles.ao1_channel = uicontrol( ...
    'Parent', handles.outputchannels, ...
    'Tag', 'ao1_channel', ...
    'Style', 'radiobutton', ...
    'Units', 'Normalized', ...
    'Position', [0.342465753424658,0.310344827586207,0.335616438356164,0.793103448275862],...
    'String', 'AO1');

handles.both_channel = uicontrol( ...
    'Parent', handles.outputchannels, ...
    'Tag', 'both_channel', ...
    'Style', 'radiobutton', ...
    'Units', 'Normalized', ...
    'Position', [0.643835616438356,0.310344827586207,0.335616438356164,0.793103448275862],...
    'String', 'Both');

% --- CHECKBOXES -------------------------------------
handles.chirp_stimulus = uicontrol( ...
    'Parent', handles.stimuluspanel, ...
    'Tag', 'chirp_stimulus', ...
    'Style', 'checkbox', ...
    'Units', 'Normalized', ...
    'Position', [0.0326086956521739,0.533632286995516,0.351449275362319,0.103139013452915],...
    'String', 'Chirp Stimulus', ...
    'Callback', @chirp_stimulus_Callback);

handles.sine_stimulus = uicontrol( ...
    'Parent', handles.stimuluspanel, ...
    'Tag', 'sine_stimulus', ...
    'Style', 'checkbox', ...
    'Units', 'Normalized', ...
    'Position', [0.0326086956521739,0.278026905829597,0.351449275362319,0.103139013452915],...
    'String', 'Sine Stimulus', ...
    'Callback', @sine_stimulus_Callback);

handles.buffer_stimulus = uicontrol( ...
    'Parent', handles.stimuluspanel, ...
    'Tag', 'buffer_stimulus', ...
    'Style', 'checkbox', ...
    'Units', 'Normalized', ...
    'Position', [0.0326086956521739,0.0313901345291480,0.351449275362319,0.103139013452915],...
    'String', 'Buffer Stimulus', ...
    'Callback', @buffer_stimulus_Callback);

% --- EDIT TEXTS -------------------------------------
handles.whole_stimulus = uicontrol( ...
    'Parent', handles.stimuluspanel, ...
    'Tag', 'whole_stimulus', ...
    'Style', 'edit', ...
    'Units', 'Normalized', ...
    'Position', [0.0326086956521739,0.650224215246639,0.934782608695652,0.273542600896861],...
    'BackgroundColor', [1 1 1], ...
    'String', {'Edit Text'}, ...
    'Callback', @whole_stimulus_Callback, ...
    'CreateFcn', @whole_stimulus_CreateFcn);

handles.chirp_duration = uicontrol( ...
    'Parent', handles.stimuluspanel, ...
    'Tag', 'chirp_duration', ...
    'Style', 'edit', ...
    'Units', 'Normalized', ...
    'Position', [0.0579710144927536,0.399103139013453,0.163043478260870,0.0582959641255605],...
    'BackgroundColor', [1 1 1], ...
    'String', {'Edit Text'}, ...
    'Callback', @chirp_duration_Callback, ...
    'CreateFcn', @chirp_duration_CreateFcn);

handles.chirp_start_freq = uicontrol( ...
    'Parent', handles.stimuluspanel, ...
    'Tag', 'chirp_start_freq', ...
    'Style', 'edit', ...
    'Units', 'Normalized', ...
    'Position', [0.380434782608696,0.394618834080718,0.163043478260870,0.0582959641255605],...
    'BackgroundColor', [1 1 1], ...
    'String', {'Edit Text'}, ...
    'Callback', @chirp_start_freq_Callback, ...
    'CreateFcn', @chirp_start_freq_CreateFcn);

handles.chirp_stop_freq = uicontrol( ...
    'Parent', handles.stimuluspanel, ...
    'Tag', 'chirp_stop_freq', ...
    'Style', 'edit', ...
    'Units', 'Normalized', ...
    'Position', [0.706521739130435,0.399103139013453,0.163043478260870,0.0582959641255605],...
    'BackgroundColor', [1 1 1], ...
    'String', {'Edit Text'}, ...
    'Callback', @chirp_stop_freq_Callback, ...
    'CreateFcn', @chirp_stop_freq_CreateFcn);

handles.sine_duration = uicontrol( ...
    'Parent', handles.stimuluspanel, ...
    'Tag', 'sine_duration', ...
    'Style', 'edit', ...
    'Units', 'Normalized', ...
    'Position', [0.0579710144927536,0.143497757847534,0.163043478260870,0.0582959641255605],...
    'BackgroundColor', [1 1 1], ...
    'String', {'Edit Text'}, ...
    'Callback', @sine_duration_Callback, ...
    'CreateFcn', @sine_duration_CreateFcn);

handles.sine_freq = uicontrol( ...
    'Parent', handles.stimuluspanel, ...
    'Tag', 'sine_freq', ...
    'Style', 'edit', ...
    'Units', 'Normalized', ...
    'Position', [0.402173913043478,0.143497757847534,0.557971014492754,0.121076233183857],...
    'BackgroundColor', [1 1 1], ...
    'String', {'Edit Text'}, ...
    'Callback', @sine_freq_Callback, ...
    'CreateFcn', @sine_freq_CreateFcn);

handles.buffer_duration = uicontrol( ...
    'Parent', handles.stimuluspanel, ...
    'Tag', 'buffer_duration', ...
    'Style', 'edit', ...
    'Units', 'Normalized', ...
    'Position', [0.684782608695652,0.0493273542600895,0.163043478260870,0.0582959641255605],...
    'BackgroundColor', [1 1 1], ...
    'String', {'Edit Text'}, ...
    'Callback', @buffer_duration_Callback, ...
    'CreateFcn', @buffer_duration_CreateFcn);

% --- POPUP MENU -------------------------------------
handles.inputchannels = uicontrol( ...
    'Parent', handles.controlpanel, ...
    'Tag', 'inputchannels', ...
    'Style', 'popupmenu', ...
    'Units', 'Normalized', ...
    'Position', [0.600000000000000,0.0939597315436244,0.338181818181818,0.134228187919463],...
    'BackgroundColor', [1 1 1], ...
    'String',  rundata.inputchannels, ...
    'Callback', @inputchannels_Callback, ...
    'CreateFcn', @inputchannels_CreateFcn);

% --- Speaker Calibration -------------------------------------
% Text field
handles.calibstate_ao0 = uicontrol( ...
    'Parent', handles.speakercalibration, ...
    'Tag', 'text8', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.541818181818182,0.337209302325581,0.414545454545455,0.162790697674419],...
    'ForegroundColor', iff(rundata.calibrated_ao0,[0 0.498 0],[0.584 0.388 0.388]), ...
    'String', iff(rundata.calibrated_ao0,'Calibrated!','Not yet calibrated!'));

handles.calibstate_ao1 = uicontrol( ...
    'Parent', handles.speakercalibration, ...
    'Tag', 'text9', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.541818181818182,0.127906976744186,0.414545454545455,0.162790697674419],...
    'ForegroundColor', iff(rundata.calibrated_ao1,[0 0.498 0],[0.584 0.388 0.388]), ...
    'String', iff(rundata.calibrated_ao1,'Calibrated!','Not yet calibrated!'));

handles.text20 = uicontrol( ...
    'Parent', handles.speakercalibration, ...
    'Tag', 'text10', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.014545454545455,0.825581395348837,0.309090909090909,0.162790697674419],...
    'String', 'Amplitude (P2P)');

handles.text21 = uicontrol( ...
    'Parent', handles.speakercalibration, ...
    'Tag', 'text11', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.018181818181818,0.627906976744185,0.250909090909091,0.162790697674419],...
    'String', 'Speaker Input');

handles.text22 = uicontrol( ...
    'Parent', handles.speakercalibration, ...
    'Tag', 'text11', ...
    'Style', 'text', ...
    'Units', 'Normalized', ...
    'Position', [0.520000000000000,0.616279069767442,0.290909090909091,0.162790697674419],...
    'String', 'Speaker Output');

% Text input
handles.amplitude_input = uicontrol( ...
    'Parent', handles.speakercalibration, ...
    'Tag', 'amplitude_input', ...
    'Style', 'edit', ...
    'Units', 'Normalized', ...
    'Position', [0.338181818181818,0.825581395348837,0.163636363636364,0.151162790697674],...
    'BackgroundColor', [1 1 1], ...
    'String', num2str(rundata.amplitude_input), ...
    'Callback', @amplitude_input_Callback);

handles.speaker_input = uicontrol( ...
    'Parent', handles.speakercalibration, ...
    'Tag', 'speaker_input', ...
    'Style', 'edit', ...
    'Units', 'Normalized', ...
    'Position', [0.341818181818182,0.627906976744185,0.163636363636364,0.151162790697674],...
    'BackgroundColor', [1 1 1], ...
    'String', strjoin(strsplit(num2str(rundata.speaker_input)),','), ...
    'Callback', @speaker_input_Callback);

handles.speaker_output = uicontrol( ...
    'Parent', handles.speakercalibration, ...
    'Tag', 'speaker_output', ...
    'Style', 'edit', ...
    'Units', 'Normalized', ...
    'Position', [0.818181818181820,0.627906976744185,0.163636363636364,0.151162790697674],...
    'BackgroundColor', [1 1 1], ...
    'String', strjoin(strsplit(num2str(rundata.speaker_output)),','), ...
    'Callback', @speaker_output_Callback);

% Check Boxes
handles.calibrate_ao0 = uicontrol( ...
    'Parent', handles.speakercalibration, ...
    'Tag', 'calibrate_ao0', ...
    'Style', 'checkbox', ...
    'Units', 'Normalized', ...
    'Position', [0.363636363636364,0.290697674418604,0.160000000000000,0.267441860465116],...
    'String', 'AO0', ...
    'Callback', @calibrate_ao0_Callback);

handles.calibrate_ao1 = uicontrol( ...
    'Parent', handles.speakercalibration, ...
    'Tag', 'calibrate_ao1', ...
    'Style', 'checkbox', ...
    'Units', 'Normalized', ...
    'Position', [0.363636363636364,0.069767441860465,0.178181818181818,0.267441860465116],...
    'String', 'AO1', ...
    'Callback', @calibrate_ao1_Callback);

handles.use_calibration = uicontrol( ...
    'Parent', handles.speakercalibration, ...
    'Tag', 'use_calibration', ...
    'Style', 'checkbox', ...
    'Units', 'Normalized', ...
    'Position', [0.523636363636364,0.767441860465115,0.454545454545455,0.267441860465116],...
    'String', 'Use Calibration?', ...
    'Value',rundata.use_calibration,...
    'Callback', @use_calibration_Callback);

% Push Button
handles.calibrateSpeakers = uicontrol( ...
    'Parent', handles.speakercalibration, ...
    'Tag', 'calibrateSpeakers', ...
    'Style', 'pushbutton', ...
    'Units', 'Normalized', ...
    'Position', [0.029090909090909,0.093023255813953,0.320000000000000,0.453488372093023],...
    'String', 'Calibrate', ...
    'Callback', @calibrateSpeakers_Callback);


% Save necessary data
setappdata(0,'handles',handles);
setappdata(0,'rundata',rundata);

% Initialize the default protocol
stimulusParser(default_stimulus_protocol);
stimulusUpdater();

end

%% Callback functions

% Control Figure
%% ---------------------------------------------------------------------------
function saveFolder_Callback(hObject,evendata) %#ok<INUSD>
handles = getappdata(0,'handles');
rundata = getappdata(0,'rundata');
% Update folder and file
folder = uigetdir(rundata.saveFolder);
rundata.saveFolder = folder;
rundata.saveName = getFileName(folder,rundata.inputchannelNum,rundata.outputchannel);
% Update file name
set(handles.setDir,'String', {strjoin(strsplit(rundata.saveName(length(rundata.saveName)-...
    iff(length(rundata.saveName)-1>=90,90,length(rundata.saveName)-1):end),' '),'_')});
% Save necessary data
setappdata(0,'handles',handles);
setappdata(0,'rundata',rundata);
end

%% ---------------------------------------------------------------------------
function start_protocol_Callback(hObject,evendata) %#ok<INUSD>
handles = getappdata(0,'handles');
rundata = getappdata(0,'rundata');
% Start the daq session
daq_session = daq.createSession('ni');
daq_session.addAnalogInputChannel(rundata.deviceName,0:rundata.inputchannelNum-1,'Voltage');
daq_session.addAnalogOutputChannel(rundata.deviceName,rundata.outputchannel,'Voltage');
daq_session.Rate = rundata.sampling_freq;
% Get output data
if rundata.use_calibration
    if (rundata.calibrated_ao0) && ((length(rundata.outputchannel)==2)||rundata.outputchannel(1)==0)
        out_data = generateOutputData(rundata.calibration_curve_ao0);        
    elseif ((length(rundata.outputchannel)==2)||rundata.outputchannel(1)==0)
        out_data = generateOutputData();
    else 
        out_data = [];
    end
    
    if rundata.calibrated_ao1 && ((length(rundata.outputchannel)==2)||rundata.outputchannel(1)==1)
        out_data=iff(isempty(out_data),generateOutputData(rundata.calibration_curve_ao1),...
            [out_data,generateOutputData(rundata.calibration_curve_ao1)]);        
    elseif ((length(rundata.outputchannel)==2)||rundata.outputchannel(1)==1)
        out_data=iff(isempty(out_data),generateOutputData(),[out_data,generateOutputData()]);
    end
else    
    out_data = generateOutputData();
    out_data = iff(length(rundata.outputchannel)==2,[out_data,out_data],out_data);
end
% Queue Data
queueOutputData(daq_session,out_data);

% Add plot data
fig_handle = figure('Units','Pixels','Position',[320 60 1260 960]);
if rundata.inputchannelNum == 1
    plot_handles{1} = plot(0,0);
else
    plot_handles = cell(rundata.inputchannelNum,1);
    for i=1:rundata.inputchannelNum
        subplot(rundata.inputchannelNum,1,i);
        plot_handles{i} = plot(0,0);
    end
end

% Open files
fid = fopen(rundata.saveName,'w');
lh = addlistener(daq_session,'DataAvailable',@(src, event)saveData(src, event, fid));

daq_session.IsContinuous = false;
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

% Set up a timer
t = timer;
t.Period = 5;
t.StartDelay = 5;
t.ExecutionMode = 'fixedSpacing';
t.TimerFcn = @(~,~)checkIfDone;
rundata.timer = t;
% Save necessary data
setappdata(0,'handles',handles);
setappdata(0,'rundata',rundata);
% Start timer
start(t);
end

%% ---------------------------------------------------------------------------
function stop_protocol_Callback(hObject,evendata) %#ok<INUSD>
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
rundata.saveName = getFileName(rundata.saveFolder,rundata.inputchannelNum,rundata.outputchannel);
% Update file name
set(handles.setDir,'String', {strjoin(strsplit(rundata.saveName(length(rundata.saveName)-...
    iff(length(rundata.saveName)-1>=90,90,length(rundata.saveName)-1):end),' '),'_')});
% Save necessary data
setappdata(0,'handles',handles);
setappdata(0,'rundata',rundata);
end

function outputchannels_Callback(hObject,evendata) %#ok<INUSD>
handles = getappdata(0,'handles');
rundata = getappdata(0,'rundata');
currentSelection = get(handles.outputchannels,'SelectedObject');
switch currentSelection
    case handles.ao0_channel
        rundata.outputchannel = 0;
    case handles.ao1_channel
        rundata.outputchannel = 1;
    case handles.both_channel
        rundata.outputchannel = [0,1];
end
% Update Filename
rundata.saveName = getFileName(rundata.saveFolder,rundata.inputchannelNum,rundata.outputchannel);
% Update file name
set(handles.setDir,'String', {strjoin(strsplit(rundata.saveName(length(rundata.saveName)-...
    iff(length(rundata.saveName)-1>=90,90,length(rundata.saveName)-1):end),' '),'_')});
% Save necessary data
setappdata(0,'handles',handles);
setappdata(0,'rundata',rundata);
end

%% ---------------------------------------------------------------------------
function chirp_stimulus_Callback(hObject,evendata) %#ok<INUSD>
rundata = getappdata(0,'rundata');
if get(hObject,'Value')
    rundata.chirp_stimulus = true;
else
    rundata.chirp_stimulus = false;
    rundata.chirp_duration = 0;
end
% Save necessary data
setappdata(0,'rundata',rundata);
stimulusUpdater();
end

%% ---------------------------------------------------------------------------
function sine_stimulus_Callback(hObject,evendata) %#ok<INUSD>
rundata = getappdata(0,'rundata');
if get(hObject,'Value')
    rundata.sine_stimulus = true;
else
    rundata.sine_stimulus = false;
    rundata.sine_duration = 0;
end
% Save necessary data
setappdata(0,'rundata',rundata);
stimulusUpdater();
end

%% ---------------------------------------------------------------------------
function buffer_stimulus_Callback(hObject,evendata) %#ok<INUSD>
rundata = getappdata(0,'rundata');
if get(hObject,'Value')
    rundata.buffer_stimulus = true;
else
    rundata.buffer_stimulus = false;
    rundata.buffer_duration = 0;
end
% Save necessary data
setappdata(0,'rundata',rundata);
stimulusUpdater();
end

%% ---------------------------------------------------------------------------
function whole_stimulus_Callback(hObject,evendata) %#ok<INUSD>
stimulusParser(get(hObject,'String'));
stimulusUpdater();
end

%% ---------------------------------------------------------------------------
function whole_stimulus_CreateFcn(hObject,evendata) %#ok<INUSD>

end

%% ---------------------------------------------------------------------------
function chirp_duration_Callback(hObject,evendata) %#ok<INUSD>
rundata = getappdata(0,'rundata');
rundata.chirp_duration = str2double(get(hObject,'String'));
setappdata(0,'rundata',rundata);
stimulusUpdater();
end

%% ---------------------------------------------------------------------------
function chirp_duration_CreateFcn(hObject,evendata) %#ok<INUSD>

end

%% ---------------------------------------------------------------------------
function chirp_start_freq_Callback(hObject,evendata) %#ok<INUSD>
rundata = getappdata(0,'rundata');
rundata.chirp_start_freq = str2double(get(hObject,'String'));
setappdata(0,'rundata',rundata);
stimulusUpdater();
end

%% ---------------------------------------------------------------------------
function chirp_start_freq_CreateFcn(hObject,evendata) %#ok<INUSD>

end

%% ---------------------------------------------------------------------------
function chirp_stop_freq_Callback(hObject,evendata) %#ok<INUSD>
rundata = getappdata(0,'rundata');
rundata.chirp_stop_freq = str2double(get(hObject,'String'));
setappdata(0,'rundata',rundata);
stimulusUpdater();
end

%% ---------------------------------------------------------------------------
function chirp_stop_freq_CreateFcn(hObject,evendata) %#ok<INUSD>

end

%% ---------------------------------------------------------------------------
function sine_duration_Callback(hObject,evendata) %#ok<INUSD>
rundata = getappdata(0,'rundata');
rundata.sine_duration = str2double(get(hObject,'String'));
setappdata(0,'rundata',rundata);
stimulusUpdater();
end

%% ---------------------------------------------------------------------------
function sine_duration_CreateFcn(hObject,evendata) %#ok<INUSD>

end

%% ---------------------------------------------------------------------------
function sine_freq_Callback(hObject,evendata) %#ok<INUSD>
rundata = getappdata(0,'rundata');
rundata.sine_freq_text = char(get(hObject,'String'));
sine_freq_text = rundata.sine_freq_text;
if ~strcmp(sine_freq_text(1),'[')
    sine_freq_text = strcat('[',sine_freq_text);
end
if ~strcmp(sine_freq_text(end),']')
    sine_freq_text = strcat(sine_freq_text,']');
end
rundata.sine_freq = eval(sine_freq_text);
setappdata(0,'rundata',rundata);
stimulusUpdater();
end

%% ---------------------------------------------------------------------------
function sine_freq_CreateFcn(hObject,evendata) %#ok<INUSD>

end

%% ---------------------------------------------------------------------------
function buffer_duration_Callback(hObject,evendata) %#ok<INUSD>
rundata = getappdata(0,'rundata');
rundata.buffer_duration = str2double(get(hObject,'String'));
setappdata(0,'rundata',rundata);
stimulusUpdater();
end

%% ---------------------------------------------------------------------------
function buffer_duration_CreateFcn(hObject,evendata) %#ok<INUSD>

end

%% ---------------------------------------------------------------------------
function inputchannels_Callback(hObject,evendata) %#ok<INUSD>
handles = getappdata(0,'handles');
rundata = getappdata(0,'rundata');
% Get Channel Info
rundata.inputchannelNum = str2double(rundata.inputchannels(get(handles.inputchannels,'Value')));
set(handles.channelNum,'String',{strcat('Input Channels: ',num2str(rundata.inputchannelNum))});
% Update Filename
rundata.saveName = getFileName(rundata.saveFolder,rundata.inputchannelNum,rundata.outputchannel);
% Update file name
set(handles.setDir,'String', {strjoin(strsplit(rundata.saveName(length(rundata.saveName)-...
    iff(length(rundata.saveName)-1>=90,90,length(rundata.saveName)-1):end),' '),'_')});

% Save necessary data
setappdata(0,'handles',handles);
setappdata(0,'rundata',rundata);
end

%% ---------------------------------------------------------------------------
function inputchannels_CreateFcn(hObject,evendata) %#ok<INUSD>

end

%% ---------------------------------------------------------------------------
function amplitude_input_Callback(hObject,evendata) %#ok<INUSD>

rundata = getappdata(0,'rundata');
rundata.amplitude_input = str2double(char(get(hObject,'String')));
setappdata(0,'rundata',rundata);
end

%% ---------------------------------------------------------------------------
function speaker_input_Callback(hObject,evendata) %#ok<INUSD>

rundata = getappdata(0,'rundata');
speaker_input = char(get(hObject,'String'));
if ~strcmp(speaker_input(1),'[')
    speaker_input = strcat('[',speaker_input);
end
if ~strcmp(speaker_input(end),']')
    speaker_input = strcat(speaker_input,']');
end
rundata.speaker_input = eval(speaker_input);
setappdata(0,'rundata',rundata);

end

%% ---------------------------------------------------------------------------
function speaker_output_Callback(hObject,evendata) %#ok<INUSD>

rundata = getappdata(0,'rundata');
speaker_output = char(get(hObject,'String'));
if ~strcmp(speaker_output(1),'[')
    speaker_output = strcat('[',speaker_output);
end
if ~strcmp(speaker_output(end),']')
    speaker_output = strcat(speaker_output,']');
end
rundata.speaker_output = eval(speaker_output);
setappdata(0,'rundata',rundata);
end

%% ---------------------------------------------------------------------------
function calibrate_ao0_Callback(hObject,evendata) %#ok<INUSD>
% function calibrate_ao0_Callback(hObject,evendata) %#ok<INUSD>
rundata = getappdata(0,'rundata');
if get(hObject,'Value')
    rundata.calibrate_ao0 = true;
else
    rundata.calibrate_ao0 = false;    
end
% Save necessary data
setappdata(0,'rundata',rundata);
end

%% ---------------------------------------------------------------------------
function calibrate_ao1_Callback(hObject,evendata) %#ok<INUSD>
% function calibrate_ao1_Callback(hObject,evendata) %#ok<INUSD>
rundata = getappdata(0,'rundata');
if get(hObject,'Value')
    rundata.calibrate_ao1 = true;
else
    rundata.calibrate_ao1 = false;    
end
% Save necessary data
setappdata(0,'rundata',rundata);
end

%% ---------------------------------------------------------------------------
function use_calibration_Callback(hObject,evendata) %#ok<INUSD>
% function use_calibration_Callback(hObject,evendata) %#ok<INUSD>
rundata = getappdata(0,'rundata');
if get(hObject,'Value')
    rundata.use_calibration = true;
else
    rundata.use_calibration = false;    
end
% Save necessary data
setappdata(0,'rundata',rundata);

end

%% ---------------------------------------------------------------------------
function calibrateSpeakers_Callback(hObject,evendata) %#ok<INUSD>
% function calibrateSpeakers_Callback(hObject,evendata) %#ok<INUSD>

handles = getappdata(0,'handles');
rundata = getappdata(0,'rundata');

% Counter check inputs
if (rundata.calibrate_ao0) && (rundata.calibrate_ao1) && ...
        ((length(rundata.speaker_input)<2)||(length(rundata.speaker_output)<2))
    warning('Insufficient speaker input/output channels. An error might occur');
end

chirp_parameters = rundata.chirp_calibration_parameters;

% Calibrate AO0
if (rundata.calibrate_ao0)
input_channels = [iff(length(rundata.speaker_input)==1,rundata.speaker_input,rundata.speaker_input(1)),...
        iff(length(rundata.speaker_output)==1,rundata.speaker_output,rundata.speaker_output(1))]-1;
output_channels = 0;
    
% Start the daq session
daq_session = daq.createSession('ni');
daq_session.addAnalogInputChannel(rundata.deviceName,input_channels,'Voltage');
daq_session.addAnalogOutputChannel(rundata.deviceName,output_channels,'Voltage');
daq_session.Rate = rundata.sampling_freq;
% Generate and queue Output Data
out_data = rundata.amplitude_input*0.5.*chirp_waveform(chirp_parameters.sam_freq,...
    chirp_parameters.run_duration,chirp_parameters.start_freq,chirp_parameters.stop_freq);
queueOutputData(daq_session,out_data);

% Add plot data
fig_handle = figure('Units','Pixels','Position',[320 60 1260 960]);
plot_handles = cell(2,1);
for i=1:2
    subplot(2,1,i);
    plot_handles{i} = plot(0,0);
end

% Get filename
calibfilename_ao0 = getCalibFile(rundata.saveFolder,'AO0');

% Open files
fid = fopen(calibfilename_ao0,'w');
lh = addlistener(daq_session,'DataAvailable',@(src, event)saveData(src, event, fid));

% Set Status
set(handles.calibstate_ao0,'ForegroundColor', [0 0.498 0], ...
    'String', {'Calibrating!!'});
% Update handles
handles.fig_handle = fig_handle;
handles.plot_handles = plot_handles;
rundata.daq_session = daq_session;
rundata.fid = fid;
rundata.lh = lh;
% Save necessary data
setappdata(0,'handles',handles);
setappdata(0,'rundata',rundata);

daq_session.IsContinuous = false;
daq_session.startBackground();

% Wait till the acquisition gets over.
daq_session.wait();

% Close plots and delete handles
close(handles.fig_handle);
delete(rundata.lh);
fclose(rundata.fid);
rundata = rmfield(rundata,'daq_session');
rundata = rmfield(rundata,'fid');
rundata = rmfield(rundata,'lh');
handles = rmfield(handles,'fig_handle');
handles = rmfield(handles,'plot_handles');
% Set Filename
rundata.calibfilename_ao0 = calibfilename_ao0;
% Get Calibration curves
rundata.calibration_curve_ao0 = generateCalibrationCurve(calibfilename_ao0,0,chirp_parameters);
rundata.calibrated_ao0 = true;  
rundata.calibrate_ao0 = false;
% Set Status
set(handles.calibstate_ao0,'ForegroundColor', [0 0.498 0], ...
    'String', {'Calibrated!'});
set(handles.calibrate_ao0,'Value',false);
% Save the Calibration process in the Experiment Log
filename = fullfile(rundata.saveFolder,rundata.expt_log);
fileid = fopen(filename,'at+');
fprintf(fileid,'Fresh Calibration performed on speaker AO0.\n');
fprintf(fileid,'AO0 Calibration Saved in %s.\n',calibfilename_ao0);
fprintf(fileid,'Calibration Curve generated successfully for speaker AO0. \n');
fclose(fileid);

% Save necessary data
setappdata(0,'handles',handles);
setappdata(0,'rundata',rundata);
end

% Calibrate AO1
if (rundata.calibrate_ao1)
input_channels = [iff(length(rundata.speaker_input)==1,rundata.speaker_input,rundata.speaker_input(2)),...
        iff(length(rundata.speaker_output)==1,rundata.speaker_output,rundata.speaker_output(2))]-1;
output_channels = 1;
    
% Start the daq session
daq_session = daq.createSession('ni');
daq_session.addAnalogInputChannel(rundata.deviceName,input_channels,'Voltage');
daq_session.addAnalogOutputChannel(rundata.deviceName,output_channels,'Voltage');
daq_session.Rate = rundata.sampling_freq;
% Generate and queue Output Data
out_data = rundata.amplitude_input*0.5.*chirp_waveform(chirp_parameters.sam_freq,...
    chirp_parameters.run_duration,chirp_parameters.start_freq,chirp_parameters.stop_freq);
queueOutputData(daq_session,out_data);

% Add plot data
fig_handle = figure('Units','Pixels','Position',[320 60 1260 960]);
plot_handles = cell(2,1);
for i=1:2
    subplot(2,1,i);
    plot_handles{i} = plot(0,0);
end

% Get filename
calibfilename_ao1 = getCalibFile(rundata.saveFolder,'AO1');

% Open files
fid = fopen(calibfilename_ao1,'w');
lh = addlistener(daq_session,'DataAvailable',@(src, event)saveData(src, event, fid));

daq_session.IsContinuous = false;
daq_session.startBackground();

% Set Status
set(handles.calibstate_ao1,'ForegroundColor', [0 0.498 0], ...
    'String', {'Calibrating!!'});
% Update handles
handles.fig_handle = fig_handle;
handles.plot_handles = plot_handles;
rundata.daq_session = daq_session;
rundata.fid = fid;
rundata.lh = lh;
% Save necessary data
setappdata(0,'handles',handles);
setappdata(0,'rundata',rundata);

% Wait till the acquisition gets over.
daq_session.wait();

% Acquisition done
handles = getappdata(0,'handles');
rundata = getappdata(0,'rundata');
% Close plots and delete handles
close(handles.fig_handle);
delete(rundata.lh);
fclose(rundata.fid);
rundata = rmfield(rundata,'daq_session');
rundata = rmfield(rundata,'fid');
rundata = rmfield(rundata,'lh');
handles = rmfield(handles,'fig_handle');
handles = rmfield(handles,'plot_handles');
% Set Filename
rundata.calibfilename_ao1 = calibfilename_ao1;
% Get Calibration curves
rundata.calibration_curve_ao1 = generateCalibrationCurve(calibfilename_ao1,1,chirp_parameters);
rundata.calibrated_ao1 = true;  
rundata.calibrate_ao1 = false;
% Set Status
set(handles.calibstate_ao1,'ForegroundColor', [0 0.498 0], ...
    'String', {'Calibrated!'});
set(handles.calibrate_ao1,'Value',false);
% Save the Calibration process in the Experiment Log
filename = fullfile(rundata.saveFolder,rundata.expt_log);
fileid = fopen(filename,'at+');
fprintf(fileid,'Fresh Calibration performed on speaker AO1.\n');
fprintf(fileid,'AO1 Calibration Saved in %s.\n',calibfilename_ao1);
fprintf(fileid,'Calibration Curve generated successfully for speaker AO1. \n');
fclose(fileid);

% Save necessary data
setappdata(0,'handles',handles);
setappdata(0,'rundata',rundata);
end

% Add the calibration part of it here!


disp('Both Speakers succsessfully calibrated!')
if rundata.calibrated_ao0 || rundata.calibrated_ao1
    rundata.use_calibration = true;
    set(handles.use_calibration,'Value',true);
end    
    
end


%% Custom functions
function [file] = getFileName(folder,inchannels,outchannels)
% function [file] = getFileName(folder)
list = dir(fullfile(folder,'*.bin'));
list = {list(:).name};
searchString = strcat('EMGData_',date,'_(\d+)');
matchedTokens = regexp(list,searchString,'tokens');
numstrs = matchedTokens(~cellfun(@isempty,matchedTokens));
outstr = strjoin(strsplit(num2str(outchannels),' '),',');
if isempty(numstrs)
    file = fullfile(folder,sprintf('EMGData_%s_%04d_In-%02d_Out-%s.bin',date,1,inchannels,outstr));
else
    nums = sort(cellfun(@(x) str2double(x{:}),numstrs));
    file = fullfile(folder,sprintf('EMGData_%s_%04d_In-%02d_Out-%s.bin',date,nums(end)+1,inchannels,outstr));
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
channelnum = size(event.Data,2);
for i=1:channelnum
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

function [] = stimulusParser(text)
chirp_data = regexp(text,'chirp:[\s]*(\d+)[\s ,]*(\d+)[\s ,]*(\d+);sine:','tokens');
sine_data = regexp(text,'sine:[\s]*(\d+)[\s ,]*([\d , \s :]+)','tokens');
buffer_data = regexp(text,'buffer:[\s]*(\d+)','tokens');

% Get saved data
rundata = getappdata(0,'rundata');
% Begin saving the data
if (~isempty(chirp_data) && length(chirp_data{1,1})==3)
    % Chirp data valid
    rundata.chirp_stimulus = true;
    rundata.chirp_duration = str2double(chirp_data{1}{1,1});
    rundata.chirp_start_freq = str2double(chirp_data{1}{1,2});
    rundata.chirp_stop_freq = str2double(chirp_data{1}{1,3});
else
    disp('Chirp input absent or invalid');
    rundata.chirp_stimulus = false;
    rundata.chirp_duration = 0;
end

if (~isempty(sine_data) && length(sine_data{1,1})>1)
    % Sine Data Valid
    rundata.sine_stimulus = true;
    rundata.sine_duration = str2double(sine_data{1}{1,1});
    sine_freq_text = sine_data{1}{1,2};
    rundata.sine_freq_text = sine_freq_text;
    if ~strcmp(sine_freq_text(1),'[')
        sine_freq_text = strcat('[',sine_freq_text);
    end
    if ~strcmp(sine_freq_text(end),']')
        sine_freq_text = strcat(sine_freq_text,']');
    end
    rundata.sine_freq = eval(sine_freq_text);
else
    disp('Sine input absent or invalid');
    rundata.sine_stimulus = false;
    rundata.sine_duration = 0;
end

if ~isempty(buffer_data)
    rundata.buffer_stimulus = true;
    rundata.buffer_duration = str2double(buffer_data{1});
else
    disp('Buffer input absent or invalid');
    rundata.buffer_stimulus = false;
    rundata.buffer_duration = 0;
end

% Save necessary data
setappdata(0,'rundata',rundata);

end

function [] = stimulusUpdater()
% function [] = stimulusUpdater()
% Get saved data
handles = getappdata(0,'handles');
rundata = getappdata(0,'rundata');
% Refresh handles
if rundata.chirp_stimulus
    set(handles.chirp_stimulus,'Value',1);
    set(handles.chirp_duration,'String',num2str(rundata.chirp_duration));
    set(handles.chirp_start_freq,'String',num2str(rundata.chirp_start_freq));
    set(handles.chirp_stop_freq,'String',num2str(rundata.chirp_stop_freq));
    chirp_text = sprintf('chirp:%d,%d,%d',rundata.chirp_duration,...
        rundata.chirp_start_freq,rundata.chirp_stop_freq);
else
    set(handles.chirp_stimulus,'Value',0);
    set(handles.chirp_duration,'String','');
    set(handles.chirp_start_freq,'String','');
    set(handles.chirp_stop_freq,'String','');
    chirp_text = '';
end

if rundata.sine_stimulus
    set(handles.sine_stimulus,'Value',1);
    set(handles.sine_duration,'String',num2str(rundata.sine_duration));
    set(handles.sine_freq,'String',rundata.sine_freq_text);
    sine_text = sprintf('sine:%d,%s',rundata.sine_duration,...
        rundata.sine_freq_text);
else
    set(handles.sine_stimulus,'Value',0);
    set(handles.sine_duration,'String','');
    set(handles.sine_freq,'String','');
    sine_text = '';
end

if rundata.buffer_stimulus
    set(handles.buffer_stimulus,'Value',1);
    set(handles.buffer_duration,'String',num2str(rundata.buffer_duration));
    buffer_text = sprintf('buffer:%d',rundata.buffer_duration);
else
    set(handles.buffer_stimulus,'Value',0);
    set(handles.buffer_duration,'String','');
    buffer_text = '';
end
stimulus_text = strcat(iff(isempty(chirp_text),'',strcat(chirp_text,';')),...
    iff(isempty(sine_text),'',strcat(sine_text,';')),buffer_text);
set(handles.whole_stimulus,'String',stimulus_text);

end

function [out_data] = generateOutputData(varargin)
% function [] = generateOutputData()
%
%
%
if ~isempty(varargin)
    calibration_curve = varargin{1};
    calibration = true;
else
    calibration = false;
end

rundata = getappdata(0,'rundata');
sam_freq = rundata.sampling_freq;
sin_freqs = rundata.sine_freq;
sig_duration = rundata.sine_duration;
buffer_duration = rundata.buffer_duration;
amplitude = rundata.amplitude_input*0.5;

if rundata.chirp_stimulus
    % Generate Chirp
    % out_data = chirp(0:1/sam_freq:rundata.chirp_duration,...
    %     rundata.chirp_start_freq,rundata.chirp_duration/2,rundata.chirp_stop_freq/2)';
    % out_data(end) = [];
    out_data = amplitude.*chirp_waveform(sam_freq,rundata.chirp_duration,rundata.chirp_start_freq,rundata.chirp_stop_freq);
    if calibration
        time = (0:1/sam_freq:rundata.chirp_duration)';
        freq = rundata.chirp_start_freq + ((rundata.chirp_stop_freq-rundata.chirp_start_freq)/rundata.chirp_duration).*time;
        normalized_amplitude = calibration_curve(freq);
        out_data = out_data.*normalized_amplitude;
        clearvars time freq normalized_amplitude;
    end
    out_data(end) = [];
else
    out_data = [];
end

% Generate Sine, with added buffer
if rundata.sine_stimulus
for i=1:length(sin_freqs)
    sin_data = amplitude.*sin(linspace(0, 2*pi*sin_freqs(i)*sig_duration, sam_freq*sig_duration+1))';
    if calibration
        sin_data = calibration_curve(sin_freqs(i)).*sin_data;
    end
    sin_data(end) = [];
    buffer_data = zeros(sam_freq*buffer_duration,1);
    out_data = [out_data;buffer_data;sin_data];
end
end
buffer_data = zeros(sam_freq*buffer_duration,1);
out_data = [out_data;buffer_data];

end

function [] = checkIfDone()
% function [] = checkIfDone()
rundata = getappdata(0,'rundata');
daq_session = rundata.daq_session;
if daq_session.IsDone
    stop(rundata.timer);
    delete(rundata.timer);
    rundata = rmfield(rundata,'timer');
    setappdata(0,'rundata',rundata);
    stop_protocol_Callback();
end

end

function [] = experimentLogger(status)
% function [] = experimentLogger()
% Log Stimulus Details and Start time
rundata = getappdata(0,'rundata');
% Begin
seperator = '##############################';

% Determine filename
filename = fullfile(rundata.saveFolder,rundata.expt_log);
fileid = fopen(filename,'at+');

if status == 1
    saveName = strsplit(rundata.saveName,filesep);
    saveName = saveName{end};
    % Save important initialization data
    imp_init_names = [1,5,6,8];
    
    % Stimulus Data
    chirp_names = [24,25,26];
    sine_names = [28,29,30];
    sine_freq_expanded = num2str(rundata.sine_freq);
    buffer_names = [31,32];   
    
    fprintf(fileid,'%s%s%s%s\n%s%s%s\n%s%s%s%s\n\n',...
        seperator,seperator,seperator,seperator,...
        seperator,saveName,seperator,...
        seperator,seperator,seperator,seperator);
    
    fprintf(fileid,'%s\n%s\n','Initialization values:',struct2str(rundata,0,imp_init_names));
    fprintf(fileid,'%s\n','Calibration values:');
    fprintf(fileid,'\t\t\t\t\t\t%s%s\n','use_calibration:',iff(rundata.use_calibration,'True','False'));
    fprintf(fileid,'\t\t\t\t\t\t%s%s\n','calibrated_ao0:',iff(rundata.calibrated_ao0,'True','False'));
    fprintf(fileid,'\t\t\t\t\t\t%s%s\n','calibfilename_ao0:',rundata.calibfilename_ao0);
    fprintf(fileid,'\t\t\t\t\t\t%s%s\n','calibration_curve_ao0:',iff(isempty(rundata.calibration_curve_ao0),'Does not exist','Exists'));
    fprintf(fileid,'\t\t\t\t\t\t%s%s\n','calibrated_ao1:',iff(rundata.calibrated_ao1,'True','False'));
    fprintf(fileid,'\t\t\t\t\t\t%s%s\n','calibfilename_ao1:',rundata.calibfilename_ao1);
    fprintf(fileid,'\t\t\t\t\t\t%s%s\n','calibration_curve_ao1:',iff(isempty(rundata.calibration_curve_ao1),'Does not exist','Exists'));
    fprintf(fileid,'\n%s\n\t\t\t\t\t\t%s%s\n%s\n','Chirp Stimulus values:','chirp_stimulus: ',...
        iff(rundata.chirp_stimulus,'True','False'),struct2str(rundata,0,chirp_names));
    fprintf(fileid,'%s\n\t\t\t\t\t\t%s%s\n%s\n','Sine Stimulus values:','sine_stimulus: ',...
        iff(rundata.sine_stimulus,'True','False'),struct2str(rundata,0,sine_names));    
    fprintf(fileid,'\t\t\t\t\t\t%s%s\n\n','Sine Frequencies:',sine_freq_expanded);
    fprintf(fileid,'%s\n\t\t\t\t\t\t%s%s\n%s\n','Buffer Stimulus values:','buffer_stimulus: ',...
        iff(rundata.buffer_stimulus,'True','False'),struct2str(rundata,0,buffer_names));        
    fprintf(fileid,'\n%s\n',seperator);
    fprintf(fileid,'%s\n%s%s\n','Experiment Run Details:', 'Start - ',datestr(clock));
   
elseif status == 0
    fprintf(fileid,'%s%s\n%s\n\n%s%s%s%s\n%s%s%s%s\n\n\n','Stop - ',datestr(clock),...
        seperator,...
        seperator,seperator,seperator,seperator,....
        seperator,seperator,seperator,seperator);
end
fclose(fileid);

end

function [chirp_signal] = chirp_waveform(sam_freq,duration,start,stop)
% A custom function to generate a sine chirp
% Equation used = sin(2*pi*(fo*t + (k/2)*t^2)
time = (0:1/sam_freq:duration)';
freq = start + 0.5*((stop-start)/duration).*time;
chirp_signal = sin(2*pi.*freq.*time);
end

function [newfile,currentfile] = getCalibFile(folder,channel_name)
% function [file] = getFileName(folder)
list = dir(fullfile(folder,'*.calib'));
list = {list(:).name};
searchString = strcat('Speaker_',channel_name,'_',date,'_(\d+)');
matchedTokens = regexp(list,searchString,'tokens');
numstrs = matchedTokens(~cellfun(@isempty,matchedTokens));
if isempty(numstrs)
    newfile = fullfile(folder,sprintf('Speaker_%s_%s_%04d.calib',channel_name,date,1));
    currentfile = '';
else
    nums = sort(cellfun(@(x) str2double(x{:}),numstrs));
    newfile = fullfile(folder,sprintf('Speaker_%s_%s_%04d.calib',channel_name,date,nums(end)+1));
    currentfile = fullfile(folder,sprintf('Speaker_%s_%s_%04d.calib',channel_name,date,nums(end)));
end

end

function [calibration_curve] = generateCalibrationCurve(filename,speaker,chirp_parameters)

% Get Data
file = fopen(filename,'r');
[Data,~] = fread(file,[3,Inf],'double');
fclose(file);
% Split Data
% time = Data(1,:)';
speaker_input = Data(2,:)';
speaker_output = ButterFilt(Data(3,:)',chirp_parameters.sam_freq,2*chirp_parameters.stop_freq);
if ~speaker
    speaker_output = halleffectsensor1(speaker_output);
else
    speaker_output = halleffectsensor2(speaker_output);
end
clearvars Data;

calibration_curve = normalizeChirpSignal(speaker_input,speaker_output,chirp_parameters);
end

function [Distance] = halleffectsensor1(Voltage)
a = 1.4802;
b = 227.4944;
x0 = 4.9785;

Distance = nthroot(b./(Voltage-a),3)-x0;
end

function [Distance] = halleffectsensor2(Voltage)
a = 1.5238;
b = 180.9620;
x0 = 4.9948;

Distance = nthroot(b./(Voltage-a),3)-x0;
end