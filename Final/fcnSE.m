function [ e, A, B ] = fcnSE( y, m, r, k, d )
%SAMPLEENTROPY Computes the probability that two segments y(i+1:i+m+k) and 
% y(j+1:j+m+k) have Chebychev distance < r*std(y, 1) given the fact that 
% y(i+1:i+m) and y(j+1:j+m) have Chebychev distance < r*std(y, 1).
% Specifying a value for d gives the multiscale version.  This
% implementation requires the creation of a length(y)*(length(y)-1)/2 
% dimensional vector.
% 
% Based on "Multiscale entropy analysis of biological signals"
% By Madalena Costa, Ary L. Goldberger, and C.-K. Peng
% Published on 18 February 2005 in Phys. Rev. E 71, 021906.
%
% This code was implemented by John Malik on 26 April 2017.
% Contact: jmalik@math.utoronto.ca

switch nargin
   case 1
       m = 5;
       r = 0.2;
       k = 1;
       d = 1;
   case 2
       r = 0.2;
       k = 1;
       d = 1;
   case 3
       k = 1;
       d = 1;
   case 4
       d = 1;
end

y = y(:);

N = length(y);
X = zeros(N - d * (m + k - 1), m + k);
for i = 1:m + k
   X(:, i) = y((i - 1) * d + 1:N - d * (m + k - 1) + d * (i - 1));
end
X = X(~any(isnan(X), 2), :);

if isempty(X)
   e = NaN;
   return
end

d0 = pdist(X, 'chebychev');
A = sum(d0 < r * nanstd(y, 1));
X = X(:, 1:m);
d0 = pdist(X, 'chebychev');
B = sum(d0 < r * nanstd(y, 1));
if A == 0 || B == 0
   e = NaN;
   return
end
e = log(B / A);

end