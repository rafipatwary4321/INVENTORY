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
  final _assistant = const AIAssistantService();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: 'Ask me about low stock, top sold items, profit, or restock advice.',
      fromUser: false,
    ),
  ];

  void _send([String? value]) {
    final text = (value ?? _controller.text).trim();
    if (text.isEmpty) return;
    final products = context.read<ProductsProvider>().products;
    final saleItems = context.read<SalesProvider>().saleItems;
    final reply = _assistant.reply(
      question: text,
      products: products,
      saleItems: saleItems,
    );
    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _messages.add(_ChatMessage(text: reply, fromUser: false));
    });
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Inventory Assistant')),
      body: Column(
        children: [
          SizedBox(
            height: 54,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _QuestionChip(
                  label: 'Which products are low stock?',
                  onTap: () => _send('Which products are low stock?'),
                ),
                _QuestionChip(
                  label: 'What sold the most today?',
                  onTap: () => _send('What sold the most today?'),
                ),
                _QuestionChip(
                  label: 'How much profit did I make?',
                  onTap: () => _send('How much profit did I make?'),
                ),
                _QuestionChip(
                  label: 'Which product should I restock?',
                  onTap: () => _send('Which product should I restock?'),
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
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 460),
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
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: const InputDecoration(
                        hintText: 'Ask inventory AI assistant...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
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

class _QuestionChip extends StatelessWidget {
  const _QuestionChip({required this.label, required this.onTap});
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

class _ChatMessage {
  const _ChatMessage({required this.text, required this.fromUser});
  final String text;
  final bool fromUser;
}
