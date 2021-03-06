function [Mat Eval]=entropy_rand(Asset,Liab,Nrand, S,U)
% Estimates randomized interbank matrixes
%
% Output
% Mat: 
% 3 dimensional matrix. First 2 dimensions interbank matrix, third 
% dimension Nrand+1 interbank matrizes. Mat(:,:,1) is maximum 
% entropy solution, remaining Nrand matrixes are randomized 
%
% Mat is 2 rows\columns larger than asset and liab vector becasue of
% a) sink bank and b) contains row and column sum at end
% for example
% row sum for rows 1:N+1 (where N number of banks) for first column
% equals  total interbank assets of banks 1, where rows 2:N provide
% assets vis-a-vie bank 2 to N, row N+1 is asset to sink bank
% column sum over columns 1:N+1 (where N number of banks) for first row 
% equals total  interbank liabilities of banks 1, where column 2:N provide
% liabilities vis-a-vie bank 2 to N, column N+1 is liab to sink bank
%
% Eval:
% provides different measures of difference between random solution
% and ME solution (1. column simulation number, 2. col norm of matrix -ME
% solution, 3. col for sum of rel difference between matrix and ME (ME base case)
% 4. col number of zeros off the diagonal.
%
% Input: 
% Asset: Vector of total interbank assets per bank
% Liab: Vector of total interbank liabilities per bank
% (Entering a single matrix will assign its sums to these vectors).
% Vectors can differ in length, as non-square matrices are permitted.
% Entropy is maximised w.r.t flat prior but with zero diagonal.
% Nrand: number of random simulations for matrix
%
% Optional:  
% Forth argument allows to creat sink bank if S=1
%
% fith argument allows to (here sink bank is not considered)
% - enforce absolute entropy: entropy(r,c,ones(length(r),length(c))), or
% - refine relative entropy: specify an a priori matrix U.


% Based on ras.m by Christian Upper, extended by Goetz von Peter, and
% Mathias Drehamnn 


%% Setting
I=1000;                                             % Maximum number of iterations

%%  ============= Checking inputs =============
% Single matrix



% Two vectors
% r and c not ideal but orignially coded so kept

r=Liab; 
c=Asset;                                 % makes inputs column vectors
if min([r;c])<0
    error('elements in r and c have to be non-negative')
end


if  (S==1)                     % Creating the sink bank
disp('Sink bank created')

    if (sum(c)>sum(r))
        disp('Interbank Liabilities smaller than interbank assets')
        r=[r ; (sum(c)-sum(r))];
        c=[c ;0];
    end
    if (sum(c)<sum(r))
         disp('Interbank Liabilities larger than interbank assets')
         c=[c ; (sum(r)-sum(c))];
        r=[r ;0];
    end
end



k1=sum(r); k2=sum(c);                           % totals
r=r/k1; c=c/k2; T=(k1+k2)/2;                    % scale by totals


rows=length(r); cols=length(c); 
if rows*cols== rows+cols+min(rows,cols)
        warndlg('Zero degrees of freedom: exact solution rather than estimation.', '!! WARNING !!')
        X=entropy_exact(r,c);
elseif rows*cols<rows+cols+min(rows,cols)
    warndlg('Inconsistent system: too few dimensions.', '!! WARNING !!')
    error
end

% 5 arguments
if (nargin==5) & (size(U)~=[rows cols])
        error('U disagrees with dimensions of rows, columns.')
end






%% ============= Prior: absolute or relative =============
if nargin == 5
    X=U./T;                                     % RELATIVE: use a prior matrix U, scaled down.
    disp('Relative entropy maximisation')
else

    EX=r*c';                                     % ABSOLUTE: outer product as initial guess (faster but equivalent to flat prior)
    U=triu(EX, +1);                              % set diagonal to 0
    L=tril(EX, -1);
    EX=U+L;
    %disp('Absolute entropy maximisation (plus zero-diagonal restriction)')
end

%% ==Randomizing and creating IB matrix

% initializing
Mat=zeros(size(r,1)+1, size(c,1)+1, Nrand+1);
Eval=zeros(Nrand+1,4);


for tt=1:Nrand+1 
    

    
    if tt==1
        X=EX;           %Maximum entropy solution 
    else
        R=2*rand(size(r,1), size(c,1)); 
        X=EX.*R;        % Randomize prior so that on average prior is equal to max entropy
    end
    
    
    %============= RAS-Algorithm =============

    indrow=find(sum(X')>0); m=length(indrow);       % indices of positive row sums (to apply method only to pos entries)
    indcol=find(sum(X)>0); n=length(indcol);        % NB Row sums of zero will produce zero row; same for columns.
    for i=1:I
        X(indrow,indcol)=X(indrow,indcol).*kron(ones(m,1),c(indcol)'./sum(X(indrow,indcol)));	% Correction of row sums
        X(indrow,indcol)=X(indrow,indcol).*kron(r(indrow)./sum(X(indrow,indcol)')',ones(1,n));	% Correction of column sums
        if max(abs([sum(X')';sum(X)']-[r;c]))<0.0000001/length(r)
            %disp(['Convergence after ',num2str(i),' iterations'])
            break
        elseif i==I
            warndlg('Max. iterations exceeded. Last iteration matrix is returned', '!! WARNING !!')
        end
    end

    Mat(1:size(r,1),1:size(c,1),tt)=X*T;                                          % scale back up
    Mat(size(r,1)+1,1:size(c,1),tt)=sum(X*T);                                        % row sums
    Mat(1:size(r,1),size(c,1)+1,tt)=sum(X*T,2);                                        % column sums

    % Analysing difference to ME solution
    Eval(tt,1)=tt;
    Eval(tt,2)=norm(Mat(1:size(Asset,1),1:size(Asset,1),tt)-Mat(1:size(Asset,1),1:size(Asset,1),1));                        %Norm
    Eval(tt,3)=nansum(nansum(abs(Mat(1:size(Asset,1),1:size(Asset,1),tt)-Mat(1:size(Asset,1),1:size(Asset,1),1))./Mat(1:size(Asset,1),1:size(Asset,1),1)));       % Sum of relative differences   
    Eval(tt,4)=length(find(Mat(1:size(Asset,1),1:size(Asset,1),tt)==0))-length(Asset);               % total numbers of zeros which are not on diagonal   
end

