
%run('../../../../Downloads/vlfeat-0.9.20/toolbox/vl_setup'); %for one-time setup (run everytime)

fid = fopen('../../../../Desktop/tatt-c_ongoing/tattoo_identification/probesAll.txt');
probe_names = textscan(fid, '%s', 'delimiter', '\n');
fclose(fid);

fid = fopen('../../../../Desktop/tatt-c_ongoing/tattoo_identification/galleryAll.txt');
gallery_names = textscan(fid, '%s', 'delimiter', '\n');
fclose(fid);

% probe_names{1, 1}(1) to get first name of probe

ranks = [30];

fid = fopen('../../../../Desktop/tatt-c_ongoing/tattoo_identification/ground_truth.txt');
ground_truth_lines = textscan(fid, '%s', 'delimiter', '\n');
fclose(fid);

tokens = [];

for i = 1:length(ground_truth_lines{1,1})
    tokens = [tokens; strsplit(char(ground_truth_lines{1,1}(i)), '|')];
end

ground_truth_map = containers.Map();

for i = 1:length(tokens(:, 1))
    if isKey(ground_truth_map, tokens{i, 1})
        char_array = ground_truth_map(tokens{i, 1});
        char_array{1, length(char_array)+1} = tokens{i, 2};
        ground_truth_map(tokens{i, 1}) = char_array;
    else
        ground_truth_map(tokens{i, 1}) = {char(tokens{i, 2})};
    end
end

gallery_features = {};
for j = 1:length(gallery_names{1,1})
    image_file_name = fullfile('../../../../Desktop/tatt-c_ongoing/tattoo_identification/images', char(gallery_names{1,1}(j)));
    original_img = imread(image_file_name);
    if size(original_img, 3) == 1
        black_white_img = original_img;
    else
        black_white_img = rgb2gray(original_img);
    end
    img_size = size(black_white_img);
    num_octaves = 3;
    if img_size(1) > 100 || img_size(2) > 100
        num_octaves = 5;
    end
    galleryPoints = detectSURFFeatures(black_white_img, 'MetricThreshold', 100.0, 'NumOctaves', num_octaves);
    [features, points] = extractFeatures(black_white_img, galleryPoints);
    gallery_features{j} = features;
end
save('SURF_gallery_levels.mat', 'gallery_features')

probe_features = {};
for j = 1:length(probe_names{1,1})
    image_file_name = fullfile('../../../../Desktop/tatt-c_ongoing/tattoo_identification/images', char(probe_names{1,1}(j)));
    original_img = imread(image_file_name);
    if size(original_img, 3) == 1
        black_white_img = original_img;
    else
        black_white_img = rgb2gray(original_img);
    end
    img_size = size(black_white_img);
    num_octaves = 3;
    if img_size(1) > 100 || img_size(2) > 100
        num_octaves = 5;
    end
    probePoints = detectSURFFeatures(black_white_img, 'MetricThreshold', 100.0, 'NumOctaves', num_octaves);
    [features, points] = extractFeatures(black_white_img, probePoints);
    probe_features{j} = features;
end
save('SURF_probe_levels.mat', 'probe_features')

load('SURF_probe_octaves.mat')
load('SURF_gallery_octaves.mat')
%{ 
%this makes total number of gallery images 358
% add in face junk images
face_features = {};
faces = dir('../../../../Desktop/tatt-c_ongoing/tattoo_identification/junk_images/faces/*.jpg');
for i = 1:numel(faces)
    image_file_name = fullfile('../../../../Desktop/tatt-c_ongoing/tattoo_identification/junk_images/faces/', char(faces(i).name));
    original_img = imread(image_file_name);
    if size(original_img, 3) == 1
        black_white_img = original_img;
    else
        black_white_img = rgb2gray(original_img);
    end
    facePoints = detectSURFFeatures(black_white_img, 'MetricThreshold', 100.0);
    [features, points] = extractFeatures(black_white_img, facePoints);
    face_features{i} = features;
end 

% add in background junk images
back_features = {};
back = dir('../../../../Desktop/tatt-c_ongoing/tattoo_identification/junk_images/background/*.jpg');
for i = 1:numel(back)
    image_file_name = fullfile('../../../../Desktop/tatt-c_ongoing/tattoo_identification/junk_images/background/', char(back(i).name));
    original_img = imread(image_file_name);
    if size(original_img, 3) == 1
        black_white_img = original_img;
    else
        black_white_img = rgb2gray(original_img);
    end
    backPoints = detectSURFFeatures(black_white_img, 'MetricThreshold', 100.0);
    [features, points] = extractFeatures(black_white_img, backPoints);
    back_features{i} = features;
end 

% add in body junk images
body_features = {};
body = dir('../../../../Desktop/tatt-c_ongoing/tattoo_identification/junk_images/body/*.jpg');
for i = 1:numel(body)
    image_file_name = fullfile('../../../../Desktop/tatt-c_ongoing/tattoo_identification/junk_images/body/', char(body(i).name));
    original_img = imread(image_file_name);
    if size(original_img, 3) == 1
        black_white_img = original_img;
    else
        black_white_img = rgb2gray(original_img);
    end
    bodyPoints = detectSURFFeatures(black_white_img, 'MetricThreshold', 100.0);
    [features, points] = extractFeatures(black_white_img, bodyPoints);
    body_features{i} = features;
end 

% add in face junk images
uncropped_features = {};
uncropped = dir('../../../../Desktop/tatt-c_ongoing/tattoo_identification/junk_images/uncropped_tatts/*.jpg');
for i = 1:numel(uncropped)
    image_file_name = fullfile('../../../../Desktop/tatt-c_ongoing/tattoo_identification/junk_images/uncropped_tatts/', char(uncropped(i).name));
    original_img = imread(image_file_name);
    if size(original_img, 3) == 1
        black_white_img = original_img;
    else
        black_white_img = rgb2gray(original_img);
    end
    uncroppedPoints = detectSURFFeatures(black_white_img, 'MetricThreshold', 100.0);
    [features, points] = extractFeatures(black_white_img, uncroppedPoints);
    uncropped_features{i} = features;
end 

gallery_features = [gallery_features face_features back_features body_features uncropped_features];
%}

for r =1:length(ranks)
    matches_final = zeros(length(probe_names{1,1}), ranks(r));
    for i = 1:length(probe_names{1,1})
        probe_img = probe_features{1, i};
        scores = zeros(1, ranks(r));
        imgs = zeros(1, ranks(r));
        for j = 1:length(gallery_names{1,1})
            gallery_img = gallery_features{1,j};
            pairs = matchFeatures(probe_img, gallery_img);
            [s, index] = min(scores);
            match_ratio = length(pairs)/min([size(gallery_img, 2), size(probe_img, 2)]);
            if match_ratio > s
                scores(1, index) = match_ratio;
                imgs(1, index) = j;
            end
        end
        [sorted_scores, indices] = sort(scores(1, :), 'descend');
        for k = 1:length(indices)
            matches_final(i, k) = imgs(1, indices(k));
        end
    end
end

resultsFile = fopen('SURF_neighbor_results.txt_2', 'a+');

all_ranks = [1, 5, 10, 20, 30];
for m = 1:length(all_ranks)
    rank = all_ranks(m);
    average_recall = 0;
    average_precision = 0;
    for i = 1:size(matches_final, 1)
        answer = 0;
        answer_arr = ground_truth_map(char(probe_names{1, 1}(i)));
        number_correct = 0;
        p = 0;
        for r = 1:rank
            match_index = matches_final(i, r);
            if match_index == 0
                continue;
            end
            x = strmatch(char(gallery_names{1,1}(match_index)), answer_arr);
            if ~isempty(x)
                number_correct = number_correct+1;
                p = p + number_correct/r;
                answer = 1;
            else
                if rank == 30 && r == 30 && answer == 0
                    fprintf(resultsFile, 'answer: %s, guess: %s\n', char(answer_arr), char(gallery_names{1,1}(matches_final(i, 1))));
                end
            end
        end
        average_recall = average_recall + number_correct/size(answer_arr, 2);
        average_precision = average_precision + p/size(answer_arr, 2);
    end
    rank
    precision = average_precision/size(matches_final, 1)
    recall = average_recall/size(matches_final, 1)
end

fclose(resultsFile);


