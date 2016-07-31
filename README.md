# ni-daq-acquisition-matlab

## daqBasicAcquisition
A simple GUI for acquiring voltage data from an NI DAQ. The GUI also simultaneously displays the data being acquired by all the channels (voltage vs time). The acquired data is saved as a binary file. The name of the next saved file is incremented automatically after every successful acquisition. Along with the acquired data, a log file is generated to track the start and stop time of each acquisition file.

The sampling rate is at 10kHz, written as a constant in the GUI. The device name (‘Dev1’) might have to be changed for the GUI to work properly.

## readAcquiredData
Use this function to read back the acquired data into MATLAB. The first row is the time of acquisition. The rest of the rows are the acquired channels.
