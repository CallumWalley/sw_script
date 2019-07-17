function o=fcnPSVG(y,opt)
% y is the time series o is the negative of the log-log slope
% opt=1 plots the log-log slope and point values
if nargin<2
    opt=0;
end

[P, x] = countGraphEdges(y);

p=polyfit(log(2:x-1),log(P(2:x-1)),1); %find the power law slope

if opt==1
    ln=length(y);
    kk=1:ln;
    %loglog(kk,P); %do a log-log plot of the distribution
    plot(log(kk),log(P),'.');
    hold on
    x=[log(kk(1)):0.1:log(kk(length(kk)))];
    plot(x,p(1)*x+p(2),'r');
    text(2,9,['Slope=' num2str(p(1))]);
    hold off
    fprintf('Slope=%4.4f\n',p(1));
end

o=-p(1);
