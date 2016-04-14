gbvs_install
img = imread('samplepics/8_grabcut.jpg');
map = gbvs(img);

% map_itti = ittikochmap(img); % map_itti.master_map contains the actual saliency map 

show_imgnmap( img , map );