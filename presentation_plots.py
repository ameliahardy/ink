from matplotlib import pyplot as plt

clusters_70 = [0.02972, 0.15234, 0.2638, 0.37972, 0.49777, 0.6655]

rank = [1, 5, 10, 15, 20, 30]

plt.plot(rank, clusters_70)
plt.title('Rank vs. Average Recall with 70 Clusters')
plt.xlabel('Rank')
plt.ylabel('Average Recall')
plt.show()

num_clusters = [50, 60, 65, 70, 75, 90, 100]
rank_20_all = [0.46911, 0.44469, 0.45849, 0.49777, 0.43089, 0.4569, 0.42399]

plt.plot(num_clusters, rank_20_all)
plt.title('Number of Clusters vs. Precision for Rank 20')
plt.xlabel('Number of Clusters')
plt.ylabel('Precision')
plt.show()