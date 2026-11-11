// Fashion Designers: Customer / Designer view, the search, and the actions on
// requests (message, accept, decline, complete).
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/rows.dart';
import 'package:banigoba/modules/designers/models/designer_summary.dart';
import 'package:banigoba/modules/notifications/services/notification_service.dart';
import 'package:banigoba/modules/provider/services/request_service.dart';
import 'package:banigoba/modules/shop/services/shop_chat_service.dart';
import 'package:banigoba/modules/shop/views/shop_chat_page.dart';

class FashionDesignersController extends GetxController {
  /// 0 = Customer, 1 = Designer.
  final RxInt view = 0.obs;

  /// 0 = Designers, 1 = My Requests.
  final RxInt customerTab = 0.obs;
  final RxString query = ''.obs;

  void setView(int value) => view.value = value;

  void setCustomerTab(int index) => customerTab.value = index;

  void onSearchChanged(String value) =>
      query.value = value.trim().toLowerCase();

  bool matchesQuery(DesignerSummary designer) {
    final text = query.value;
    if (text.isEmpty) return true;
    final haystack = [
      designer.name,
      designer.location,
      designer.bio,
      designer.priceRange,
      ...designer.specialties,
    ].join(' ').toLowerCase();
    return haystack.contains(text);
  }

  int compareRequestsNewestFirst(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) => _createdAt(b).compareTo(_createdAt(a));

  DateTime _createdAt(Map<String, dynamic> data) =>
      asDateTime(data['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Accepted';
      case 'declined':
        return 'Declined';
      case 'completed':
        return 'Completed';
      default:
        return 'Updated';
    }
  }

  Future<void> updateRequestStatus(
    String requestId,
    String status,
    Map<String, dynamic> requestData,
  ) async {
    final currentStatus = (requestData['status'] ?? 'pending').toString();

    await const RequestService(RequestKind.design).setStatus(requestId, status);

    if (currentStatus == status) return;

    final customerId = (requestData['customerId'] ?? '').toString();
    if (customerId.isEmpty) return;

    final designerId = (requestData['designerId'] ?? '').toString();
    final designerName = (requestData['designerName'] ?? 'Designer').toString();
    final occasion = (requestData['occasion'] ?? 'custom design').toString();
    final statusLabel = _statusLabel(status).toLowerCase();

    await NotificationService().addNotification(
      receiverId: customerId,
      title: 'Design request $statusLabel',
      body: '$designerName $statusLabel your $occasion request.',
      type: 'designer_request_status',
      extraData: {
        'designerId': designerId,
        'designerName': designerName,
        'requestId': requestId,
        'requestStatus': status,
        'requestOccasion': occasion,
        'fromName': designerName,
      },
    );
  }

  Future<void> openConversation({
    required String designerId,
    required String designerName,
    required String customerId,
    required String customerName,
    required bool asDesigner,
    required String requestId,
    required Map<String, dynamic> requestData,
  }) async {
    if (designerId.isEmpty || customerId.isEmpty) return;
    final chatId = await ShopChatService().ensureDesignerConversation(
      designerId: designerId,
      customerId: customerId,
      designerName: designerName,
    );
    await ShopChatService().addDesignRequestReference(
      chatId: chatId,
      requestId: requestId,
      occasion: (requestData['occasion'] ?? 'Custom design').toString(),
      budget: (requestData['budget'] ?? '').toString(),
      deadline: (requestData['deadline'] ?? '').toString(),
      status: (requestData['status'] ?? '').toString(),
    );
    if (isClosed) return;
    await Get.to<void>(
      () => ShopChatPage(
        chatId: chatId,
        title: asDesigner ? customerName : designerName,
        asSeller: asDesigner,
      ),
    );
  }
}
