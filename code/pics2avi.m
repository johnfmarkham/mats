function pics2avi(path,piclist,aviFileName)

aviobj = VideoWriter(aviFileName);
aviobj.Quality = 100;
open(aviobj);
for i = 1:length(piclist)
    im = imread(strcat(path,piclist(i).name));
    writeVideo(aviobj,im);
end
close(aviobj);