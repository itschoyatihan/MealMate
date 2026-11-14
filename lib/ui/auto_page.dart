import 'package:flutter/material.dart';
import 'auto_generator.dart';
import 'auto_models.dart';
import 'foods_page.dart';

/// Shared for guest and authenticated users; caller supplies real catalog,
/// current budget, initial saved plan, and persistence callback.
class AutoPlanPage extends StatefulWidget {
  final int dailyBudget;
  final List<FoodCatalogItem> catalog;
  final AutoPlan? initialPlan;
  final Future<void> Function(AutoPlan) onSave;
  final VoidCallback? onChangeBudget;

  const AutoPlanPage({
    super.key,
    required this.dailyBudget,
    this.catalog = sampleFoodCatalog,
    required this.onSave,
    this.initialPlan,
    this.onChangeBudget,
  });

  @override
  State<AutoPlanPage> createState() => _AutoPlanPageState();
}

class _AutoPlanPageState extends State<AutoPlanPage> {
  static const green = Color(0xFF083F25);
  static const orange = Color(0xFFFF7900);
  static const cream = Color(0xFFFFF8EF);
  static const paleGreen = Color(0xFFEAF6DF);
  final _generator = AutoGenerator();
  late Set<MealType> _selected;
  Map<MealType, FoodCatalogItem> _draft = {};
  bool _generated = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final plan = widget.initialPlan;
    _selected = plan == null ? MealType.values.toSet() : plan.meals.keys.toSet();
    if (plan != null) {
      _draft = Map.of(plan.meals);
      _generated = true;
    }
  }

  int get _total => _draft.values.fold(0, (sum, food) => sum + food.price);
  bool get _complete => _generated && _selected.isNotEmpty &&
      _draft.length == _selected.length &&
      _selected.every(_draft.containsKey) &&
      _total <= widget.dailyBudget;

  void _toggle(MealType type) {
    if (_saving) return;
    setState(() {
      if (_selected.remove(type)) {
        _draft.remove(type);
      } else {
        _selected.add(type);
      }
      _error = null;
    });
  }

  void _generateAll() {
    if (_saving) return;
    final result = _generator.generate(
      catalog: widget.catalog,
      selected: _selected,
      budget: widget.dailyBudget,
      previous: _draft,
    );
    setState(() {
      if (result.success) {
        _draft = Map.of(result.meals!);
        _generated = true;
        _error = null;
      } else {
        _error = result.error;
      }
    });
  }

  void _regenerateOne(MealType type) {
    if (_saving || !_generated || !_selected.contains(type)) return;
    final result = _generator.regenerateOne(
      type: type,
      catalog: widget.catalog,
      current: _draft,
      budget: widget.dailyBudget,
    );
    setState(() {
      if (result.success) {
        _draft = Map.of(result.meals!);
        _error = null;
      } else {
        _error = result.error;
      }
    });
  }

  void _clear() {
    if (_saving) return;
    setState(() {
      _draft = {};
      _selected = MealType.values.toSet();
      _generated = false;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (!_complete || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(AutoPlan(
        date: DateTime.now(),
        meals: Map.of(_draft),
      ));
      if (!mounted) return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save meal plan. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('✨ Automatic Meal Plan'),
        backgroundColor: cream,
        foregroundColor: green,
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 850;
        return SingleChildScrollView(
          padding: EdgeInsets.all(wide ? 28 : 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Column(children: [
                          _summary(),
                          const SizedBox(height: 20),
                          _selector(),
                        ])),
                        const SizedBox(width: 24),
                        Expanded(child: _results()),
                      ],
                    )
                  : Column(children: [
                      _summary(),
                      const SizedBox(height: 20),
                      _selector(),
                      const SizedBox(height: 20),
                      _results(),
                    ]),
            ),
          ),
        );
      }),
    );
  }

  Widget _panel({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3E7DD)),
        ),
        child: child,
      );

  Widget _summary() => _panel(child: Row(children: [
        _stat("Today's\nBudget", widget.dailyBudget),
        const SizedBox(height: 55, child: VerticalDivider()),
        _stat('Plan\nTotal', _generated ? _total : null),
        const SizedBox(height: 55, child: VerticalDivider()),
        _stat('Remaining\nBudget',
            _generated ? widget.dailyBudget - _total : widget.dailyBudget),
      ]));

  Widget _stat(String label, int? value) => Expanded(
        child: Column(children: [
          Text(label, textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          FittedBox(child: Text(value == null ? '—' : '$value Ks',
              style: const TextStyle(color: green, fontWeight: FontWeight.bold,
                  fontSize: 19))),
        ]),
      );

  Widget _selector() => _panel(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose Meal Types', style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: green)),
          const SizedBox(height: 4),
          const Text('Select which meals to include in your plan.'),
          const SizedBox(height: 16),
          Column(
            children: [
              for (int row = 0; row < MealType.values.length; row += 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      for (final type in MealType.values.skip(row).take(2))
                        Expanded(
                          child: InkWell(
                            onTap: _saving ? null : () => _toggle(type),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    _selected.contains(type)
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    color: _selected.contains(type)
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      type.label,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
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
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: _saving ? null : _generateAll,
            icon: Icon(_generated ? Icons.refresh : Icons.auto_awesome),
            label: Text(_generated ? 'Regenerate Plan (All)' : 'Generate Meal Plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: green, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          )),
        ],
      ));

  Widget _results() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) _panel(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_error!, style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold)),
              if (widget.onChangeBudget != null)
                TextButton(onPressed: widget.onChangeBudget,
                    child: const Text('Adjust Daily Budget')),
            ],
          )),
          if (_error != null) const SizedBox(height: 12),
          if (!_generated)
            _panel(child: const SizedBox(
              height: 270,
              child: Column(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.ramen_dining, size: 76, color: Colors.green),
                  SizedBox(height: 14),
                  Text('Your meal plan will appear here',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Choose meal types and tap Generate Meal Plan.',
                      textAlign: TextAlign.center),
                ],
              ),
            ))
          else _panel(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recommended Meal Plan', style: TextStyle(
                  fontSize: 21, fontWeight: FontWeight.bold, color: green)),
              const SizedBox(height: 5),
              const Text('A budget-friendly plan from the food catalog.'),
              const SizedBox(height: 14),
              ...MealType.values.where(_selected.contains).map((type) {
                final food = _draft[type];
                return Card(child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(children: [
                    SizedBox(width: 58, height: 58, child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: food?.imagePath == null || food!.imagePath!.isEmpty
                          ? const ColoredBox(color: paleGreen,
                              child: Icon(Icons.restaurant, color: green))
                          : Image.asset(food.imagePath!, fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const ColoredBox(
                                color: paleGreen,
                                child: Icon(Icons.restaurant, color: green),
                              )),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(type.label, style: const TextStyle(color: orange,
                            fontWeight: FontWeight.bold)),
                        Text(food?.name ?? 'Not generated yet',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (food != null) Text('${food.shopName} · ${food.price} Ks'),
                      ],
                    )),
                    IconButton(
                      tooltip: food == null ? 'Generate ${type.label}'
                          : 'Regenerate ${type.label}',
                      onPressed: _saving ? null : () => _regenerateOne(type),
                      icon: Icon(food == null ? Icons.add : Icons.refresh,
                          color: Colors.green),
                    ),
                  ]),
                ));
              }),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: paleGreen,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [const Text('Plan Total',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('$_total Ks', style: const TextStyle(
                          fontWeight: FontWeight.bold))]),
              ),
              const SizedBox(height: 12),
              Text(_complete ? 'This plan is within your daily budget.'
                  : 'Generate all selected meals within your budget before saving.'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _clear,
                      icon: const Icon(Icons.rotate_left, size: 18),
                      label: const Text('Reset'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12,
                        ),
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: _complete && !_saving ? _save : null,
                      icon: const Icon(Icons.check, size: 18),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(_saving ? 'Saving...' : 'Save Meal Plan'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 12,
                        ),
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )),
        ],
      );
}
