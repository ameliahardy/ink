
%run('../../../../Downloads/vlfeat-0.9.20/toolbox/vl_setup'); %for one-time setup (run everytime)
% probe_names{1, 1}(1) to get first name of probe

fid = fopen('../../../../Desktop/tatt-c_ongoing/tattoo_identification/galleryAll_2.txt');
probe_names = textscan(fid, '%s', 'delimiter', '\n');
fclose(fid);

fid = fopen('../../../../Desktop/tatt-c_ongoing/tattoo_identification/galleryAll_2.txt');
gallery_names = textscan(fid, '%s', 'delimiter', '\n');
fclose(fid);

ranks = [30];

fid = fopen('../../../../Desktop/tatt-c_ongoing/tattoo_identification/ground_truth_2.txt');
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

%this makes total number of gallery images 358
% add in face junk images
probe_features = {};
probes = dir('../../../../Desktop/tatt-c_ongoing/tattoo_identification/new_tattoo_dataset/segmented/*.jpg');
for i = 1:numel(probes)
    image_file_name = fullfile('../../../../Desktop/tatt-c_ongoing/tattoo_identification/new_tattoo_dataset/segmented/', char(probes(i).name));
    original_img = imread(image_file_name);
    if size(original_img, 3) == 1
        black_white_img = original_img;
    else
        black_white_img = rgb2gray(original_img);
    end
    probePoints = detectSURFFeatures(black_white_img, 'MetricThreshold', 100.0);
    [features, points] = extractFeatures(black_white_img, probePoints);
    probe_features{i} = features;
end 

gallery_features = {};
gallery = dir('../../../../Desktop/tatt-c_ongoing/tattoo_identification/new_tattoo_dataset/segmented/*.jpg');
for i = 1:numel(gallery)
    image_file_name = fullfile('../../../../Desktop/tatt-c_ongoing/tattoo_identification/new_tattoo_dataset/segmented/', char(gallery(i).name));
    original_img = imread(image_file_name);
    if size(original_img, 3) == 1
        black_white_img = original_img;
    else
        black_white_img = rgb2gray(original_img);
    end
    galleryPoints = detectSURFFeatures(black_white_img, 'MetricThreshold', 100.0);
    [features, points] = extractFeatures(black_white_img, galleryPoints);
    gallery_features{i} = features;
end 

for r =1:length(ranks)
    matches_final = zeros(length(probe_names{1,1}), ranks(r));
    for i = 1:length(probe_names{1,1})
        probe_img = probe_features{1, i};
        scores = zeros(1, ranks(r));
        imgs = zeros(1, ranks(r));
        for j = 1:length(gallery_names{1,1})
            if i == j
                continue
            end
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

resultsFile = fopen('SURF_neighbor_results_toy.txt', 'a+');

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
                if answer == 0 && rank == 30
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


