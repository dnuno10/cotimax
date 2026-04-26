import 'package:supabase_flutter/supabase_flutter.dart';

class DeleteDependency {
  const DeleteDependency({
    required this.key,
    required this.label,
    required this.count,
  });

  final String key;
  final String label;
  final int count;
}

Future<List<DeleteDependency>> fetchDeleteDependencies({
  required String entityType,
  required Iterable<String> ids,
  SupabaseClient? client,
}) async {
  final normalizedIds = ids
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toList();
  if (normalizedIds.isEmpty) {
    return const <DeleteDependency>[];
  }

  final response = await (client ?? Supabase.instance.client).rpc(
    'list_delete_dependencies',
    params: {'p_entity_type': entityType, 'p_ids': normalizedIds},
  );

  final rows = (response as List<dynamic>? ?? const <dynamic>[])
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList(growable: false);

  return rows
      .map(
        (row) => DeleteDependency(
          key: (row['dependency_key'] ?? '').toString(),
          label: (row['dependency_label'] ?? '').toString(),
          count: (row['dependency_count'] as num?)?.toInt() ?? 0,
        ),
      )
      .where((item) => item.count > 0 && item.label.isNotEmpty)
      .toList(growable: false);
}

String buildDeleteDependencyMessage(List<DeleteDependency> dependencies) {
  if (dependencies.isEmpty) {
    return '';
  }

  final lines = dependencies
      .map((item) => '- ${item.count} ${item.label}')
      .join('\n');
  return [
    'Esta accion tambien quitara la referencia en:',
    lines,
    '',
    'Los registros relacionados no se eliminaran.',
  ].join('\n');
}
