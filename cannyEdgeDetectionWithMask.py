import numpy as np
import cv2
from matplotlib import pyplot as plt

img = cv2.imread('7_original.jpg')
mask = np.zeros(img.shape[:2],np.uint8)

bgdModel = np.zeros((1,65),np.float64)
fgdModel = np.zeros((1,65),np.float64)

# newmask is the mask image I manually labelled
newmask = cv2.imread('7_map.jpg',0)
plt.imshow(newmask), plt.colorbar()
plt.show()

# wherever it is marked white (sure foreground), change mask=1
# wherever it is marked black (sure background), change mask=0

viewmask = np.zeros(img.shape[:2],np.uint8)

viewmask[newmask > 150] = 100
plt.imshow(viewmask)
plt.show()


viewmask2 = np.zeros(img.shape[:2],np.uint8)
viewmask2[newmask < 30] = 100
plt.imshow(viewmask2)
plt.show()


mask[newmask > 150] = 1
mask[newmask < 30] = 0


mask, bgdModel, fgdModel = cv2.grabCut(img,mask,None,bgdModel,fgdModel,1,cv2.GC_INIT_WITH_MASK)

mask = np.where((mask==2)|(mask==0),0,1).astype('uint8')
img = img*mask[:,:,np.newaxis]
plt.imshow(img)
plt.show()
