function [FNN] = fcnFNN(x,tao,mmax,rtol,atol)
%x : time series
%tao : time delay
%mmax : maximum embedding dimension
%reference:M. B. Kennel, R. Brown, and H. D. I. Abarbanel, Determining
%embedding dimension for phase-space reconstruction using a geometrical 
%construction, Phys. Rev. A 45, 3403 (1992). 
%author:"Merve Kizilkaya"
%rtol=15
%atol=2;
N=length(x);
Ra=std(x,1);
FNN = zeros(mmax, 1);
for m = 1:mmax
    M = N - m*tao;
    % Phase space reconstruction
    Y = x((1:M) + (0:(m-1))'*tao)';
    onesM1 = ones(M,1);
    for n = 1:M
        y0 = onesM1 * Y(n,:);
        distance = sqrt(sum( (Y - y0).^2, 2) );

        [val, indx_ref] = min(distance);

        % find the next closest value/index to location indx_ref
        distance(indx_ref) = realmax;
        [neardis nearpos] = min(distance);

        D = abs(x(n+m*tao) - x(nearpos + m*tao));
        R = sqrt(D*D + neardis*neardis);
        if D/neardis > rtol || R/Ra > atol
             FNN(m,1) = FNN(m,1) + 1; 
        end
    end
end
FNN=(FNN./FNN(1,1))*100;
% figure
% plot(1:length(FNN),FNN)
% grid on;
% title('Minimum embedding dimension with false nearest neighbours')
% xlabel('Embedding dimension')
% ylabel('The percentage of false nearest neighbours')
