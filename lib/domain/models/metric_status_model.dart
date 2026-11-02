enum MetricSyncStatus {
  available,
  permissionRequired,
  noDataFound,
  unsupported,
}

enum MetricDataQuality { measured, estimated, userEntered, unavailable }

class MetricStatus {
  final String key;
  final String title;
  final String description;
  final MetricSyncStatus status;
  final String? lastValue;
  final DateTime? lastSyncedAt;
  final String explanation;
  final String expectedSource;

  const MetricStatus({
    required this.key,
    required this.title,
    required this.description,
    required this.status,
    this.lastValue,
    this.lastSyncedAt,
    required this.explanation,
    this.expectedSource = 'Android Health Connect',
  });

  String get statusLabel {
    switch (status) {
      case MetricSyncStatus.available:
        return 'Available';
      case MetricSyncStatus.permissionRequired:
        return 'Permission Required';
      case MetricSyncStatus.noDataFound:
        return 'No Data Found';
      case MetricSyncStatus.unsupported:
        return 'Unavailable';
    }
  }
}
