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
  final _scrollController = ScrollController();
  final List<_Message> _messages = [
    const _Message(
      fromUser: false,
      text: 'Ask me about profit, restock, top/least selling, and stock alerts.',
    ),
  ];
  bool _busy = false;

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _ask([String? value]) async {
    final query = (value ?? _controller.text).trim();
    if (query.isEmpty) return;
    if (_busy) return;
    setState(() {
      _busy = true;
      _messages.add(_Message(fromUser: true, text: query));
      _controller.clear();
    });
    _scrollToLatest();

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
    _scrollToLatest();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: FeatureHeaderCard(
              title: 'AI Assistant',
              subtitle: 'Ask inventory, profit, and restock questions in natural language.',
              icon: Icons.smart_toy_outlined,
              trailingIcon: Icons.bolt_outlined,
            ),
          ),
          if (!_api.isConfigured)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.key_off_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'API key missing. Running local AI fallback mode.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            height: 58,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              scrollDirection: Axis.horizontal,
              children: [
                _QuickQuestion(
                  icon: Icons.warning_amber_rounded,
                  label: 'Which products are low stock?',
                  onTap: () => _ask('Which products are low stock?'),
                ),
                _QuickQuestion(
                  icon: Icons.inventory_outlined,
                  label: 'What should I restock?',
                  onTap: () => _ask('What should I restock?'),
                ),
                _QuickQuestion(
                  icon: Icons.monetization_on_outlined,
                  label: 'Which product is most profitable?',
                  onTap: () => _ask('Which product is most profitable?'),
                ),
                _QuickQuestion(
                  icon: Icons.local_fire_department_outlined,
                  label: 'What sold the most today?',
                  onTap: () => _ask('What sold the most today?'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.length <= 1
                ? EmptyStateWidget(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Ask inventory AI',
                    subtitle:
                        'Try quick prompts above for restock, profit, and sales insights.',
                  )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_busy ? 1 : 0),
              itemBuilder: (context, i) {
                if (_busy && i == _messages.length) {
                  return const _TypingBubble();
                }
                final m = _messages[i];
                final cs = Theme.of(context).colorScheme;
                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 180),
                  tween: Tween(begin: 0, end: 1),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, (1 - value) * 8),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Align(
                    alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!m.fromUser)
                            Padding(
                              padding: const EdgeInsets.only(right: 8, bottom: 4),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: cs.secondaryContainer,
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 16,
                                  color: cs.onSecondaryContainer,
                                ),
                              ),
                            ),
                          Flexible(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: m.fromUser
                                    ? cs.primaryContainer
                                    : cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(m.fromUser ? 16 : 4),
                                  bottomRight: Radius.circular(m.fromUser ? 4 : 16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  m.text,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: m.fromUser
                                            ? cs.onPrimaryContainer
                                            : cs.onSurface,
                                        height: 1.35,
                                      ),
                                ),
                              ),
                            ),
                          ),
                          if (m.fromUser)
                            Padding(
                              padding: const EdgeInsets.only(left: 8, bottom: 4),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: cs.primaryContainer,
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
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
  const _QuickQuestion({
    required this.label,
    required this.onTap,
    required this.icon,
  });
  final String label;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
        onPressed: onTap,
      ),
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

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 220),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 4),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: cs.secondaryContainer,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: cs.onSecondaryContainer,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: _TypingDots(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        double alphaFor(int index) {
          final phase = (t + (index * 0.18)) % 1.0;
          return 0.35 + (phase < 0.5 ? phase : 1 - phase) * 1.3;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Padding(
              padding: EdgeInsets.only(right: i == 2 ? 0 : 5),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: alphaFor(i).clamp(0.25, 1)),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
