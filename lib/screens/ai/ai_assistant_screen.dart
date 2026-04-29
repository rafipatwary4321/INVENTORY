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
  final _inputFocus = FocusNode();
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
    _inputFocus.dispose();
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF050C18), Color(0xFF0A1C35), Color(0xFF0F2F57)],
          ),
        ),
        child: Column(
          children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: _AiHeaderCard(
              subtitle: _api.isConfigured ? 'Connected to AI API' : 'Fallback AI mode',
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: AnimatedFeatureHero(
              title: 'AI + Inventory Brain',
              subtitle: 'Assistant intelligence over boxes, stock, and demand.',
              icon: Icons.smart_toy_rounded,
              gradientColors: [Color(0xFF7A37FF), Color(0xFF13A7FF), Color(0xFF1DE2B0)],
              animationType: FeatureHeroAnimationType.ai,
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
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: _AiInsightMiniCard(
                    title: 'Demand Pulse',
                    subtitle: 'Analyzing movement',
                    icon: Icons.graphic_eq_rounded,
                    glow: Color(0xFF13A7FF),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _AiInsightMiniCard(
                    title: 'Restock AI',
                    subtitle: 'Priority suggestions',
                    icon: Icons.auto_awesome_rounded,
                    glow: Color(0xFF7C3BFF),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: _messages.length <= 1
                  ? const EmptyStateVisual(
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
                        return TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 210),
                          tween: Tween(begin: 0, end: 1),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, (1 - value) * 10),
                              child: Opacity(opacity: value, child: child),
                            );
                          },
                          child: _MessageBubble(message: m),
                        );
                      },
                    ),
            ),
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: (_inputFocus.hasFocus
                            ? const Color(0xFF13A7FF)
                            : Colors.white.withValues(alpha: 0.2))
                        .withValues(alpha: _inputFocus.hasFocus ? 0.65 : 0.2),
                  ),
                  boxShadow: _inputFocus.hasFocus
                      ? [
                          BoxShadow(
                            color: const Color(0xFF13A7FF).withValues(alpha: 0.32),
                            blurRadius: 16,
                          ),
                        ]
                      : null,
                ),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final narrow = c.maxWidth < 400;
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            focusNode: _inputFocus,
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
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFF13A7FF),
                                ),
                                onPressed: _busy ? null : () => _ask(),
                                tooltip: 'Ask',
                                icon: const Icon(Icons.send_rounded),
                              )
                            : GlowButton(
                                onPressed: _busy ? null : _ask,
                                icon: Icons.send_rounded,
                                label: 'Ask',
                              ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          ],
        ),
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
        backgroundColor: const Color(0xFF0D1B33),
        side: BorderSide(color: const Color(0xFF13A7FF).withValues(alpha: 0.55)),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}

class _AiInsightMiniCard extends StatelessWidget {
  const _AiInsightMiniCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.glow,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: glow.withValues(alpha: 0.14),
        border: Border.all(color: glow.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
        ],
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
                color: const Color(0xFF0C1A30),
                border: Border.all(color: const Color(0xFF13A7FF).withValues(alpha: 0.35)),
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

class _AiHeaderCard extends StatelessWidget {
  const _AiHeaderCard({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B38FF), Color(0xFF1288FF), Color(0xFF14D2B2)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1288FF).withValues(alpha: 0.35),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _Message message;

  @override
  Widget build(BuildContext context) {
    final fromUser = message.fromUser;
    final alignment = fromUser ? Alignment.centerRight : Alignment.centerLeft;
    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!fromUser)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 4),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF13A7FF).withValues(alpha: 0.2),
                    border: Border.all(color: const Color(0xFF13A7FF).withValues(alpha: 0.45)),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
                ),
              ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(22),
                    topRight: const Radius.circular(22),
                    bottomLeft: Radius.circular(fromUser ? 22 : 8),
                    bottomRight: Radius.circular(fromUser ? 8 : 22),
                  ),
                  gradient: fromUser
                      ? const LinearGradient(
                          colors: [Color(0xFF6B38FF), Color(0xFF1288FF)],
                        )
                      : null,
                  color: fromUser ? null : const Color(0xFF0D1A31),
                  border: Border.all(
                    color: fromUser
                        ? Colors.transparent
                        : const Color(0xFF13A7FF).withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (fromUser ? const Color(0xFF6B38FF) : const Color(0xFF13A7FF))
                          .withValues(alpha: 0.28),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.96),
                        height: 1.35,
                      ),
                ),
              ),
            ),
            if (fromUser)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: const Icon(Icons.person_rounded, size: 16, color: Colors.white),
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
