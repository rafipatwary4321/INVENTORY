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

  @override
  void initState() {
    super.initState();
    _inputFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

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
    final hasOnlyWelcomeMessage = _messages.length <= 1;
    return Scaffold(
      appBar: NeonAppBar(
        title: 'AI Assistant',
        subtitle: 'Smart inventory companion',
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0F1A), Color(0xFF101B32), Color(0xFF162643)],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _AiHeaderCard(
                subtitle: _api.isConfigured ? 'Connected to AI API' : 'Running local fallback AI',
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: _AiHeroCard(),
            ),
            if (!_api.isConfigured)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: NeonGlassCard(
                  radius: 20,
                  borderColor: const Color(0x66F97316),
                  child: Row(
                    children: [
                      const Icon(Icons.key_off_rounded, color: Color(0xFFF97316)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'API key missing. Running local AI fallback mode.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                children: [
                  _QuickQuestion(label: 'Low Stock', onTap: () => _ask('Low stock products?')),
                  _QuickQuestion(label: 'Profit', onTap: () => _ask('Most profitable product?')),
                  _QuickQuestion(label: 'Today Sales', onTap: () => _ask('Today sales koto?')),
                  _QuickQuestion(label: 'Restock', onTap: () => _ask('What should I restock?')),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: _InsightCardsRow(),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(color: const Color(0x5522D3EE)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x3322D3EE),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: hasOnlyWelcomeMessage
                    ? _AiWelcomeEmptyState(onAsk: _ask)
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
                            duration: const Duration(milliseconds: 220),
                            tween: Tween(begin: 0, end: 1),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, (1 - value) * 12),
                                child: Opacity(opacity: value, child: child),
                              );
                            },
                            child: _MessageBubble(message: m),
                          );
                        },
                      ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: const Color(0x66111B2E),
                    border: Border.all(
                      color: (_inputFocus.hasFocus
                              ? const Color(0xFF22D3EE)
                              : Colors.white.withValues(alpha: 0.2))
                          .withValues(alpha: _inputFocus.hasFocus ? 0.72 : 0.22),
                    ),
                    boxShadow: [
                      if (_inputFocus.hasFocus)
                        BoxShadow(
                          color: const Color(0x5522D3EE),
                          blurRadius: 20,
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          focusNode: _inputFocus,
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: _busy ? null : _ask,
                          decoration: const InputDecoration(
                            hintText: 'Ask anything...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _busy ? null : () {},
                        tooltip: 'Voice (coming soon)',
                        icon: const Icon(Icons.mic_none_rounded),
                      ),
                      const SizedBox(width: 6),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFA855F7), Color(0xFF3B82F6), Color(0xFF22D3EE)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x663B82F6),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _busy ? null : () => _ask(),
                          tooltip: 'Send',
                          icon: const Icon(Icons.send_rounded, color: Colors.white),
                        ),
                      ),
                    ],
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
  });
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: const Color(0x55111B2E),
        side: BorderSide(color: const Color(0x6622D3EE)),
        label: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
        onPressed: onTap,
      ),
    );
  }
}

class _InsightCardsRow extends StatelessWidget {
  const _InsightCardsRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _InsightCard(
            icon: Icons.warning_amber_rounded,
            title: 'Restock Milk',
            subtitle: 'Low stock alert',
            glow: Color(0xFFF97316),
          ),
          SizedBox(width: 10),
          _InsightCard(
            icon: Icons.trending_up_rounded,
            title: 'Sales +20%',
            subtitle: 'Compared to yesterday',
            glow: Color(0xFF22D3EE),
          ),
          SizedBox(width: 10),
          _InsightCard(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Discount Suggestion',
            subtitle: 'Try slow-product offer',
            glow: Color(0xFFA855F7),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.glow,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return NeonGlassCard(
      radius: 22,
      borderColor: glow.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
            ),
          ],
        ),
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

class _AiHeroCard extends StatelessWidget {
  const _AiHeroCard();

  @override
  Widget build(BuildContext context) {
    return NeonGlassCard(
      radius: 30,
      padding: const EdgeInsets.all(16),
      borderColor: const Color(0x6622D3EE),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Intelligent Inventory AI',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask about sales, stock, profit, and restock suggestions.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFA855F7), Color(0xFF3B82F6), Color(0xFF22D3EE)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x883B82F6),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiWelcomeEmptyState extends StatelessWidget {
  const _AiWelcomeEmptyState({required this.onAsk});

  final Future<void> Function([String?]) onAsk;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        NeonGlassCard(
          radius: 24,
          borderColor: const Color(0x66A855F7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF22D3EE).withValues(alpha: 0.2),
                      border: Border.all(color: const Color(0xAA22D3EE)),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Welcome to AI Assistant',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Try a smart prompt to get instant inventory insights.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickQuestion(label: 'Today sales koto?', onTap: () => onAsk('Today sales koto?')),
            _QuickQuestion(
              label: 'Low stock products?',
              onTap: () => onAsk('Low stock products?'),
            ),
            _QuickQuestion(
              label: 'Most profitable product?',
              onTap: () => onAsk('Most profitable product?'),
            ),
            _QuickQuestion(
              label: 'What should I restock?',
              onTap: () => onAsk('What should I restock?'),
            ),
            _QuickQuestion(
              label: 'Slow moving products?',
              onTap: () => onAsk('Slow moving products?'),
            ),
          ],
        ),
      ],
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
