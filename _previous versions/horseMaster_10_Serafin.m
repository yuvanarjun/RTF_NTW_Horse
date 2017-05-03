% horseMaster.m file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the master file to run various codes to estimate network matrices
% when only limited information is available. It is part of the work of the
% BCBS Research Task Force's Liquidity Stress Testing group.
%
% Assumptions
% - We assume a folder structure as already defined in the distibuted zip
%   file or Dropbox folder
% - This Horse.m file should be kept in the Horse Race �root� and it will
%   call on each of the underlying codes in the sub folders
% - For MAC/LINUX the program defines alternative paths
%
% For any inputfile it will apply the approaches chosen. For each of these
% approaches, a series of networks statistics is computed.
% In addition, the real, observed network is compared with
% 1. ME
% 2. The networks as estimated with the various approaches
%
% In some cases, the approach only estimates an adjacency matrix (eg batt).
% In this case the observed network is transformed into an adjacency matrix
%
% TO DO
% - store the network stats for all approaches as a table
% - make sure results for all approaches are stored in \approach\output directories
% - what is a propper fit measure: correlation? error score for comparing
%   adjancy matrices?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Preparations
% -------------------------------------------------------------------------
clear all
clc
% set random seed
rng(1989);

% Choose data set and approaches to run
% -------------------------------------------------------------------------
% Here you set the name of input file (in CSV with no fringes, ie no row or
% column names).
inputfilename = 'matrix.xlsx';

approachesList = {'orig','maxe','anan','dreh','bara','batt'};

approaches={'batt'};

% Set directory paths
% -------------------------------------------------------------------------
if ispc == 1
    p_fullmatrix = [pwd '\_fullmatrix\'];
else
    % Alternate reference on MAC/LINUX
    p_fullmatrix = ['_fullmatrix/'];
end

addpath('statistics');
addpath('statistics/debtrank');
addpath('statistics/debtrank_poledna');

% Prepare the input files
% -------------------------------------------------------------------------
% Read in the full information matrix
% We assume that the matrix is in a tab delineated CSV file with banks
% assets in columns and its liabilities in rows. The marginal are thus a
% row vector for banks� assets and a column vector for liabilities.
M_orig = xlsread([p_fullmatrix inputfilename],'matrix');
E = xlsread([p_fullmatrix inputfilename],'capital');
TA = xlsread([p_fullmatrix inputfilename],'total_assets');

% Derive descriptive information
rows = size(M_orig,1);
cols = size(M_orig,2);
assert(rows == cols, 'Matrix is not square')

% IvL: changed sum to nansum
Assets      = nansum(M_orig,1);
Liabilities = nansum(M_orig,2);

% Run codes
% -------------------------------------------------------------------------

for a = approachesList
    if strcmp(a,'orig') == 0
            % Each of these would leave behind an estimated matrix in the \` approach�\output directory
            addpath([a{:} '/code']);
            if exist([a{:} 'code.m'],'file') == 2
                try
                    %eval(['M_' a{:} ' = ' a{:} 'code();']);
                    eval(['M_' a{:} ' = ' a{:} 'code(a, M_orig, Assets, Liabilities, E, TA);']);
                    eval(['outputMatrices.' a{:} '.M = M_' a{:} ';']);
                catch err
                    % Give more information for mismatch.
                    if exist([a{:} 'code.m'],'file') == 0
                        msg = sprintf('%s', ...
                            'Matlab cannot find script ', [a{:} 'code.m'], '. Make sure it exists in a designated folder.');
                        display(msg);
                        
                        % Display any other errors as usual.
                    else
                        msg = sprintf('%s', ...
                            'Script for ', [a{:} 'code.m'], ' seems to crash. Make sure it is working properly and is giving a matrix as output.');
                        display(msg);
                    end
                end
            end
    end
        computeNetworkStatistics_v3
        eval(['outputMatrices.' a{:} '.Network = M_' a{:} ';']);
        eval(['outputMatrices.' a{:} '.Links = Links;' ]);
        eval(['outputMatrices.' a{:} '.Density = Density;']);
        eval(['outputMatrices.' a{:} '.MeanDeg = MeanDeg;']);
        eval(['outputMatrices.' a{:} '.MedoDeg = MedoDeg;']);
        eval(['outputMatrices.' a{:} '.SymPearson = SymPearson;']);
        eval(['outputMatrices.' a{:} '.LendDep = LendDep;']);
        eval(['outputMatrices.' a{:} '.BoroDep = BoroDep;']);
        eval(['outputMatrices.' a{:} '.Cmit = Cmit;']);
        eval(['outputMatrices.' a{:} '.coresize = coresize;']);
        eval(['outputMatrices.' a{:} '.score = score;']);
        eval(['outputMatrices.' a{:} '.debtrank = impact_debtrank;']);
    clear('A','Links','Density','MeanDeg','MedoDeg','SymPearson','LendDep',...
        'BoroDep','Cmit','coresize','score','C1z','C2z','X','ans',...
        'b','boro','boromax','bratio','cols','error','errors','l','lend',...
        'lendmax','lratio','n','odX','core','x',...
        'I','W','a','ag','ag_new','ans_compute_DebtRank','aval_size',...
        'capital','case_load_capital','edgeList','gamma',...
        'impact_debtrank','impact_default','ind','ind_aval',...
        'inputfilename','nNodes','nSteps','net','node_list',...
        'p_fullmatrix','phi0','seed_node','seed_nodes',...
        'strength','theta','tot_asset','v0','impact');
    
end

save('outputMatrices.mat','outputMatrices')

labels=1:1:rows
labels=labels'
approachesList2 = {'orig','maxe','anan','dreh','bara'}; 
for a = approachesList2
eval(['outputMatrices.' a{:} '.rank = horzcat(outputMatrices.' a{:} '.debtrank,labels)']);
eval(['outputMatrices.' a{:} '.rank = sortrows(outputMatrices.' a{:} '.rank,-1)']);
eval(['outputMatrices.' a{:} '.top1 = ismember(outputMatrices.orig.rank(1,2),outputMatrices.' a{:} '.rank(1,2))']);     
 eval(['outputMatrices.' a{:} '.top3 = ismember(outputMatrices.orig.rank(1,2),outputMatrices.' a{:} '.rank(1:3,2))']);     
 %eval(['outputMatrices.' a{:} '.top10 = ismember(outputMatrices.orig.rank(1,2),outputMatrices.' a{:} '.rank(1:10,2))']);          
 eval(['outputMatrices.' a{:} '.corr = corr(outputMatrices.orig.debtrank,outputMatrices.' a{:} '.debtrank)']); 
 eval(['outputMatrices.' a{:} '.overlap1 = size(intersect(outputMatrices.orig.rank(1,2),outputMatrices.' a{:} '.rank(1,2))) / size(union(outputMatrices.orig.rank(1,2),outputMatrices.' a{:} '.rank(1,2)))']);
eval(['outputMatrices.' a{:} '.overlap3 = size(intersect(outputMatrices.orig.rank(1:3,2),outputMatrices.' a{:} '.rank(1:3,2)))/ size(union(outputMatrices.orig.rank(1:3,2),outputMatrices.' a{:} '.rank(1:3,2)))']);
%eval(['outputMatrices.' a{:} '.overlap10 = size(intersect(outputMatrices.orig.rank(1:10,2),outputMatrices.' a{:} '.rank(1:10,2))) / size(union(outputMatrices.orig.rank(1:10,2),outputMatrices.' a{:} '.rank(1:10,2)))']);
end
    


% Compute Similarity
% -------------------------------------------------------------------------

% Compares adjcency matrices only
hamming_dist = @(a,b)sum(a(:)~=b(:));
jaccard_dist = @(a,b)sum(a(:) & b(:))/ sum(a(:) | b(:));

% Compares valued networks
cosine_simi = @(a,b)dot(a(:),b(:))/(sqrt(dot(a(:),a(:)))*sqrt(dot(b(:),b(:))));
% For the Jensen Shannon distance we have the function jsdiv(a,b)

for a = approachesList
    if strcmp(a{:},'orig') == 0
        eval(['similarity.' a{:} '.hamming = hamming_dist(outputMatrices.orig.Network(:), outputMatrices.' a{:} '.Network(:));']);
        eval(['similarity.' a{:} '.jaccard = jaccard_dist(outputMatrices.orig.Network(:), outputMatrices.' a{:} '.Network(:));']);
        
        eval(['similarity.' a{:} '.cosine = cosine_simi(outputMatrices.orig.Network(:), outputMatrices.' a{:} '.Network(:));']);
        eval(['similarity.' a{:} '.jensen = jsdiv(outputMatrices.orig.Network(:), outputMatrices.' a{:} '.Network(:));']);
    end
end
