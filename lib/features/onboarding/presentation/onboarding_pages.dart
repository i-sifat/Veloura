import 'package:flutter/material.dart';
import 'package:veloura/features/onboarding/presentation/onboarding_art.dart';
import 'package:veloura/features/onboarding/presentation/onboarding_tokens.dart';

/// A cinematic introduction page with centered artwork and copy.
class OnboardingIntroPage extends StatelessWidget {
  const OnboardingIntroPage({
    required this.variant,
    required this.title,
    required this.body,
    this.brand = false,
    super.key,
  });

  final int variant;
  final String title;
  final String body;
  final bool brand;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      children: [
        OnboardingArt(variant: variant),
        if (brand) ...[
          const Text('Veloura', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700)),
          const Text(
            'Play. Connect. Grow together.',
            style: TextStyle(color: OnboardingTokens.pinkLight, fontSize: 13),
          ),
          const SizedBox(height: 42),
        ] else
          const SizedBox(height: 34),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 330),
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: OnboardingTokens.muted, height: 1.55),
          ),
        ),
      ],
    ),
  );
}

/// Name capture matching the elevated fields in the supplied design.
class NamesPage extends StatelessWidget {
  const NamesPage({required this.nameA, required this.nameB, super.key});

  final TextEditingController nameA;
  final TextEditingController nameB;

  @override
  Widget build(BuildContext context) => _SetupLayout(
    title: 'What are your names?',
    subtitle: 'This helps us make the experience\nfeel more personal.',
    child: Column(
      children: [
        _NameField(controller: nameA, label: 'Your name', hint: 'You'),
        const SizedBox(height: 14),
        _NameField(controller: nameB, label: "Partner's name", hint: 'Partner'),
        const SizedBox(height: 42),
        const Icon(
          Icons.favorite_border_rounded,
          color: OnboardingTokens.pink,
          size: 104,
          shadows: [OnboardingTokens.glow],
        ),
      ],
    ),
  );
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.label, required this.hint});

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: OnboardingTokens.fieldHeight,
    child: TextField(
      controller: controller,
      maxLength: 16,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        suffixIcon: const Icon(Icons.favorite_border, color: OnboardingTokens.pink),
        filled: true,
        fillColor: OnboardingTokens.elevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: OnboardingTokens.border),
        ),
      ),
    ),
  );
}

/// Inclusive two-person sex selection page from the reference flow.
class SexPage extends StatelessWidget {
  const SexPage({
    required this.yours,
    required this.partners,
    required this.onYoursChanged,
    required this.onPartnersChanged,
    super.key,
  });

  final String yours;
  final String partners;
  final ValueChanged<String> onYoursChanged;
  final ValueChanged<String> onPartnersChanged;

  @override
  Widget build(BuildContext context) => _SetupLayout(
    title: 'Select sex',
    subtitle: 'Just so we can keep things\ninclusive and personal.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChoiceRow(value: yours, onChanged: onYoursChanged),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Divider(color: OnboardingTokens.border),
        ),
        const Text("Your partner's sex", style: TextStyle(color: OnboardingTokens.muted)),
        const SizedBox(height: 12),
        _ChoiceRow(value: partners, onChanged: onPartnersChanged),
      ],
    ),
  );
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _SexChoice(
          label: 'Female',
          symbol: '♀',
          selected: value == 'female',
          onTap: () => onChanged('female'),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _SexChoice(
          label: 'Male',
          symbol: '♂',
          selected: value == 'male',
          onTap: () => onChanged('male'),
        ),
      ),
    ],
  );
}

class _SexChoice extends StatelessWidget {
  const _SexChoice({
    required this.label,
    required this.symbol,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String symbol;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: OnboardingTokens.choiceHeight,
        decoration: BoxDecoration(
          color: OnboardingTokens.elevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            width: selected ? 2 : 1,
            color: selected ? OnboardingTokens.pink : OnboardingTokens.border,
          ),
          boxShadow: selected ? const [OnboardingTokens.glow] : null,
        ),
        child: Stack(
          children: [
            if (selected)
              const Positioned(
                top: 10,
                right: 10,
                child: Icon(Icons.check_circle, size: 20, color: OnboardingTokens.pink),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    symbol,
                    style: TextStyle(
                      fontSize: 52,
                      color: selected ? OnboardingTokens.pinkLight : OnboardingTokens.violet,
                    ),
                  ),
                  Text(label, style: TextStyle(color: selected ? Colors.white : OnboardingTokens.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Final confirmation screen shown before entering the app.
class ReadyPage extends StatelessWidget {
  const ReadyPage({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      children: [
        const SizedBox(height: 40),
        const SizedBox(
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.favorite_border_rounded,
                size: 220,
                color: OnboardingTokens.pink,
                shadows: [OnboardingTokens.glow],
              ),
              Icon(Icons.people_alt_rounded, size: 92, color: Colors.white),
            ],
          ),
        ),
        Text(
          "You're all set!",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        const Text('Welcome to Veloura', style: TextStyle(color: OnboardingTokens.muted)),
        const SizedBox(height: 18),
        const SizedBox(width: 170, child: Divider(color: OnboardingTokens.border)),
        const Icon(Icons.favorite_border, color: OnboardingTokens.pink, size: 18),
        const SizedBox(height: 14),
        const Text(
          'You and your partner are ready\nto play, connect and grow together.',
          textAlign: TextAlign.center,
          style: TextStyle(color: OnboardingTokens.muted, height: 1.55),
        ),
      ],
    ),
  );
}

class _SetupLayout extends StatelessWidget {
  const _SetupLayout({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.only(top: 18),
    child: Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: OnboardingTokens.muted, height: 1.35),
        ),
        const SizedBox(height: 30),
        child,
      ],
    ),
  );
}
