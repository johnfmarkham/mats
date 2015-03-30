clear variables; close all; clc;
inputRun = fullfile('..', '..', '..', '20150306-0014');
outputDir = fullfile('..', '..', 'uneven');

list = dir(fullfile(inputRun, '*Files'));
for i = 1:numel(list)
	currDir = list(i).name;
	list2 = dir(fullfile(inputRun, currDir, '*c01.tif'));
	sourceFile = fullfile(inputRun, currDir, list2(1).name);
	destFile = fullfile(outputDir, list2(1).name);
	copyfile(sourceFile, destFile);
	list2 = dir(fullfile(inputRun, currDir, '*c02.tif'));
	sourceFile = fullfile(inputRun, currDir, list2(1).name);
	destFile = fullfile(outputDir, list2(1).name);
	copyfile(sourceFile, destFile);
end