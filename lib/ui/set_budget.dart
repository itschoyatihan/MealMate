import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared, responsive budget entry screen for guest and signed-in users.
/// Returns the saved amount (int) to the calling page using Navigator.pop.
/// Pass [initialBudget] to reuse this same screen for editing.
class SetBudgetPage extends StatefulWidget {
  final int? initialBudget;
  final Future<bool> Function(int amount)? onSave;
  final Widget Function(int amount)? confirmationPageBuilder;

  const SetBudgetPage({
    super.key,
    this.initialBudget,
    this.onSave,
    this.confirmationPageBuilder,
  });

  @override
  State<SetBudgetPage> createState() => _SetBudgetPageState();
}

class _SetBudgetPageState extends State<SetBudgetPage> {
  static const Color darkGreen = Color(0xFF174B27);
  static const Color green = Color(0xFF329B19);
  static const Color lightGreen = Color(0xFFF0F9E5);
  static const List<int> quickAmounts = [5000, 10000, 15000, 20000];

  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialBudget == null ? '' : _format(widget.initialBudget!),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _format(int amount) {
    final digits = amount.toString();
    return digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  int? get _amount => int.tryParse(_controller.text.replaceAll(',', '').trim());

  void _selectAmount(int amount) {
    setState(() => _controller.text = _format(amount));
    _formKey.currentState?.validate();
  }

  bool _isSaving = false;

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final amount = _amount;
    if (amount == null) return;

    if (widget.onSave != null) {
      setState(() => _isSaving = true);

      try {
        final success = await widget.onSave!(amount);
        if (!mounted || !success) return;
      } catch (error) {
        debugPrint('BUDGET SAVE ERROR: $error');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save budget. Please try again.'),
          ),
        );
        return;
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }

    if (!mounted) return;

    if (widget.confirmationPageBuilder != null) {
      Navigator.of(context).pushReplacement<void, int>(
        MaterialPageRoute<void>(
          builder: (_) => widget.confirmationPageBuilder!(amount),
        ),
        result: amount,
      );
    } else {
      Navigator.of(context).pop(amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _amount;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF7),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              bottom: -100,
              left: -80,
              right: -80,
              child: Container(
                height: 185,
                decoration: const BoxDecoration(
                  color: Color(0xFFE9F8CF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.elliptical(420, 125),
                    topRight: Radius.elliptical(420, 100),
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 690),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 32,
                    vertical: isMobile ? 20 : 32,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Back',
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: darkGreen,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Set Daily Budget',
                                maxLines: 2,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF14281A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: EdgeInsets.all(isMobile ? 14 : 25),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF3FAE8), Color(0xFFEDF8DE)],
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/img/setbudget.png',
                                width: isMobile ? 65 : 105,
                                height: isMobile ? 75 : 110,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(width: isMobile ? 10 : 23),
                              Container(
                                width: 1,
                                height: isMobile ? 75 : 105,
                                color: const Color(0xFFC8D9B3),
                              ),
                              SizedBox(width: isMobile ? 10 : 23),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Set Your Daily Budget',
                                      style: TextStyle(
                                        fontSize: isMobile ? 19 : 26,
                                        height: 1.12,
                                        fontWeight: FontWeight.w800,
                                        color: darkGreen,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Enter how much you want to spend on meals today.',
                                      style: TextStyle(
                                        fontSize: isMobile ? 14 : 16,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'Daily Budget (MMK)',
                          style: TextStyle(
                            color: darkGreen,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 13),
                        TextFormField(
                          controller: _controller,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. 15,000',
                            hintStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFB0B7B2),
                            ),
                            prefixIcon: const Icon(
                              Icons.monetization_on_rounded,
                              color: green,
                              size: 27,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 21,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(17),
                              borderSide: const BorderSide(
                                color: green,
                                width: 1.6,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(17),
                              borderSide: const BorderSide(
                                color: darkGreen,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final amount = int.tryParse(
                              (value ?? '').replaceAll(',', '').trim(),
                            );
                            if (amount == null || amount <= 0) {
                              return 'Enter a budget greater than 0 MMK';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 35),
                        const Text(
                          'Quick Amount',
                          style: TextStyle(
                            color: darkGreen,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: quickAmounts.map((amount) {
                            final active = selected == amount;
                            return ChoiceChip(
                              label: Text(_format(amount)),
                              selected: active,
                              onSelected: (_) => _selectAmount(amount),
                              showCheckmark: false,
                              backgroundColor: lightGreen,
                              selectedColor: const Color(0xFFD8F29C),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 17,
                                vertical: 12,
                              ),
                              labelStyle: const TextStyle(
                                color: darkGreen,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 70),
                        SizedBox(
                          height: 65,
                          child: ElevatedButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.check_rounded, size: 30),
                            label: const Text(
                              'Save Budget',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(35),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 35),
                      ],
                    ),
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
