%---------------------------------------
function plotHeaderedFile(plotFile,tableFile,opts)
%---------------------------------------
% Reads in a csv file whose first line is the field names
% Graphs all the numerical columns
%
isCSVDelimited = 1;
logfile_fd = 1;
if(isfield(opts,'isCSVDelimited'))
    isCSVDelimited = opts.isCSVDelimited;
end
if(isfield(opts,'logfile_fd'))
    logfile_fd = opts.logfile_fd;
end
s = readHeaderedFile(tableFile,isCSVDelimited,logfile_fd);
if(isempty(s))
    return;
end
if(~isstruct(s))
    return;
end
xlabel_text = '';
ylabel_text = '';
if(isfield(opts,'xlabel'))
    xlabel_text = opts.xlabel;
end
if(isfield(opts,'ylabel'))
    ylabel_text = opts.ylabel;
end
if(~isfield(opts,'groupings'))
    opts.groupings = 'together';
end
if(~isfield(opts,'dimensions'))
    opts.dimensions = 2;
end
if(isfield(opts,'fields') && opts.dimensions == 2)
    fields = opts.fields;
else
    fields = fieldnames(s);
end

formatStr = {'.r','.g','.b','.k','.c','.m','.y'};
nFields = length(fields);
rows = length(s);
if(opts.dimensions==2)
    % Simple plots where cols different quantities and rows are time
    legendText = {};
    h = figure();
    if(strcmp(opts.groupings,'together'))
        for  i=1:nFields
            hold on;
            subplot(nFields,1,i);
            x = 1:rows;
            y = [s.(fields{i})];
            if(ischar(y))
                log_fprintf(logfile_fd,'The fields %s contains this value.\nSomething must be wrong in %s\n.',fields{i},y,tableFile);
                close(h);
                return;
            end
            ylabel_text = fields{i};
            if(isfield(opts,'isLogScale') && opts.isLogScale~=0)
                y(y<1) = 1;
                y = log10(y);
                ylabel_text = strcat('log10(',ylabel_text,')');
            end
            plot(x,y,'.');
            ylabel(ylabel_text);
            xlabel(xlabel_text);
            hold off;
        end
    elseif(strcmp(opts.groupings,'separate'))
        hold on;
        for  i=1:nFields
            x = 1:rows;
            y = [s.(fields{i})];
            ylabel_text = fields{i};
            if(isfield(opts,'isLogScale') && opts.isLogScale~=0)
                y(y<1) = 1;
                y = log10(y);
                ylabel_text = strcat('log10(',ylabel_text,')');
            end
            plot(x,y,formatStr{i});
            legendText = { legendText{:},ylabel_text};
        end
        legend(legendText);
        xlabel(xlabel_text);
        hold off;
    end
    print(h, '-dpng', plotFile, '-r 300');
    close(h) 
elseif(opts.dimensions==3)
    % Animated plots where cols label x values and rows are time
    outfilejpg = strrep(plotFile,'.avi','_tmp.jpg');
    h = figure();
    x = zeros(nFields,1);
    y = zeros(rows,nFields);
    max_x = 0;
    for  i=1:nFields
        str = fields{i};
        x(i) = str2double(str(2:end));
    end
    for j=1:rows
        for  i=1:nFields
            y(j,i) = s(j).(fields{i});
        end
        lastNonZero = find(y(j,:),1,'last');
        max_x = max(max_x,x(lastNonZero));
    end
    if(isfield(opts,'isLogScale') && opts.isLogScale~=0)
        y(y<1) = 1;
        y = log10(y);
        ylabel_text = strcat('log10(',ylabel_text,')');
    end
    min_x = min(x);
    min_y = min(min(y));
    max_y = max(max(y));
    
    if(isempty(x) || isempty(y) || length(min_x)~=2 || length(min_y)~=2)
        log_fprintf(logfile_fd,'Either x or y is empty.  rows = %d though.\n',rows);
        log_fprintf(logfile_fd,'or min_x is the wrong size.  min_x = %d \n',min_x);
        log_fprintf(logfile_fd,'or min_y is the wrong size.  min_y = %d \n',min_y);
    else
        aviobj = VideoWriter(plotFile);
        aviobj.Quality = 100;
        open(aviobj);
        for j=1:rows
            bar(x,y(j,:),'hist');
            xlim([min_x max_x]);
            ylim([min_y max_y]);
            xlabel(xlabel_text);
            ylabel(ylabel_text);
            title(sprintf('frame = %4d',j));
            print(h, '-djpeg', outfilejpg, '-r 100');
            % avisynth objects to some frame sizes
            im = imread(outfilejpg);
            dim1 = floor(size(im,1)/8) * 8;
            dim2 = floor(size(im,2)/8) * 8;
            imtrimmed(1:dim1,1:dim2,:) = im(1:dim1,1:dim2,:);
            
            writeVideo(aviobj,imtrimmed);
            delete(outfilejpg);
        end
        close(aviobj);
    end
    close(h) 
end

