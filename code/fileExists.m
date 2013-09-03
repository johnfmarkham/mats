function ret = fileExists(filename)
        dirList = dir(filename);
        if(length(dirList)==0)
            ret = 0;
            return;
        end
ret = 1;