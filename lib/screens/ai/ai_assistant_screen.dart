import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/premium/premium_ui.dart';
import '../../providers/products_provider.dart';
import '../../providers/sales_provider.dart';
import '../../services/ai/ai_api_service.dart';
import '../../services/ai/ai_assistant_service.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final _controller = TextEditingController();
  final _service = const AIAssistantService();
  final _api = AIApiService();
  final List<_Message> _messages = [
    const _Message(
      fromUser: false,
      text: 'Ask me about profit, restock, top/least selling, and stock alerts.',
    ),
  ];
  bool _busy = false;

  Future<void> _ask([String? value]) async {
    final query = (value ?? _controller.text).trim();
    if (query.isEmpty) return;
    if (_busy) return;
    setState(() {
      _busy = true;
      _messages.add(_Message(fromUser: true, text: query));
      _controller.clear();
    });

    final products = context.read<ProductsProvider>().products;
    final items = context.read<SalesProvider>().saleItems;
    String reply;
    try {
      if (_api.isConfigured) {
        reply = await _api.askAssistant(
          query: query,
          products: products,
          saleItems: items,
        );
      } else {
        reply = _service.respond(
          query: query,
          products: products,
          saleItems: items,
        );
      }
    } catch (_) {
      // Hard fallback to local assistant if real API fails.
      reply = _service.respond(
        query: query,
        products: products,
        saleItems: items,
      );
      reply =
          '$reply\n\n(Fallback: real AI API unavailable, showing local AI response.)';
    }
    if (!mounted) return;
    setState(() {
      _messages.add(_Message(fromUser: false, text: reply));
      _busy = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PremiumAppBar(
        title: 'AI Assistant',
        subtitle: _api.isConfigured
            ? 'Provider: Real AI API'
            : 'Provider: Local fallback AI',
      ),
      body: Column(
        children: [
          if (!_api.isConfigured)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Real AI key not configured. Using local assistant fallback.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          SizedBox(
            height: 52,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              children: [
                _QuickQuestion(
                  label: 'Which product is most profitable?',
                  onTap: () => _ask('Which product is most profitable?'),
                ),
                _QuickQuestion(
                  label: 'What should I restock?',
                  onTap: () => _ask('What should I restock?'),
                ),
                _QuickQuestion(
                  label: 'Top selling product?',
                  onTap: () => _ask('Top selling product?'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return Align(
                  alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    constraints: const BoxConstraints(maxWidth: 460),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: m.fromUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.text),
                  ),
                );
              },
            ),
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: LayoutBuilder(
                builder: (context, c) {
                  final narrow = c.maxWidth < 400;
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: _busy ? null : _ask,
                          decoration: const InputDecoration(
                            hintText: 'Ask inventory intelligence...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      narrow
                          ? IconButton.filled(
                              onPressed: _busy ? null : () => _ask(),
                              tooltip: 'Ask',
                              icon: const Icon(Icons.send_rounded),
                            )
                          : FilledButton.icon(
                              onPressed: _busy ? null : _ask,
                              icon: const Icon(Icons.send_rounded),
                              label: const Text('Ask'),
                            ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickQuestion extends StatelessWidget {
  const _QuickQuestion({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(label: Text(label), onPressed: onTap),
    );
  }
}

class _Message {
  const _Message({
    required this.fromUser,
    required this.text,
  });
  final bool fromUser;
  final String text;
}
