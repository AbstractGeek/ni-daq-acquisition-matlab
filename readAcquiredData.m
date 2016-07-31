function [Data,count] = readAcquiredData(filename,varargin)
% Reads data logged by the logData function
%
% Last Modified On 15 August 2015
% Author: Dinesh Natesan

if isempty(varargin)
    % Get input channels
    inchan = regexp(filename,'In-(\d\d)','tokens');
    inchan = str2double(inchan{1,1});
else
    inchan = varargin{1};
end

% Read file
file = fopen(filename,'r');
[Data,count] = fread(file,[inchan+1,Inf],'double');
fclose(file);
end
