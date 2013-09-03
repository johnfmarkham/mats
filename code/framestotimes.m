function times = framestotimes(p,timesField,frames)
timesTable = [p.(timesField)];
n = length(frames);
times = zeros(n,1);
for i=1:n
    times(i) = timesTable(frames(i));
end