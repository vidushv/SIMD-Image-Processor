clear all
close all
instrreset;

% Test Type:
% 0 -- Random MNIST image
% 1 -- 128x128 test image
testType = 1;

% Number of bins for the histogram
numBins = 8;

% Probably don't change this
bytesPerBin = 2;

% If you change this, makesure you change uart.v as well
baudRate = 115200;

% Image Name
imgName = 'standard_test_images_small/livingroom.tif';

if testType == 0
    images = loadMNISTImages('handwriting-images');
    [numBytes, numImages] = size(images);
    imageIndex = randi(numImages);

    % Get a random image and convert range to 0-255 (8 bits)
    dim = sqrt(numBytes);
    A = 255 - round(255*reshape(images(:,imageIndex),dim,dim));
elseif testType == 1
    A = imread(imgName);
    A = A(:,:,1);
end

% Set Up Serial Port

[height, width] = size(A);

s = serial('com1','BaudRate',baudRate);
s.OutputBufferSize = height;

% Send Image to FPGA
fopen(s);
for i = 1:width
    fwrite(s, A(:,i));
end
S = fread(s, numBins * bytesPerBin);
fclose(s);

% Plot Results
figure
subplot(1,3,1)
imshow(A, [0 255])
title('Image Sent to FPGA')

% Matlab calculated histogram
subplot(1,3,2)
N = histc(reshape(double(A),[],1), linspace(0,256,numBins+1));
bar(N)
title('Histogram generated by MATLAB')

% FPGA Calculated Histogram
subplot(1,3,3)

% Reconstruct transmitted data
M = zeros(numBins,1);
for i = 1:bytesPerBin
   M = M + 2^(8*(i-1))*S(i:bytesPerBin:end);
end
bar(M)
title('Histogram generated by FPGA')

% Print out differences. Should be all zeros
histogram_diferences = (N(1:end-1) - M)'
