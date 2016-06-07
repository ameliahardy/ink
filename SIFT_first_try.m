% Need to download vlfeat binary first from webpage - didn't want to store
% all this in git

run('../../../../Downloads/vlfeat-0.9.20/toolbox/vl_setup'); %for one-time setup (run everytime)

heart_image = imread('google_img_tattoos/hearts/plain_heart.jpg');

heart_image = single(rgb2gray(heart_image)); %vl_sift needs grayscale

bird_image = imread('google_img_tattoos/birds/7.jpg');

bird_image = single(rgb2gray(bird_image));

[f_heart, d_heart] = vl_sift(heart_image); %frames and descriptors
[f_bird, d_bird] = vl_sift(bird_image);

% now compare other images with these two to categorize as birds or hearts

% Here, SIFT is looking at pure L2 distance between two descriptors, so
% this is probably not the best method for us. However, can use this same
% process with other vlfeatures.
heart_images = dir('google_img_tattoos/hearts/*.jpg');
total = 0;
correct = 0;
for img = heart_images'
    fileName = fullfile('google_img_tattoos/hearts/', img.name);
    img = imread(fileName);
    img = single(rgb2gray(img));
    [f, d] = vl_sift(img);
    [heart_match, heart_score] = vl_ubcmatch(d_heart, d);
    [bird_match, bird_score] = vl_ubcmatch(d_bird, d);
    % taking average, might want to change this
    total = total + 1;
    if sum(heart_score)/size(heart_match, 2) < sum(bird_score)/size(bird_match, 2)
        correct = correct + 1;
    end
    fraction_correct = correct/total;
end

%Print hearts correctness
fraction_correct

bird_images = dir('google_img_tattoos/birds/*.jpg');
total = 0;
correct = 0;
for img = bird_images'
    fileName = fullfile('google_img_tattoos/birds/', img.name);
    img = imread(fileName);
    img = single(rgb2gray(img));
    [f, d] = vl_sift(img);
    [heart_match, heart_score] = vl_ubcmatch(d_heart, d);
    [bird_match, bird_score] = vl_ubcmatch(d_bird, d);
    % taking average, might want to change this
    total = total + 1;
    if sum(heart_score)/size(heart_match, 2) > sum(bird_score)/size(bird_match, 2)
        correct = correct + 1;
    end
    fraction_correct = correct/total;
end

% Birds categorized correctly
fraction_correct


