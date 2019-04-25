clear; close all; clc;
script_dir = 'C:\Users\Rob\Desktop\darts\';
cd(script_dir);
addpath('.\eeglab13_6_5b')
data_dir = '.\data\';
addpath(data_dir);
eeglab;
close all;

% user input
chan_labs = {'Fz','Cz','Pz','Oz'};
freq_labs = {'theta', 'alpha'};
subjs_to_include = {'571', '579', '580', ...
	'607', '608', '616', '619', '621', '627', '631'};
subjs_to_include = { '571', '608', '607', '579', '580'};

% load XLSX SNAP data
[num,txt,raw] = xlsread([data_dir,'behavioral_data.xlsx']);
headers = txt(1,:);
for k=1:numel(headers)
	xlsx.(headers{k})=num(:,k) ;
end

% initialize eeg columns to add the behav columns
for chan_lab = chan_labs
	for freq_lab = freq_labs
		xlsx.([chan_lab{:},'_',freq_lab{:}]) = nan(length(xlsx.pres),1);
	end
end

for subj_i = 1:length(subjs_to_include)
	subj_id = subjs_to_include{subj_i};
	subj_set = [subj_id,'_eeg_64_laplace.set'];
	
	% bandpass filter at desired freqs
	EEG = pop_loadset('filename',subj_set,'filepath',data_dir);
	EEG_theta = pop_eegfiltnew(EEG, 3, 7);
	EEG_alpha = pop_eegfiltnew(EEG, 8, 12);
	EEGs = {EEG_theta,EEG_alpha};
	load([data_dir, subj_id,'_eeg_64_latencys'])
	
	% check eeg:behav trial alignment, astronomically small chance this check can fail
	for xl_start_row  = 1:(length(xlsx.pres)-length(start_event_time_inds))
		xl_pres = xlsx.pres(xl_start_row:xl_start_row+length(start_event_time_inds)-1);
		if sum(end_event_strings(:,4)==num2str(xl_pres)) == length(start_event_time_inds)
			break
		end
	end

	% retrieve this subjs trial-level amplitudes at desired chans and freqs
	for chan_lab_i = 1:length(chan_labs)
		chan_lab = chan_labs{chan_lab_i};
		for freq_lab_i = 1:length(EEGs)
			freq_lab = freq_labs{freq_lab_i};
			EEG = EEGs{freq_lab_i};
			trial_amps = [];
			for trial_latency_i = 1:length(start_event_time_inds)
				start_latency_i = start_event_time_inds(trial_latency_i);
				end_latency_i = end_event_time_inds(trial_latency_i);
				trial_amps(end+1) = mean(abs(EEG.data(chan_lab_i,start_latency_i:end_latency_i)),2)';
			end
			all_amps = xlsx.([chan_lab,'_',freq_lab]);
			all_amps(xl_start_row:(xl_start_row+length(start_event_time_inds)-1)) = trial_amps;
			xlsx.([chan_lab,'_',freq_lab]) = all_amps;
		end
	end	
end

% trial-level behav+eeg regression
throwtimes = xlsx.throwtime(xlsx.distance < 6 & xlsx.throwtime < 5);
delay = xlsx.delaystilltime(xlsx.distance < 6 & xlsx.throwtime < 5);
pres = categorical(xlsx.pres(xlsx.distance < 6 & xlsx.throwtime < 5));
dists = xlsx.distance(xlsx.distance < 6 & xlsx.throwtime < 5);
subjs = categorical(xlsx.subject(xlsx.distance < 6 & xlsx.throwtime < 5));

% create chan+freq  variables
varnames = {'dists', 'throwtimes', 'delay', 'pres', 'subjs'};
for chan_lab = chan_labs
	for freq_lab = freq_labs
		varname = [chan_lab{:},'_',freq_lab{:}];
		varnames{end+1} = varname;
		eval([varname,' = xlsx.',varname,'(xlsx.distance < 6 & xlsx.throwtime < 5);']);
	end
end

eval( ['reg_table = table(', strjoin(varnames,','),');'] );

fit = fitlm(reg_table,'ResponseVar', 'dists', 'RobustOpts', 'on');


% [H,P,CI,STATS] = ttest2(Cz_thetas_abs,Cz_thetas_pres)
% [H,P,CI,STATS] = ttest2(Cz_thetas_abs,Cz_thetas_pres, 'vartype', 'unequal')