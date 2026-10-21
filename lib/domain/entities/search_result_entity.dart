class SearchResultEntity<T> {
  int currentPage;
  int totalItems;
  List<T> data;
  int itemsPerPage;
  int lastpage;

  SearchResultEntity({
    required this.currentPage,
    required this.totalItems,
    required this.data,
    required this.itemsPerPage,
    required this.lastpage,
  });

  factory SearchResultEntity.empty({
    int currentPage = 0,
    int itemsPerPage = 0,
  }) {
    return SearchResultEntity(
      currentPage: currentPage,
      totalItems: 0,
      data: [],
      itemsPerPage: itemsPerPage,
      lastpage: 0,
    );
  }

  bool get isEmpty => data.isEmpty;

  @override
  String toString() {
    return 'SearchResultEntity{currentPage: $currentPage, totalItems: $totalItems, data: $data, itemsPerPage: $itemsPerPage, lastpage: $lastpage}';
  }
}
