import 'package:equatable/equatable.dart';

/// One photo in a seller's own gallery management view — carries the row
/// id (needed to delete it) alongside its public URL.
class FarmImage extends Equatable {
  const FarmImage({required this.id, required this.url});

  final String id;
  final String url;

  @override
  List<Object?> get props => [id, url];
}
