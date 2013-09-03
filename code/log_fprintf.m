function log_fprintf(varargin)
%%
% fprintf-like function that puts a date/time string at the front of the
% line
if(isstruct(varargin{1}) && isfield(varargin{1},'logfile_fd'))
    fd = varargin{1}.logfile_fd;
elseif(isfloat(varargin{1}))
    fd = varargin{1};
else
    fprintf(1,'The first argument to log_fprintf() must either be a file descriptor or a struct with member logfile_fd (and, optionally, verbose)\n');
    return;
end

if(isfield(varargin{1},'verbose') && varargin{1}.verbose~=0)
    fprintf(1,varargin{2:end});
end
% TODO: Something nicer here
varargin{2} = strrep(varargin{2},'\n',',');
fprintf(fd,'%04d%02d%02d.%02d:%02d:%04.2f,',datevec(now()));
fprintf(fd,varargin{2:end});
fprintf(fd,'\n');
end