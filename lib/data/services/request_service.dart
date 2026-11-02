// Custom design requests (customer to designer) and hair requests (customer
// to salon). Both are the same shape: a customer, a provider, a status, and
// the details the customer filled in. Screens read them as maps with an
// `id`, camelCase fields, and `createdAt` as an ISO string.
import '../../core/supabase/supabase_config.dart';
import '../supabase/rows.dart';

enum RequestKind {
  design('design_requests', 'designer_id', 'designerId'),
  hair('agent_requests', 'agent_id', 'agentId');

  const RequestKind(this.table, this.providerColumn, this.providerField);

  final String table;
  final String providerColumn;
  final String providerField;
}

class RequestService {
  const RequestService(this.kind);

  final RequestKind kind;

  /// A request row as the screens read it.
  Map<String, dynamic> read(Map<String, dynamic> row) => flattenRow(row);

  Stream<List<Map<String, dynamic>>> _watch(String column, String userId) {
    return supabase
        .from(kind.table)
        .stream(primaryKey: ['id'])
        .eq(column, userId)
        .map((rows) => [for (final row in rows) read(row)]);
  }

  /// Requests the customer sent.
  Stream<List<Map<String, dynamic>>> watchForCustomer(String customerId) =>
      _watch('customer_id', customerId);

  /// Requests addressed to the provider.
  Stream<List<Map<String, dynamic>>> watchForProvider(String providerId) =>
      _watch(kind.providerColumn, providerId);

  /// Sends a request; [details] are the form fields (camelCase).
  Future<String> create({
    required String customerId,
    required String providerId,
    required Map<String, dynamic> details,
  }) async {
    final row = await supabase
        .from(kind.table)
        .insert({
          'customer_id': customerId,
          kind.providerColumn: providerId,
          'status': 'pending',
          'data': details,
        })
        .select('id')
        .single();
    return row['id'].toString();
  }

  Future<void> setStatus(String requestId, String status) async {
    await supabase
        .from(kind.table)
        .update({'status': status})
        .eq('id', requestId);
  }
}
