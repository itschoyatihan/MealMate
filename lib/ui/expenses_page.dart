import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/api_client.dart';
import '../services/api_exception.dart';
import 'manage_items.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key, this.embedded = false, this.onBack});
  final bool embedded;
  final VoidCallback? onBack;
  @override
  State<ExpensesPage> createState() => ExpensesPageState();
}

class ExpensesPageState extends State<ExpensesPage> {
  Future<bool> confirmLeave() => _canDiscard();
  static const _meals = ['breakfast', 'lunch', 'snacks', 'dinner'];
  static const _icons = [
    Icons.egg_alt_outlined,
    Icons.rice_bowl,
    Icons.local_drink_outlined,
    Icons.dinner_dining,
  ];
  late DateTime _date;
  List<ExpenseItem> _items = [];
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  bool _allowPop = false;
  String? _loadError;
  bool _hasRecord = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _label(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final prefix = _dateKey(d) == _dateKey(_today) ? 'Today, ' : '';
    return '$prefix${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  int get _total => _items.fold(0, (sum, item) => sum + item.total);
  int _mealTotal(String meal) => _items
      .where((e) => e.mealType == meal)
      .fold(0, (sum, e) => sum + e.total);

  Future<void> _load() async {
    final requested = _dateKey(_date);
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final response = await context.read<ApiClient>().get(
        '/expenses',
        queryParameters: {'date': requested},
      );
      if (!mounted || _dateKey(_date) != requested) return;
      final data = response['data'];
      final expense = data is Map ? data['expense'] : null;
      final rawItems = expense is Map ? expense['items'] : null;
      setState(() {
        _items = rawItems is List
            ? rawItems
                  .whereType<Map>()
                  .map(
                    (e) => ExpenseItem.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList()
            : [];
        _hasRecord = true;
        _dirty = false;
      });
    } on ApiException catch (e) {
      if (!mounted || _dateKey(_date) != requested) return;
      if (e.statusCode == 404) {
        setState(() {
          _items = [];
          _hasRecord = false;
          _dirty = false;
        });
      } else {
        setState(() => _loadError = e.message);
      }
    } catch (e) {
      if (!mounted || _dateKey(_date) != requested) return;
      setState(() => _loadError = 'Could not load expenses. Please try again.');
    } finally {
      if (mounted && _dateKey(_date) == requested) {
        setState(() => _loading = false);
      }
    }
  }

  Future<bool> _canDiscard() async {
    if (!_dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Unsaved changes'),
            content: const Text(
              'Your changes have not been saved to the database. Discard them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Keep Editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _selectDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized.isAfter(_today)) {
      await _futureWarning();
      return;
    }
    if (_dateKey(normalized) == _dateKey(_date)) return;
    if (!await _canDiscard() || !mounted) return;
    setState(() => _date = normalized);
    await _load();
  }

  Future<void> _futureWarning() => showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text(
        'Future Date Not Allowed',
        style: TextStyle(color: expenseDarkGreen, fontWeight: FontWeight.bold),
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy, size: 72, color: expenseGreen),
          SizedBox(height: 12),
          Text(
            'You can only view or record expenses for today or past dates.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(c),
          style: FilledButton.styleFrom(
            backgroundColor: expenseGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(180, 48),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  Future<void> _calendar() async {
    var focused = DateTime(_date.year, _date.month, 1);
    DateTime selected = _date;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) {
          final firstWeekday =
              DateTime(focused.year, focused.month, 1).weekday % 7;
          final days = DateTime(focused.year, focused.month + 1, 0).day;
          const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
          const months = [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
          ];
          return AlertDialog(
            title: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => update(
                          () => focused = DateTime(
                            focused.year,
                            focused.month - 1,
                          ),
                        ),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        '${months[focused.month - 1]} ${focused.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => update(
                          () => focused = DateTime(
                            focused.year,
                            focused.month + 1,
                          ),
                        ),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 7,
                    childAspectRatio: 1.1,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final day in weekdays)
                        Center(
                          child: Text(
                            day,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      for (var i = 0; i < firstWeekday; i++) const SizedBox(),
                      for (var day = 1; day <= days; day++)
                        Builder(
                          builder: (_) {
                            final d = DateTime(
                              focused.year,
                              focused.month,
                              day,
                            );
                            final active = _dateKey(d) == _dateKey(selected);
                            return InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () => update(() => selected = d),
                              child: Center(
                                child: CircleAvatar(
                                  radius: 17,
                                  backgroundColor: active
                                      ? expenseGreen
                                      : Colors.transparent,
                                  child: Text(
                                    '$day',
                                    style: TextStyle(
                                      color: active
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: expenseGreen),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _selectDate(selected);
                },
                child: const Text('Select'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _manage(String meal) async {
    final original = _items.where((e) => e.mealType == meal).toList();
    final result = await Navigator.push<List<ExpenseItem>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ManageMealItemsPage(mealType: meal, initialItems: original),
      ),
    );
    if (!mounted || result == null) return;
    final before = original.map((e) => e.toJson().toString()).join('|');
    final after = result.map((e) => e.toJson().toString()).join('|');
    if (before == after) return;
    setState(() {
      _items = [..._items.where((e) => e.mealType != meal), ...result]
        ..sort(
          (a, b) =>
              _meals.indexOf(a.mealType).compareTo(_meals.indexOf(b.mealType)),
        );
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (_saving || _loading || _loadError != null) return;
    if (!_dirty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No changes to save.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final api = context.read<ApiClient>();
      if (_items.isEmpty) {
        if (_hasRecord) {
          // ApiClient.delete has no queryParameters argument; the date is URL-encoded.
          final result = await api.delete('/expenses?date=${_dateKey(_date)}');
          if (result['success'] != true) {
            throw StateError('Expense delete failed.');
          }
        }
      } else {
        final result = await api.post(
          '/expenses',
          data: {
            'date': _dateKey(_date),
            'items': _items.map((e) => e.toJson()).toList(),
          },
        );
        if (result['success'] != true) throw StateError('Expense save failed.');
      }
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _hasRecord = _items.isNotEmpty;
      });
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
          title: const Text(
            'Expenses Saved!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: expenseDarkGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: expenseGreen, size: 76),
              SizedBox(height: 14),
              Text(
                'Your actual meal expenses have been saved.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(c),
              style: FilledButton.styleFrom(
                backgroundColor: expenseGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(180, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) {
        setState(() => _allowPop = true);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException
                  ? e.message
                  : 'Could not save expenses. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteRecord() async {
if (_saving || _loading || _loadError != null || !_hasRecord) {
return;
}

final dateToDelete = _dateKey(_date);

final confirmed = await showDialog<bool>(
context: context,
builder: (dialogContext) => AlertDialog(
title: const Text(
'Delete Record?',
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.red,
fontWeight: FontWeight.bold,
),
),
content: Text(
'Are you sure you want to delete all expense records for ${_label(_date)}?\n\nThis action cannot be undone.',
textAlign: TextAlign.center,
),
actionsAlignment: MainAxisAlignment.center,
actions: [
TextButton(
onPressed: () => Navigator.pop(dialogContext, false),
child: const Text('Cancel'),
),
FilledButton(
onPressed: () => Navigator.pop(dialogContext, true),
style: FilledButton.styleFrom(
backgroundColor: Colors.red,
foregroundColor: Colors.white,
minimumSize: const Size(110, 48),
),
child: const Text('Delete'),
),
],
),
);

if (confirmed != true || !mounted) return;

setState(() => _saving = true);

try {
final result = await context.read<ApiClient>().delete(
'/expenses?date=$dateToDelete',
);

if (result['success'] != true) {
  throw StateError('Expense delete failed.');
}

if (!mounted) return;

setState(() {
  _items = [];
  _hasRecord = false;
  _dirty = false;
});

ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Expense record deleted successfully.'),
    backgroundColor: expenseGreen,
  ),
);
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      e is ApiException
          ? e.message
          : 'Could not delete expense record. Please try again.',
    ),
  ),
);
} finally {
if (mounted) {
setState(() => _saving = false);
}
}
}

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 650;
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (widget.embedded && !didPop) {
          widget.onBack?.call();
        } else if (!didPop && await _canDiscard() && context.mounted) {
          setState(() => _allowPop = true);
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFCF7),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFFCF7),
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: expenseGreen),
            onPressed: () async {
              if (widget.embedded) {
                widget.onBack?.call();
              } else if (await _canDiscard() && context.mounted) {
                setState(() => _allowPop = true);
                Navigator.pop(context);
              }
            },
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expenses',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
              Text(
                'Manage your actual meal expenses',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          toolbarHeight: 76,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: wide ? 720 : 560),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 28 : 16,
                vertical: 16,
              ),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _loading
                          ? null
                          : () => _selectDate(
                              _date.subtract(const Duration(days: 1)),
                            ),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading ? null : _calendar,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 58),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          side: const BorderSide(
                            color: expenseGreen,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              color: expenseGreen,
                              size: 26,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _label(_date),
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'Tap to select date',
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: expenseGreen,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _loading
                          ? null
                          : () =>
                                _selectDate(_date.add(const Duration(days: 1))),
                      icon: const Icon(Icons.chevron_right),
                    ),
                    OutlinedButton(
                      onPressed: _loading ? null : () => _selectDate(_today),
                      child: const Text(
                        'Today',
                        style: TextStyle(color: expenseGreen),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: expenseGreen),
                    ),
                  )
                else if (_loadError != null)
                  Center(
                    child: Column(
                      children: [
                        Text(_loadError!, textAlign: TextAlign.center),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else ...[
                  if (_items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      child: Column(
                        children: [
                          const Text(
                            'No Expense Record Yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You haven’t added any meal expenses for ${_label(_date).toLowerCase()}.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  for (var i = 0; i < _meals.length; i++) _mealCard(i),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8D9),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.monetization_on_outlined,
                          color: Color(0xFFFFA500),
                          size: 30,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _dateKey(_date) == _dateKey(_today)
                                ? 'Today’s Total'
                                : 'Day’s Total',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          expenseMoney(_total),
                          style: const TextStyle(
                            fontSize: 18,
                            color: expenseDarkGreen,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check),
                    label: Text(
                      _saving ? 'Saving...' : 'Save Changes',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: expenseGreen,
                      minimumSize: const Size.fromHeight(55),
                    ),
),

              if (_hasRecord) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _deleteRecord,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text(
                    'Delete Record',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(
                      color: Colors.red,
                      width: 1.5,
                    ),
                    minimumSize: const Size.fromHeight(55),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mealCard(int i) {
    final meal = _meals[i];
    final entries = _items.where((e) => e.mealType == meal).toList();
    final label = '${meal[0].toUpperCase()}${meal.substring(1)}';
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _manage(meal),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFFFF6E9),
                child: Icon(
                  _icons[i],
                  color: const Color(0xFFFF9C00),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entries.isEmpty
                          ? label
                          : '$label (${entries.length} ${entries.length == 1 ? 'item' : 'items'})',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entries.isEmpty
                          ? 'No item added'
                          : entries.map((e) => e.name).join(', '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (entries.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    expenseMoney(_mealTotal(meal)),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: expenseDarkGreen,
                    ),
                  ),
                ),
              Icon(
                entries.isEmpty ? Icons.add_circle : Icons.edit_outlined,
                color: expenseGreen,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
