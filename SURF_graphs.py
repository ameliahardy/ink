from matplotlib import pyplot as plt

recall = [69.71, 85.16, 88.34, 90.89, 93.23]
precision = [69.71, 83.27, 83.68, 83.88, 84.01]

rank = [1, 5, 10, 20, 30]

plt.plot(rank, recall, label='Average recall')
plt.plot(rank, precision, label='Average precision')
plt.legend(loc=3)
plt.xlabel('Rank')
plt.ylabel('Percent')
plt.show()
