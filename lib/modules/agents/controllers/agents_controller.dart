// Agents: Hair / Clothes tab and the search.
import 'package:get/get.dart';

import 'package:banigoba/modules/agents/models/agent_summary.dart';

class AgentsController extends GetxController {
  /// 0 = Hair Agents, 1 = Clothes Agents.
  final RxInt tab = 0.obs;
  final RxString query = ''.obs;

  String get selectedAgentType => tab.value == 0 ? 'hair' : 'clothes';

  void setTab(int index) => tab.value = index;

  void onSearchChanged(String value) =>
      query.value = value.trim().toLowerCase();

  bool matchesQuery(AgentSummary agent) {
    final text = query.value;
    if (text.isEmpty) return true;
    final haystack = [
      agent.name,
      agent.location,
      agent.bio,
      agent.rate,
      ...agent.services,
    ].join(' ').toLowerCase();
    return haystack.contains(text);
  }
}
