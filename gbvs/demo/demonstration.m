
% This file is a demonstration of how to call gbvs()

% make some parameters
params = makeGBVSParams;

% could change params like this
params.contrastwidth = .11;

% example of itti/koch saliency map call
%params.useIttiKochInsteadOfGBVS = 1;
%outitti = gbvs('samplepics/1.jpg',params);
%figure;
%subplot(1,2,1);
%imshow(imread('samplepics/1.jpg'));
%title('image');
%subplot(1,2,2);
%imshow(outitti.master_map_resized);
%title('Itti, Koch Saliency Map');
%fprintf(1,'Now waiting for user to press enter...\n');
%pause;

% example of calling gbvs() with default params and then displaying result
outW = 200;
out = {};
% compute saliency maps for some images
for i = 2
  
  img = imread(sprintf('samplepics/%d.jpg',i));

  tic; 

    % this is how you call gbvs
    % leaving out params reset them to all default values (from
    % algsrc/makeGBVSParams.m)
    out{i} = gbvs( img );   
  
  toc;

  % show result in a pretty way  
  
  sz = size(img); sz = sz(1:2);

  img = imresize( img , sz , 'bicubic' );  
  saliency_map = imresize( out{i}.master_map , sz , 'bicubic' );
  if ( max(img(:)) > 2 ) img = double(img) / 255; end
  img_thresholded = img .* repmat( saliency_map >= prctile(saliency_map(:),60) , [ 1 1 size(img,3) ] );  
  
  %figure;
  %subplot(2,2,1);
  %imshow(img);
  imwrite(img,sprintf('%d_original.jpg',i));
  title('original image');
    
  %subplot(2,2,2);
  %imshow(saliency_map);
  imwrite(saliency_map,sprintf('%d_map.jpg',i));
  title('GBVS map');
  
  %subplot(2,2,3);
  %imshow(img_thresholded);
  imwrite(img_thresholded,sprintf('%d_cropped.jpg',i));
  title('most salient (75%ile) parts');
  
  %subplot(2,2,4);
  imgnmap = show_imgnmap(img,out{i});
  imwrite(imgnmap,sprintf('%d_overlay.jpg',i));
  title('saliency map overlayed');
  
  if ( i < 5 )
    fprintf(1,'Now waiting for user to press enter...\n');

    %pause;
  end

end
