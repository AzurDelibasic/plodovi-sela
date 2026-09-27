import 'package:equatable/equatable.dart';

class City extends Equatable {
  const City({required this.id, required this.name});

  final int id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
