%change directory to the one where all the files that were transferred are
%stored
%cd 'D:\Doc\Contagion\InterbankContagion\MAGD\Expl';

%[income_load,incBCodes_load] = xlsread('D:\Doc\Contagion\InterbankContagion\matlabOriginal\ebainc.xls','inc','A2:P87');
[bs_load,bsNames_load] = xlsread('BankData.xls','data','A2:I6');

%"bank vs country" map of the probability to become a counterparty
%the file contains the coutry breakdown of each banks portfolios which are
%used as a probability of a connection between banks; the codes of the
%banks in the example are: C1001, C1002, C1003, C2004 and C2005
[map,mapRow] = xlsread('ProbMap_test.xls','map','A2:C6');
[out,mapCol] = xlsread('ProbMap_test.xls','map','B1:C1');

%select data and adding income parameters
sbs = size(bsNames_load);

%SIMULATION - AN EXAMPLE
ta  = bs_load(:,1);  %total assets

a = bs_load(:,2); %derivative assets 
l = bs_load(:,5); %derivative liabilities

e   = bs_load(:,4); %capital

%NETWORK GENERATOR
%if run with no optional parameters (one optional allowed), the system 
%generated with function "funIBankRandomGenV3" is generated without constraints on the size of exposures relative to capital
%(implemented for the so-called Large Exposure limits):
[X_rel,l_sim,X] = funIBankRandomGenV3(-l,a,bsNames_load(:,2),bsNames_load(:,4),map,mapRow,mapCol);
%description of the output:
%X          - matrix of the bilateral exposures
%X_rel      - matrix of relative exposures (according to Halaj and Kok (2013))
%l_sim      - vector of banks' derivative liabilities that are implied by
%the simulation (it may happen, given the approximate procedure - that
%l(i)>l_sim(i) for some banks i.





            