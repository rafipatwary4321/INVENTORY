import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/products_provider.dart';
import '../../providers/sales_provider.dart';
import '../../services/ai/ai_assistant_service.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final _controller = TextEditingController();
  final _service = const AIAssistantService();
  final List<_Message> _messages = [
    const _Message(
      fromUser: false,
      text: 'Ask me about profit, restock, top/least selling, and stock alerts.',
    ),
  ];

  void _ask([String? value]) {
    final query = (value ?? _controller.text).trim();
    if (query.isEmpty) return;
    final products = context.read<ProductsProvider>().products;
    final items = context.read<SalesProvider>().saleItems;
    final reply = _service.respond(query: query, products: products, saleItems: items);
    setState(() {
      _messages.add(_Message(fromUser: true, text: query));
      _messages.add(_Message(fromUser: false, text: reply));
      _controller.clear();
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
      appBar: AppBar(title: const Text('AI Assistant')),
      body: Column(
        children: [
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
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _ask,
                      decoration: const InputDecoration(
                        hintText: 'Ask inventory intelligence...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _ask,
                    icon: const Icon(Icons.send),
                    label: const Text('Ask'),
                  ),
                ],
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
