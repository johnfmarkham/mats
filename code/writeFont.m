function writeFont(fontFile) 
% Make an image and put a font in it for later use
dirList = dir(fontFile);
if(~isempty(dirList))
    return;
end
im = zeros(1280,1080);
hf = figure('color','black','units','normalized','position',[.1 .1 .8 .8]); 
set(gca,'units','pixels','position',[5 5 size(im,2)-10 size(im,1)-10],'visible','off')
cols = 60;
xoff = 10;
yoff = 400;
xinc = 17;
yinc = 36;

for i=1:255
    x =  xoff + mod(i,cols) * xinc;
    y = yoff - floor(i/cols) * yinc;
    text('Interpreter','none','units','pixels','FontName','FixedWidth','Color','w','position',[x y],'fontsize',20,'string',sprintf('%c',i)); 
end

im = getframe(gca);
pixels = uint16(im.cdata(:,:,1));
pixels(pixels~=0) = 65535;
imwrite(pixels,fontFile,'Compression','none');
close(hf) 

