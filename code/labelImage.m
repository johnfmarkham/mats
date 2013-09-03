function im = labelImage(im,file,scalebarpixels,scalebartext,font)

s = dir(file);
xinc = 17;
yinc = 36;

ds = datestr(s.datenum,' yyyymmdd HH:MM:SS');
str = strcat(s.name,ds);
% fprintf(1,'%s\n',str);

im = textToImage(im,font,str,10,10);
if(length(scalebartext)>1)
    letters = round(scalebarpixels/xinc);
    scalebar = char(6 * ones(letters + 2,1));
    scalebar(1) = 25;
    scalebar(end) = 23;
    tstart = ceil((letters - length(scalebartext)) / 2) + 1;
    tend = tstart + length(scalebartext)-1;
    scalebar(tstart:tend) = scalebartext;
    im = textToImage(im,font,scalebar,yinc,500);
end
