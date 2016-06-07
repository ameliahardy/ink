run('../../../../Downloads/vlfeat-0.9.20/toolbox/vl_setup'); %for one-time setup (run everytime)

fid = fopen('../../../../Desktop/tatt-c_ongoing/tattoo_identification/probesAll.txt');
probe_names = textscan(fid, '%s', 'delimiter', '\n');
fclose(fid);

fid = fopen('../../../../Desktop/tatt-c_ongoing/tattoo_identification/galleryAll.txt');
gallery_names = textscan(fid, '%s', 'delimiter', '\n');
fclose(fid);

% probe_names{1, 1}(1) to get first name of probe

probe_image_feats = zeros(size(probe_names{1,1}, 1), 256);
for i = 1:length(probe_names{1,1})
    image_file_name = fullfile('../../../../Desktop/tatt-c_ongoing/tattoo_identification/images', char(probe_names{1,1}(i)));
    original_img = imread(image_file_name);
    if size(original_img, 3) == 1
        black_white_img = original_img;
    else
        black_white_img = rgb2gray(original_img);
    end
    new_img = imresize(black_white_img(:, :), [16,16]);
    probe_image_feats(i, :) = new_img(:);
    probe_image_feats(i, :) = probe_image_feats(i, :) - mean(probe_image_feats(i, :));
    probe_image_feats(i, :) = probe_image_feats(i, :)./norm(probe_image_feats(i, :));
end

gallery_image_feats = zeros(size(gallery_names{1,1}, 1), 256);
for i = 1:length(gallery_names{1,1})
    image_file_name = fullfile('../../../../Desktop/tatt-c_ongoing/tattoo_identification/images', char(gallery_names{1,1}(i)));
    original_img = imread(image_file_name);
    if size(original_img, 3) == 1
        black_white_img = original_img;
    else
        black_white_img = rgb2gray(original_img);
    end
    new_img = imresize(black_white_img(:,:), [16,16]);
    gallery_image_feats(i, :) = new_img(:);
    gallery_image_feats(i, :) = gallery_image_feats(i, :) - mean(gallery_image_feats(i, :));
    gallery_image_feats(i, :) = gallery_image_feats(i, :)./norm(gallery_image_feats(i, :));
end

rank = 30

closest_neighbor = {};
for i = 1:size(probe_image_feats, 1)
    probe = probe_image_feats(i, :);
    distance = [];
    for j = 1:size(gallery_image_feats, 1)
        d = vl_alldist2(probe', gallery_image_feats(j,:)');
        distance = [distance;d];
    end
    for r = 1:rank
        [val, index] = min(distance);
        closest_neighbor{i, r} = gallery_names{1, 1}(index);
        distance(index) = Inf;
    end
end

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

average_recall = 0;
average_precision = 0;
% size of answer_arr is relevant docs
for i = 1:size(closest_neighbor, 1)
    answer_arr = ground_truth_map(char(probe_names{1,1}(i)));
    number_correct = 0;
    p = 0;
    for j = 1:rank
        x = strmatch(char(closest_neighbor{i, j}(1)), answer_arr);
        if ~isempty(x)
            number_correct = number_correct+1;
            p = p + number_correct/j;
        end
    end
    if number_correct == 0
        char(probe_names{1,1}(i))
        char(closest_neighbor{i, j}(1))
    end
    average_recall = average_recall + number_correct/size(answer_arr, 2);
    average_precision = average_precision + p/size(answer_arr, 2);
end
precision = average_precision/size(closest_neighbor, 1)
recall = average_recall/size(closest_neighbor, 1)