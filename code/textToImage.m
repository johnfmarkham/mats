function im = textToImage(im,font,str,y,x)


cols = 60;
xoff = 10;
yoff = 545;
xinc = 17;
yinc = 36;
font = cast(font,class(im));
for i=1:length(str)
    c = str(i);
    xChar = xoff + mod(c,cols) * xinc;
    yChar = yoff + floor(c/cols) * yinc;
    xDest = x + (i-1) * xinc;
    yDest = y;
    dy = yDest:yDest+yinc;
    dx = xDest:xDest+xinc;
    sy = yChar:yChar+yinc;
    sx = xChar:xChar+xinc;
    % TODO: Wrap around
    if(max(dy)<=size(im,1) && max(dx)<=size(im,2))
        if(size(im,3)==3)
            for i=1:3
                im(dy,dx,i) = bitor(im(dy,dx,i) , font(sy,sx));
            end
        else
            im(dy,dx) = bitor(im(dy,dx) , font(sy,sx));
        end
    end
end