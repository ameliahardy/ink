clear all;
run('vlfeat-0.9.20/toolbox/vl_setup'); %for one-time setup (run everytime)

im = imread('7_original.jpg');

regionSize = 150 ;
regularizer = 10 ;
segments = vl_slic(single(im), regionSize, regularizer) ;

perim = true(size(im,1), size(im,2));
for k = 1 : max(segments(:))
    regionK = segments == k;
    perimK = bwperim(regionK, 8);
    perim(perimK) = false;
end

perim = uint8(cat(3,perim,perim,perim));

finalImage = im .* perim;
imshow(finalImage);