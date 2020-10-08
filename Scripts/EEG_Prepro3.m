%{
EEG_Prepro3
Author: Tom Bullock
Date created: 07.10.20
Date updated: 07.10.20

Purpose: Run ICA (AMICA) and apply IC Label

Notes: this will typically be run in parallel on cluster, so just grab all
prepro2 files in that directory and run through AMICA

%}

clear
close all

% set EEGLAB Path (if not already set)
eeglabDir = '/Users/tombullock/Documents/Psychology/ATTLAB_Repos/EEG_Exp_Template/eeglab2019_1';
if ~exist('eeglab.m')
    cd(eeglabDir);eeglab;clear;close all;cd ..
else
    eeglabDir = '/Users/tombullock/Documents/Psychology/ATTLAB_Repos/EEG_Exp_Template/eeglab2019_1';
end

% set directories
rDir = '/Users/tombullock/Documents/Psychology/ATTLAB_Repos/EEG_Exp_Template';
sourceDirEEG = [rDir '/' 'EEG_Prepro2'];  
destDir = [rDir '/' 'EEG_Prepro3']; 

% add dependencies to path
addpath(genpath([rDir '/' 'Dependencies']))

% change dir to source dir (files ready to be run through ICA), get list of
% files, then change dir back
cd(sourceDirEEG)
d=dir('*.mat');
cd ..

% loop through files and run ICA
for i=1:length(d)
   
    thisFilename = d(i).name;
    
    
end






% subjects for processing
subjects = 1:3;

%% subject loop
for iSub=1:length(subjects)
    sjNum = subjects(iSub);
    
    % condition loop
    for iCond=1%:2
        
        
        
        
        if isfield(EEG.etc, 'clean_channel_mask')
            dataRank = min([rank(double(EEG.data')) sum(EEG.etc.clean_channel_mask)]);
        else
            dataRank = rank(double(EEG.continousData'));
        end
        
        try
            
            % AMICA takes forever on continous data, use send email function to notify when done
            runamica15(EEG.data, 'num_chans', EEG.nbchan,...
                'outdir', [EEG_ica_dir sprintf('sj%d_se%02d_EEG_ica',subNum,session+1)],...
                'pcakeep', dataRank, 'num_models', 1,...
                'do_reject', 1, 'numrej', 15, 'rejsig', 3, 'rejint',1);
            
            EEG.etc.amica  = loadmodout15([EEG_ica_dir sprintf('sj%d_se%02d_EEG_ica',subNum,session+1)]); % loads AMICA output from outdir
            EEG.etc.amica.S = EEG.etc.amica.S(1:EEG.etc.amica.num_pcs, :);
            EEG.icaweights = EEG.etc.amica.W;
            EEG.icasphere  = EEG.etc.amica.S;
            EEG = eeg_checkset(EEG, 'ica');
            
            %     % Estimate single equivalent dipoles
            % 	% Havent used below lines for anything yet
            %     templateChannelFilePath = [eeglab_dipDir 'standard_BESA/standard-10-5-cap385.elp'];
            %     hdmFilePath  = [eeglab_dipDir 'standard_BEM/standard_vol.mat'];
            %     EEG = pop_dipfit_settings( EEG, 'hdmfile',[eeglab_dipDir 'standard_BEM/standard_vol.mat'],...
            %         'coordformat','MNI','mrifile',...
            %         [eeglab_dipDir 'standard_BEM/standard_mri.mat'],'chanfile',...
            %         [eeglab_dipDir 'standard_BEM/elec/standard_1005.elc'],'coord_transform',...
            %         [0.83215 -15.6287 2.4114 0.081214 0.00093739 -1.5732 1.1742 1.0601 1.1485] ,'chansel',[1:63] );
            %     EEG = pop_multifit(EEG, 1:EEG.nbchan,'threshold', 100, 'dipplot','off','plotopt',{'normlen' 'on'});
            %
            %     % Search for and estimate symmetrically constrained bilateral dipoles
            %     EEG = fitTwoDipoles(EEG, 'LRR', 35);
            
            
            % apply IC Label
            EEG = iclabel(EEG);
            
            
            save([EEG_ica_dir sprintf('sj%02d_se%02d_EEG_clean_ica.mat',subNum,session+1)], 'EEG','-v7.3');
            
        catch e
            header = sprintf('Error running ICA PREPROCESSING for SJ %02d. WHY HAVE YOU FORSAKEN ME.',subNum);
            message = sprintf('The identifier was:\n%s.\nThe message was:\n%s', e.identifier, e.message);
            sendEmailToMe(header,message)
            error(message)
        end
        
    end
end