/// Mirrors the `status` check constraint on `public.orders`.
enum OrderStatus {
  pending,
  confirmed,
  ready,
  completed,
  cancelled;

  static OrderStatus fromDb(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => OrderStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Na čekanju';
      case OrderStatus.confirmed:
        return 'Potvrđeno';
      case OrderStatus.ready:
        return 'Spremno';
      case OrderStatus.completed:
        return 'Završeno';
      case OrderStatus.cancelled:
        return 'Otkazano';
    }
  }
}
