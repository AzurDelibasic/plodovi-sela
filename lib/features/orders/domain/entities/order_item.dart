import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  const OrderItem({
    required this.title,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  final String title;
  final double unitPrice;
  final double quantity;
  final double subtotal;

  @override
  List<Object?> get props => [title, unitPrice, quantity, subtotal];
}
