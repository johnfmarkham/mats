%---------------------------------------
function ret = dirExists(path)
%---------------------------------------
ret = isdir(path);
% ret = 1;
% for i=1:length(path)
%     if(path(i)=='/' || path(i)=='\' || i==length(path))
%         dirList = dir(path(1:i));
%         if(length(dirList)==0)
%             ret = 0;
%             return;
%         end
%     end
% end

