function unmixingParams = findSpectralUnmixingParams(experimentDetails)
debug = 1;

im11 = imread(experimentDetails.channel11);
im12 = imread(experimentDetails.channel12);
im21 = imread(experimentDetails.channel21);
im22 = imread(experimentDetails.channel22);

pixels = size(im11,1) * size(im11,2);
m11 = reshape(im11,pixels,1);
m12 = reshape(im12,pixels,1);
m21 = reshape(im21,pixels,1);
m22 = reshape(im22,pixels,1);

m11 = m11 - experimentDetails.blackValue;
m12 = m12 - experimentDetails.blackValue;
m21 = m21 - experimentDetails.blackValue;
m22 = m22 - experimentDetails.blackValue;

m21 = m21(m11>experimentDetails.lb1);
m11 = m11(m11>experimentDetails.lb1);

m12 = m12(m22>experimentDetails.lb2);
m22 = m22(m22>experimentDetails.lb2);

% figure(2);
% hist(double(m21));
% figure(3);
% hist(double(m12));

p1 = polyfit(double(m11),double(m21),1);
p2 = polyfit(double(m22),double(m12),1);
%  An optimisation procedure to do the same job as polyfit
%       x and y axes
% options = optimset('MaxFunEvals', 1000, 'TolFun', 1e-15, 'Display', 'final', 'LargeScale', 'off');
% init = [-p1(1),-p2(1)];
% ub = [0 0];
% lb = [-100 -100];
% [minvec, minval, exitflag] = fmincon(@cost,init,[],[], [],[],lb,ub,[],options,m11,m12,m21,m22);
if(debug)
    figure;
    hold on;
    x = 0:double(max(m11));
    y = polyval(p1,x);
    plot(m11,m21,'.g');
    plot(x,y,'k');
    x = 0:double(max(m22));
    y = polyval(p2,x);
    plot(m12,m22,'.r');
    plot(y,x,'k');
    xlim([0 200]);
    ylim([0 500]);
    hold off;
end

fid = fopen(experimentDetails.outfile,'w');
fprintf(fid,'%f %f\n',p1(1),p2(1));
%fprintf(fid,'%f %f\n',-minvec(1),-minvec(2));
fclose(fid);

%-----------------------------------------
function result = cost(v,m11,m12,m21,m22)
%-----------------------------------------
mix_12 = v(2);
mix_21 = v(1);
s11 = double(m11) + mix_12 * double(m21);
s21 = double(m21) + mix_21 * double(m11);

s12 = double(m12) + mix_12 * double(m22);
s22 = double(m22) + mix_21 * double(m12);

p1 = polyfit(double(s11),double(s21),1);
p2 = polyfit(double(s22),double(s12),1);

%result = std(s21) +  std(s12);
result = abs(p1(1)) + abs(p2(1));
fprintf(1,'%f %f %f %f %f\n',result,v(1),v(2),p1(1),p2(1));



