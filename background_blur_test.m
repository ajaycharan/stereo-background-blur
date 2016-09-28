close all
clear
clc

PROJECT_WORK_DIR = 'D:\ShreyasSkandan\Smart_Toy_Repository\src\ShreyasSkandan\code_postprocessing_gopro\StereoPortraitMode';

% Load rectified images - Colour and Grayscale
RECT_LEFT_BW = imread(strcat(PROJECT_WORK_DIR,'\RectifiedImages\LEFT\left_rectifiedFrame0000001.png'));
RECT_RIGHT_BW = imread(strcat(PROJECT_WORK_DIR,'\RectifiedImages\RIGHT\right_rectifiedFrame0000001.png'));
RECT_LEFT_CLR = imread(strcat(PROJECT_WORK_DIR,'\RectifiedImages\Colour\leftCLR_rectifiedFrame0000001.png'));
RECT_RIGHT_CLR = imread(strcat(PROJECT_WORK_DIR,'\RectifiedImages\Colour\rightCLR_rectifiedFrame0000001.png'));

% Load the depth map corresponding to the rectified image
%NUMPY_LOC = 'D:\TestFocus\Rectified\Focus\DepthImages\NUMPY\depth_test1000000.npy';
%DEPTH = readNPY(NUMPY_LOC);
DEPTH = load(strcat(PROJECT_WORK_DIR,'\DepthImages\disparityimage.mat'));
DEPTH = DEPTH.DEPTH;
%save('disparityimage.mat','DEPTH');

slope_threshold = 8;
depth_threshold = 8;
% For K-Means depth segmentation algorithm
% nDepths = 4;

% Created the background image - blurred image
H = fspecial('disk',20);
blurredImage = imfilter(RECT_LEFT_CLR,H,'replicate');

% Unroll both colour and blurred images into vectors
colour_image_vec = reshape(RECT_LEFT_CLR,[size(DEPTH,1)*size(DEPTH,2),3]);
blurred_image_vec = reshape(blurredImage,[size(DEPTH,1)*size(DEPTH,2),3]);

% Use K-Means to segment out the depth image into
% ab = reshape(DEPTH,[size(DEPTH,1)*size(DEPTH,2),1]);
% [cluster_idx, cluster_center] = kmeans(ab,nDepths,'distance','sqEuclidean','Replicates',3);
% pixel_labels = reshape(cluster_idx,[size(DEPTH,1),size(DEPTH,2)]);
% save('kmeansresult.mat',pixel_labels);
% figure,
% imshow(pixel_labels,[]);
segdata = load('kmeansresult.mat');
pixel_labels = segdata.pixel_labels;

% Create a mask of all pixels at the prescribed depth (usually the max
% disparity -> minimum depth)
mask = zeros(size(DEPTH,1)*size(DEPTH,2),1);
indices = find(pixel_labels == max(max(pixel_labels)));
mask(indices) = 1;
mask = reshape(mask,[size(DEPTH,1),size(DEPTH,2)]);

% Perform a few morphological operations to create a more uniform mask
mask = imfill(mask,'holes');
mask = bwmorph(mask,'clean');
mask = bwmorph(mask,'open',11);
mask = bwmorph(mask,'close',10);
mask = bwmorph(mask,'thicken',3);

% Extract the largest connected component
mask = bwareafilt(mask, 1, 'largest');
mask = imfill(mask,'holes');
mask = bwmorph(mask,'spur',25);

% st = regionprops(mask,'BoundingBox');
% width = st.BoundingBox(3);
% height = st.BoundingBox(4);
% row_start = st.BoundingBox(2);
% col_start = st.BoundingBox(1);
% row_end = row_start + height;
% col_end = col_start + width;

% Create a distance transform matrix from the mask outward
D = bwdist(mask);
D(D>depth_threshold) = slope_threshold;
% Standardize the distance transform to create a gradient
maxD = max(max(D));
minD = min(min(D));
mean = mean2(D);
normDistTransVec = (D - minD)/(maxD-minD);
%newmask = ones(size(DEPTH,1),size(DEPTH,2));
%newmask(row_start-padding:row_end+padding,col_start-padding:col_end+padding) = normDistTransVec;
%normDistTransVec = newmask;
newmask = normDistTransVec;
figure,
imagesc(newmask);

Evec = reshape(normDistTransVec,[size(normDistTransVec,1)*size(normDistTransVec,2),1]);
gradient = [Evec,Evec,Evec];

% Apply the gradient onto the image
resultingImageVec = double(gradient).*double(blurred_image_vec) + double(1-gradient).*double(colour_image_vec);
resImage = reshape(resultingImageVec,[size(DEPTH,1),size(DEPTH,2),3]);

%figure,
%imshow(uint8(resImage));

%figure,
%imshow(reshape(colour_image_vec,[size(DEPTH,1),size(DEPTH,2),3]));


figure,
subplot(2,1,1);
imshow(imresize(uint8(resImage),0.5,'nearest'));

subplot(2,1,2);
imshow(imresize(RECT_LEFT_CLR,0.5,'nearest'));




