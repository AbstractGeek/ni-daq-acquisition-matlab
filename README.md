# ni-daq-acquisition-matlab

*Preparation:* Install NI-DAQmx drivers compatible with the MATLAB version being used. Connect the DAQ and run the command daq.getDevices to double check if the DAQ is being correctly detected by MATLAB. Additionally, keep note of the device name (default-‘Dev1’).The device name might have to be changed in daqBasicAcquisition if it is not the same as the default.

## daqBasicAcquisition
A simple GUI for acquiring voltage data from an NI DAQ. The GUI also simultaneously displays the data being acquired by all the channels (voltage vs time). The acquired data is saved as a binary file. The name of the next saved file is incremented automatically after every successful acquisition. Along with the acquired data, a log file is generated to track the start and stop time of each acquisition file.

The sampling rate is at 10kHz, written as a constant in the GUI. The device name (‘Dev1’) might have to be changed for the GUI to work properly.

## readAcquiredData
Use this function to read back the acquired data into MATLAB. The first row is the time of acquisition. The rest of the rows are the acquired channels.
