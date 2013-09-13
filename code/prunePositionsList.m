% takes a list of folders as input and only leaves
% folders for selected positions in [chosenPos] vector
function dirList = prunePositionsList(dirList, chosenPos)
vPosMap = [];
vPosMap(chosenPos) = true;

n = numel(dirList);
vListMap = false(1, n);

for i = 1:n
	s = dirList(i).name;
	% TBD allow a custom function for extracting position number
	k1 = strfind(s, '(') + 1;
	if (isempty(k1))
		continue
	end
	k2 = strfind(s, ')') - 1;
	if (isempty(k2))
		continue
	end
	
	idx = str2double(s(k1(1):k2(1)));
	if (isnan(idx))
		continue
	end
	if (idx > numel(vPosMap))
		continue
	end
	if (vPosMap(idx))
		vListMap(i) = true;
	end
end
dirList = dirList(vListMap);
end