CONTEXT 
This code aims at loading and semi-automatically detecting the Spreading Depolarizations (SDs) artificially elicited during in-vivo 
experiments in rats. The signals collected are Electrocorticography signals, invasivaly recorded through subdural electrodes.

DATA DESCRIPTION
	data_xxxxxx_xxxxxx_ds: exp_ds, structure containing raw data of ECoG signal collected in rats
		signal: NxM matrix, N being the total number of samples, M being the number of electrodes
		time: Nx1 vector, N being the total number of samples
		fs: sample frequency
	data_xxxxxx_xxxxxx_SD: SD, matrix containing parameters computed on each SD detected (rows). The first column 
 		indicates the electrode on which the specific SD was detected. 

CODE DESCRIPTION
1) main_SD_analysis.m --> this is the main code, divided in two parts:
	a. Data loading 
	b. GUI to select the data 
	(more details are added in the functions)
2) load_downsampled_file.m --> code needed to load the signal data
3) load_SD_file --> code needed to load the SD data
4) automatic_labelling --> code needed to automatically detect the stimulation artifact on the signal and associate the correct label 
			   (C for control, S for stimulation) to each SD
5) axescoord2figurecoord.m --> function needed to adapt the coordinates detected on the plot to the coordinates in the figure 
			       reference frame
6) labelling_user_check --> code needed to create the GUI to check and modify SDs selection/labelling (in case of wrongly automatically 
			    detected SD, i.e. wrong labelling)

Disclaimer: main_SD_analysis.m calls functions 2-6 that have not been adapted to the Reproducible and Open Science standards yet,
 	    please refer to the main_SD_analysis.m for the purposes of this challenge.


