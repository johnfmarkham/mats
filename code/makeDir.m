%---------------------------------------
function ret = makeDir(path,positionDetails)
%---------------------------------------
% Makes the directory path (which may be several levels deep) if it doesn't
% exist already.
ret = 1;
for i=1:length(path)
    if(path(i)=='/' || path(i)=='\' || i==length(path))
        if(~dirExists(path(1:i)))
            log_fprintf(positionDetails,'Making %s\n',path(1:i));
            ret = (ret && mkdir(path(1:i)));
            if(ret==0)
                log_fprintf(positionDetails,'Broke trying to make %s\n',path(1:i));
                return;
            end
        end
    end
end

