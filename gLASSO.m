function [S,K] = gLASSO(X, F, lambda, rho)
% X: N by p data matrix
% F: number of frequency sampling points
% lambda: LASSO tuning parameter
% rho: augmented Lagrangian parameter

[N,p] = size(X); % no. of observations
%F=4; % no. of sampling points
%lambda = 0.1; rho = 1.2; threshold =3;
% model = 2; % 1: IID 2: VAR

w=@(m) exp(-m^2); % window function

%% construct autocorrelation estimator R
% R(:,:,1) => R[m=0]
% R(:,:,N) => R[m=N-1]
R=zeros(p,p,N);
for m=1:N
    for n=m:N
        R(:,:,m)=R(:,:,m)+X(n,:)'*X(n-m+1,:);
    end
end
R=R/N;

%% construct SDM estimator S
% S(:,:,1)=S[f=1]
% S(:,:,F)=S[f=F]
S=zeros(p,p,F);
parfor f=1:F
    S(:,:,f)=S(:,:,f) + w(0)*R(:,:,1);
    for m=1:N-1
        S(:,:,f)=S(:,:,f)+ ...
            w(m)*(R(:,:,m)*exp(-1i*2*pi*m*(f-1)/F) ...
            +ctranspose(R(:,:,m))*exp(1i*2*pi*m*(f-1)/F));
    end
eig_vals(:,f)=eig(S(:,:,f));
end
U=max(max(eig_vals));

%% find K[.] using ADMM
K=zeros(p,p,F);
parfor f=1:F
    [K_step,~]=ADMM((S(:,:,f)+S(:,:,f).')/2,lambda,rho);
    K(:,:,f) = K_step;
end