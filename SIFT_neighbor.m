% closest SIFT neighbor

run('../../../../Downloads/vlfeat-0.9.20/toolbox/vl_setup'); %for one-time setup (run everytime)

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

all_g_descriptors = {};
for j = 1:length(gallery_names{1,1})
    image_file_name = fullfile('../../../../Desktop/tatt-c_ongoing/tattoo_identification/images/', char(gallery_names{1,1}(j)));
    original_img = imread(image_file_name);
    if size(original_img, 3) == 1
        black_white_img = original_img;
    else
        black_white_img = rgb2gray(original_img);
    end
    new_img = single(black_white_img);
    [g_frames, g_descriptors] = vl_dsift(new_img, 'fast', 'step', 9);
    all_g_descriptors{j} = [double(g_descriptors)];
end
save('g_descriptors.mat', 'all_g_descriptors')

all_p_descriptors = {};
for j = 1:length(probe_names{1,1})
    image_file_name = fullfile('../../../../Desktop/tatt-c_ongoing/tattoo_identification/images/', char(probe_names{1,1}(j)));
    original_img = imread(image_file_name);
    if size(original_img, 3) == 1
        black_white_img = original_img;
    else
        black_white_img = rgb2gray(original_img);
    end
    new_img = single(black_white_img);
    [p_frames, p_descriptors] = vl_dsift(new_img, 'fast', 'step', 9);
    all_p_descriptors{j} = [double(p_descriptors)];
end
save('p_descriptors.mat', 'all_p_descriptors')

%load('g_descriptors.mat')
%load('p_descriptors.mat')

for r =1:length(ranks)
    matches_final = zeros(length(probe_names{1,1}), ranks(r));
    for i = 1:length(probe_names{1,1})
        image_file_name = fullfile('../../../../Desktop/tatt-c_ongoing/tattoo_identification/images/', char(probe_names{1,1}(i)));
        original_img = imread(image_file_name);
        p_descriptors = uint8(squeeze(all_p_descriptors{1,i}));
        %min_scores = Inf(1, ranks(r));
        num_matches = zeros(1, ranks(r));
        min_imgs = zeros(1, ranks(r));
        for j = 1:size(all_g_descriptors, 1)
            [matches, scores] = vl_ubcmatch(p_descriptors, uint8(squeeze(all_g_descriptors{1,j})));
            %[s, index] = max(min_scores);
            [s, index] = min(num_matches);
            %{
            if sum(scores)/size(matches, 2) < min_scores(1, index)
                min_scores(1, index) = sum(scores)/size(matches, 2);
                min_imgs(1, index) = j;
            end
            %}
            if size(matches, 2) > num_matches(1, index)
               num_matches(1, index) = size(matches, 2);
               min_imgs(1, index) = j;
            end
        end
        %[sorted_scores, indices] = sort(min_scores(1, :));
        [sorted_matches, indices] = sort(num_matches(1, :), 'descend');
        for k = 1:length(indices)
            matches_final(i, k) = min_imgs(1, indices(k));
        end
    end
end

all_ranks = [1, 5, 10, 20, 30];
for m = 1:length(all_ranks)
    rank = all_ranks(m);
    average_recall = 0;
    average_precision = 0;
    for i = 1:size(matches_final, 1)
        number_correct = 0;
        p = 0;
        for r = 1:rank
            match_index = matches_final(i, r);
            if match_index == 0
                continue;
            end
            answer_arr = ground_truth_map(char(probe_names{1, 1}(i)));
            x = strmatch(char(gallery_names{1,1}(match_index)), answer_arr);
            if ~isempty(x)
                number_correct = number_correct+1;
                p = p + number_correct/r;
            end
        end
        average_recall = average_recall + number_correct/size(answer_arr, 2);
        average_precision = average_precision + p/size(answer_arr, 2);
    end
    rank
    precision = average_precision/size(matches_final, 1)
    recall = average_recall/size(matches_final, 1)
end


