% closest SIFT neighbor

run('../../../../Downloads/vlfeat-0.9.20/toolbox/vl_setup'); %for one-time setup (run everytime)

fid = fopen('../../../../Desktop/tatt-c_ongoing/tattoo_similarity/probesAll.txt');
probe_names = textscan(fid, '%s', 'delimiter', '\n');
fclose(fid);

fid = fopen('../../../../Desktop/tatt-c_ongoing/tattoo_similarity/galleryAll.txt');
gallery_names = textscan(fid, '%s', 'delimiter', '\n');
fclose(fid);

% probe_names{1, 1}(1) to get first name of probe

fid = fopen('../../../../Desktop/tatt-c_ongoing/tattoo_similarity/ground_truth.txt');
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

probe_sift_features = [];

probe_indiv_cell = {};

for i = 1:length(probe_names{1,1})
    image_file_name = fullfile('../../../../Desktop/tatt-c_ongoing/tattoo_similarity/images/cropped', char(probe_names{1,1}(i)));
    original_img = imread(image_file_name);
    black_white_img = rgb2gray(original_img);
    new_img = single(black_white_img);
    [frames, descriptors] = vl_dsift(new_img, 'fast', 'step', 9);
    probe_sift_features = [probe_sift_features double(descriptors)];
    probe_indiv_cell{i} = [double(descriptors)];
end

gallery_sift_features = [];

gallery_indiv_cell = {};

for i = 1:length(gallery_names{1,1})
    image_file_name = fullfile('../../../../Desktop/tatt-c_ongoing/tattoo_similarity/images/cropped', char(gallery_names{1,1}(i)));
    original_img = imread(image_file_name);
    black_white_img = rgb2gray(original_img);
    new_img = single(black_white_img);
    [frames, descriptors] = vl_dsift(new_img, 'fast', 'step', 9);
    gallery_sift_features = [gallery_sift_features double(descriptors)];
    gallery_indiv_cell{i} = [double(descriptors)];
end

num_centers = 70;

fileID = fopen('results.txt', 'a+');

% forming centers from both probe and gallery...ideally we would have a
% huge set to train this on

[centers, assignments] = vl_kmeans([probe_sift_features gallery_sift_features], num_centers);

% calculate topic vector for gallery images

gallery_topic_vectors = zeros(length(gallery_names{1,1}), num_centers);

for i = 1:size(gallery_indiv_cell, 2)
    sift_features = gallery_indiv_cell{1, i};
    center_assign = [];
    for j = 1:size(sift_features, 2)
        dist = vl_alldist2(centers, sift_features(:, j));
        [val, index] = min(dist);
        center_assign = [center_assign index];
    end
    % counts is our topic vector representation
    [counts, edges] = histc(center_assign, 1:num_centers);
    gallery_topic_vectors(i, :) = counts;
end

probe_topic_vectors = zeros(length(probe_names{1,1}), num_centers);

for i = 1:size(probe_indiv_cell, 2)
    sift_features = probe_indiv_cell{1, i};
    center_assign = [];
    for j = 1:size(sift_features, 2)
        dist = vl_alldist2(centers, sift_features(:, j));
        [val, index] = min(dist);
        center_assign = [center_assign index];
    end
    [counts, edges] = histc(center_assign, 1:num_centers);
    probe_topic_vectors(i, :) = counts;
end

all_ranks = [1, 5, 10, 20, 30];
highest_rank = 30;

% match each probe topic vector to its closest gallery topic vector

matches = zeros(length(probe_names{1,1}), highest_rank);
match_values = Inf(length(probe_names{1,1}), highest_rank);

for i = 1:length(probe_names{1,1})
    probe_v = probe_topic_vectors(i, :)';
    match_val_vector = match_values(i, :);
    match_vector = matches(i, :);
    for j = 1:length(gallery_names{1,1})
        gallery_v = gallery_topic_vectors(j, :)';
        euclidean_dist = vl_alldist2(probe_v, gallery_v);
        [val, ind] = max(match_val_vector);
        if val > euclidean_dist
            match_val_vector(1,ind) = euclidean_dist;
            match_vector(1,ind) = j;
        end
    end
    matches(i, :) = match_vector;
end

for m = 1:length(all_ranks)
    rank = all_ranks(m);
    average_recall = 0;
    average_precision = 0;
    for i = 1:size(matches, 1)
        number_correct = 0;
        p = 0;
        for r = 1:rank
            match_index = matches(i, r);
            answer_arr = ground_truth_map(char(probe_names{1, 1}(i)));
            x = strmatch(char(gallery_names{1,1}(match_index)), answer_arr);
            if ~isempty(x)
                number_correct = number_correct+1;
                p = p + number_correct/r;
            end
        end
        if number_correct == 0
            char(probe_names{1, 1}(i))
            char(gallery_names{1,1}(matches(i, 1)))
            answer_arr
        end
        average_recall = average_recall + number_correct/size(answer_arr, 2);
        average_precision = average_precision + p/size(answer_arr, 2);
    end
    precision = average_precision/size(matches, 1);
    recall = average_recall/size(matches, 1);
    fprintf(fileID, 'rank: %d, centers: %d precision: %0.5f, recall: %0.5f\n', rank, num_centers, precision, recall);
end
fclose(fileID);






