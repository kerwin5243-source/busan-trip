import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'info_screen.dart' show PageHeader;

// ─── Models ───────────────────────────────────────────────────────────────────
enum AddMode { expense, payment }
enum ExpType { trip, prepaid }
enum Currency { krw, twd }

class Expense {
  final String name;
  final double cost;
  final String payer;
  final List<String> participants;
  final ExpType type;
  final Currency currency;
  final int ts;

  const Expense({
    required this.name,
    required this.cost,
    required this.payer,
    required this.participants,
    required this.type,
    required this.currency,
    required this.ts,
  });

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        name: j['name'] ?? '',
        cost: (j['cost'] as num).toDouble(),
        payer: j['payer'] ?? '',
        participants: List<String>.from(j['participants'] ?? []),
        type: j['type'] == 'prepaid' ? ExpType.prepaid : ExpType.trip,
        currency: j['currency'] == 'TWD' ? Currency.twd : Currency.krw,
        ts: j['ts'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'cost': cost,
        'payer': payer,
        'participants': participants,
        'type': type == ExpType.prepaid ? 'prepaid' : 'trip',
        'currency': currency == Currency.twd ? 'TWD' : 'KRW',
        'ts': ts,
      };
}

class Payment {
  final String from;
  final String to;
  final double amount;
  final Currency currency;
  final int ts;

  const Payment({
    required this.from,
    required this.to,
    required this.amount,
    required this.currency,
    required this.ts,
  });

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        from: j['from'] ?? '',
        to: j['to'] ?? '',
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] == 'TWD' ? Currency.twd : Currency.krw,
        ts: j['ts'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'amount': amount,
        'currency': currency == Currency.twd ? 'TWD' : 'KRW',
        'ts': ts,
      };
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class MoneyScreen extends ConsumerStatefulWidget {
  final List<String> members;

  const MoneyScreen({super.key, required this.members});

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends ConsumerState<MoneyScreen> {

  AddMode _mode = AddMode.expense;
  Currency _currency = Currency.krw;
  ExpType _expType = ExpType.trip;

  late String _payer;
  late String _payTo;
  late Set<String> _participants;
  String? _selectedViewer; // for personal detail view

  List<Expense> _expenses = [];
  List<Payment> _payments = [];

  final _nameCtrl = TextEditingController();
  final _costCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _payer = widget.members.isNotEmpty ? widget.members.first : '';
    _payTo = widget.members.length > 1 ? widget.members[1] : '';
    _participants = Set.from(widget.members);
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    List<Expense> expenses = [];
    List<Payment> payments = [];
    try {
      final exRaw = prefs.getString('expenses') ?? '[]';
      expenses = (jsonDecode(exRaw) as List)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      await prefs.remove('expenses');
    }
    try {
      final paRaw = prefs.getString('payments') ?? '[]';
      payments = (jsonDecode(paRaw) as List)
          .map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      await prefs.remove('payments');
    }
    if (mounted) setState(() { _expenses = expenses; _payments = payments; });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'expenses', jsonEncode(_expenses.map((e) => e.toJson()).toList()));
    await prefs.setString(
        'payments', jsonEncode(_payments.map((p) => p.toJson()).toList()));
  }

  void _addRecord() {
    final name = _nameCtrl.text.trim();
    final cost = double.tryParse(_costCtrl.text) ?? 0;
    if (name.isEmpty || cost <= 0) return;
    HapticFeedback.mediumImpact();

    if (_mode == AddMode.expense) {
      final parts = _participants.isEmpty
          ? List<String>.from(widget.members)
          : _participants.toList();
      setState(() {
        _expenses.add(Expense(
          name: name,
          cost: cost,
          payer: _payer,
          participants: parts,
          type: _expType,
          currency: _currency,
          ts: DateTime.now().millisecondsSinceEpoch,
        ));
      });
    } else {
      setState(() {
        _payments.add(Payment(
          from: _payer,
          to: _payTo,
          amount: cost,
          currency: _currency,
          ts: DateTime.now().millisecondsSinceEpoch,
        ));
      });
    }
    _nameCtrl.clear();
    _costCtrl.clear();
    _save();
  }

  // ── Calculate balances ────────────────────────────────────────────────────
  Map<String, double> _calcBalances(Currency curr) {
    final bal = {for (final u in widget.members) u: 0.0};

    for (final e in _expenses) {
      if (e.currency != curr) continue;
      final parts = e.participants.isNotEmpty
          ? e.participants
          : widget.members;
      final share = e.cost / parts.length;
      bal[e.payer] = (bal[e.payer] ?? 0) + e.cost;
      for (final u in parts) {
        bal[u] = (bal[u] ?? 0) - share;
      }
    }
    for (final p in _payments) {
      if (p.currency != curr) continue;
      bal[p.from] = (bal[p.from] ?? 0) + p.amount;
      bal[p.to] = (bal[p.to] ?? 0) - p.amount;
    }
    return bal;
  }

  String _fmt(Currency c, double v) {
    final abs = v.abs();
    return c == Currency.krw
        ? '₩${abs.toStringAsFixed(0)}'
        : 'NT\$${abs.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final balKrw = _calcBalances(Currency.krw);
    final balTwd = _calcBalances(Currency.twd);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: const PageHeader(title: '記帳'),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 0, 20,
              MediaQuery.of(context).padding.bottom + 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Mode switch ─────────────────────────────────
              IosSegment<AddMode>(
                items: const [
                  (AddMode.expense, '新增支出'),
                  (AddMode.payment, '收付款'),
                ],
                value: _mode,
                onChanged: (m) => setState(() => _mode = m),
              ),
              const SizedBox(height: 12),
              // ── Currency switch ──────────────────────────────
              IosSegment<Currency>(
                items: const [
                  (Currency.krw, '韓幣 (₩)'),
                  (Currency.twd, '台幣 (NT\$)'),
                ],
                value: _currency,
                onChanged: (c) => setState(() => _currency = c),
              ),
              const SizedBox(height: 16),
              // ── Input form ───────────────────────────────────
              GlassCard(
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + amount
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _FormField(
                            ctrl: _nameCtrl,
                            hint: '項目 / 備註',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _FormField(
                            ctrl: _costCtrl,
                            hint: '金額',
                            keyboardType: TextInputType.number,
                            prefix: _currency == Currency.krw ? '₩' : 'NT\$',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Payer
                    Text('付款人',
                        style: TStyle.sans(11,
                            fw: FontWeight.w700, color: C.ink2)),
                    const SizedBox(height: 8),
                    UserTabRow(
                      users: widget.members,
                      selected: _payer,
                      onSelect: (u) => setState(() => _payer = u),
                    ),
                    // Payment target
                    if (_mode == AddMode.payment) ...[
                      const SizedBox(height: 14),
                      Text('收款人',
                          style: TStyle.sans(11,
                              fw: FontWeight.w700, color: C.ink2)),
                      const SizedBox(height: 8),
                      UserTabRow(
                        users: widget.members
                            .where((u) => u != _payer)
                            .toList(),
                        selected: _payTo,
                        onSelect: (u) => setState(() => _payTo = u),
                      ),
                    ],
                    // Expense type + participants
                    if (_mode == AddMode.expense) ...[
                      const SizedBox(height: 14),
                      IosSegment<ExpType>(
                        items: const [
                          (ExpType.trip, '行中支出'),
                          (ExpType.prepaid, '預付費用'),
                        ],
                        value: _expType,
                        onChanged: (t) => setState(() => _expType = t),
                      ),
                      const SizedBox(height: 12),
                      Text('分攤成員',
                          style: TStyle.sans(11,
                              fw: FontWeight.w700, color: C.ink2)),
                      const SizedBox(height: 8),
                      _HouseholdPicker(
                        members: widget.members,
                        selected: _participants,
                        onToggle: (u) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (_participants.contains(u)) {
                              _participants.remove(u);
                            } else {
                              _participants.add(u);
                            }
                          });
                        },
                        onSelectAll: (group) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            final all = group.toSet();
                            final allSelected = all.every(_participants.contains);
                            if (allSelected) {
                              _participants.removeAll(all);
                            } else {
                              _participants.addAll(all);
                            }
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Submit
                    GestureDetector(
                      onTap: _addRecord,
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: C.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text('加入紀錄',
                              style: TStyle.sans(15,
                                  fw: FontWeight.w900,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // ── Balance summary ──────────────────────────────
              SectionTitle('個人結算', icon: Icons.account_balance_wallet_outlined),
              if (_expenses.isNotEmpty || _payments.isNotEmpty) ...[
                _BalanceTable(
                    balances: balKrw,
                    currency: Currency.krw,
                    fmt: _fmt,
                    selectedViewer: _selectedViewer,
                    onSelectViewer: (u) => setState(() =>
                        _selectedViewer = _selectedViewer == u ? null : u)),
                const SizedBox(height: 10),
                _BalanceTable(
                    balances: balTwd,
                    currency: Currency.twd,
                    fmt: _fmt,
                    selectedViewer: _selectedViewer,
                    onSelectViewer: (u) => setState(() =>
                        _selectedViewer = _selectedViewer == u ? null : u)),
                // Personal breakdown
                if (_selectedViewer != null) ...[
                  const SizedBox(height: 16),
                  _PersonalDetail(
                    person: _selectedViewer!,
                    expenses: _expenses,
                    payments: _payments,
                    fmt: _fmt,
                  ),
                ],
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('尚無記錄',
                        style: TStyle.sans(13, color: C.ink2)),
                  ),
                ),
              const SizedBox(height: 24),
              // ── Records ──────────────────────────────────────
              SectionTitle('支出明細', icon: Icons.receipt_long_outlined),
              ..._expenses.reversed.map((e) => SwipeToDelete(
                    key: ValueKey('exp_${e.ts}'),
                    onDelete: () {
                      setState(() => _expenses.removeWhere(
                          (x) => x.ts == e.ts));
                      _save();
                    },
                    child: _ExpenseRow(
                        item: e, members: widget.members, fmt: _fmt),
                  )),
              if (_payments.isNotEmpty) ...[
                const SizedBox(height: 16),
                SectionTitle('收付款明細', icon: Icons.swap_horiz_rounded),
                ..._payments.reversed.map((p) => SwipeToDelete(
                      key: ValueKey('pay_${p.ts}'),
                      onDelete: () {
                        setState(() => _payments.removeWhere(
                            (x) => x.ts == p.ts));
                        _save();
                      },
                      child: _PaymentRow(item: p, fmt: _fmt),
                    )),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Form field ───────────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputType keyboardType;
  final String? prefix;

  const _FormField({
    required this.ctrl,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (prefix != null) ...[
            Text(prefix!,
                style: TStyle.mono(13, color: C.ink2)),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: keyboardType,
              style: TStyle.sans(14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TStyle.sans(14, color: C.ink2),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Household picker (A/B rows of 3) ────────────────────────────────────────
class _HouseholdPicker extends StatelessWidget {
  final List<String> members;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final ValueChanged<List<String>> onSelectAll;

  const _HouseholdPicker({
    required this.members,
    required this.selected,
    required this.onToggle,
    required this.onSelectAll,
  });

  static const _houseLabels = ['甲', '乙'];
  static const _houseColors = [Color(0xFF3D6EA9), Color(0xFF2F8F5B)];

  @override
  Widget build(BuildContext context) {
    final half = (members.length / 2).ceil();
    final rows = [
      members.take(half).toList(),
      members.skip(half).toList(),
    ];

    return Column(
      children: List.generate(rows.length, (rowIdx) {
        final group = rows[rowIdx];
        if (group.isEmpty) return const SizedBox.shrink();
        final color = _houseColors[rowIdx % _houseColors.length];
        final label = _houseLabels[rowIdx % _houseLabels.length];
        final allOn = group.every(selected.contains);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Household select-all button
              GestureDetector(
                onTap: () => onSelectAll(group),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: allOn
                        ? color.withValues(alpha: 0.15)
                        : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: allOn ? color.withValues(alpha: 0.5) : C.divider,
                      width: allOn ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text('全$label',
                        style: TStyle.sans(10,
                            fw: FontWeight.w900,
                            color: allOn ? color : C.ink2)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Member chips
              ...group.map((u) {
                final on = selected.contains(u);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onToggle(u),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: on
                            ? color.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: on
                              ? color.withValues(alpha: 0.5)
                              : C.divider.withValues(alpha: 0.9),
                          width: on ? 1.5 : 1,
                        ),
                      ),
                      child: Text(u,
                          style: TStyle.sans(13,
                              fw: FontWeight.w800,
                              color: on ? color : C.ink2)),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Balance table ────────────────────────────────────────────────────────────
class _BalanceTable extends StatelessWidget {
  final Map<String, double> balances;
  final Currency currency;
  final String Function(Currency, double) fmt;
  final String? selectedViewer;
  final ValueChanged<String>? onSelectViewer;

  const _BalanceTable({
    required this.balances,
    required this.currency,
    required this.fmt,
    this.selectedViewer,
    this.onSelectViewer,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = currency == Currency.krw ? '₩ 韓幣' : 'NT\$ 台幣';
    final all = balances.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (all.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(symbol, style: TStyle.sans(11, fw: FontWeight.w900, color: C.ink2)),
          const SizedBox(height: 8),
          ...all.map((e) {
            final isPositive = e.value >= 0;
            final isSelected = selectedViewer == e.key;
            return GestureDetector(
              onTap: () => onSelectViewer?.call(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? C.accent.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(color: C.accent.withValues(alpha: 0.3))
                      : null,
                ),
                child: Row(
                  children: [
                    Text(e.key,
                        style: TStyle.sans(14,
                            fw: isSelected ? FontWeight.w900 : FontWeight.w700,
                            color: isSelected ? C.primary : C.ink)),
                    const SizedBox(width: 4),
                    if (isSelected)
                      Icon(Icons.expand_more_rounded,
                          size: 14, color: C.accent),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (e.value.abs() < 0.5
                                ? C.divider
                                : isPositive
                                    ? const Color(0xFF34C759)
                                    : Colors.red)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        e.value.abs() < 0.5
                            ? '持平'
                            : '${isPositive ? '+' : '-'}${fmt(currency, e.value)}',
                        style: TStyle.mono(13,
                            color: e.value.abs() < 0.5
                                ? C.ink2
                                : isPositive
                                    ? const Color(0xFF2E7D32)
                                    : Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Personal expense detail ──────────────────────────────────────────────────
class _PersonalDetail extends StatelessWidget {
  final String person;
  final List<Expense> expenses;
  final List<Payment> payments;
  final String Function(Currency, double) fmt;

  const _PersonalDetail({
    required this.person,
    required this.expenses,
    required this.payments,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final myPaid = expenses.where((e) => e.payer == person).toList();
    final myShare = expenses
        .where((e) =>
            e.participants.contains(person) ||
            (e.participants.isEmpty))
        .toList();

    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('$person 的明細',
                style: TStyle.serifTitle(15, color: C.primary)),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: const Icon(Icons.close_rounded,
                  size: 16, color: C.ink2),
            ),
          ]),
          const SizedBox(height: 10),
          if (myPaid.isNotEmpty) ...[
            Text('我付的帳',
                style: TStyle.sans(11, fw: FontWeight.w800, color: C.ink2)),
            const SizedBox(height: 6),
            ...myPaid.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Expanded(
                        child: Text(e.name,
                            style: TStyle.sans(13, fw: FontWeight.w700))),
                    Text(fmt(e.currency, e.cost),
                        style: TStyle.mono(13,
                            color: const Color(0xFF2E7D32))),
                  ]),
                )),
            const SizedBox(height: 10),
          ],
          if (myShare.isNotEmpty) ...[
            Text('分攤項目',
                style: TStyle.sans(11, fw: FontWeight.w800, color: C.ink2)),
            const SizedBox(height: 6),
            ...myShare.map((e) {
              final parts = e.participants.isNotEmpty
                  ? e.participants.length
                  : 1;
              final share = e.cost / parts;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Expanded(
                      child: Text(e.name,
                          style: TStyle.sans(13, fw: FontWeight.w700))),
                  Text('−${fmt(e.currency, share)}',
                      style: TStyle.mono(13, color: Colors.red)),
                ]),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ─── Expense row ──────────────────────────────────────────────────────────────
class _ExpenseRow extends StatelessWidget {
  final Expense item;
  final List<String> members;
  final String Function(Currency, double) fmt;

  const _ExpenseRow(
      {required this.item, required this.members, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final parts =
        item.participants.isNotEmpty ? item.participants : members;
    final share = item.cost / parts.length;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 14,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.type == ExpType.prepaid
                  ? const Color(0x1FE05C3A)
                  : const Color(0x1F3D6EA9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.type == ExpType.prepaid
                  ? Icons.schedule_rounded
                  : Icons.receipt_rounded,
              size: 18,
              color: item.type == ExpType.prepaid
                  ? const Color(0xFFE05C3A)
                  : const Color(0xFF3D6EA9),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: TStyle.sans(14, fw: FontWeight.w700)),
                Text(
                  '${item.payer} 付 · 均攤 ${fmt(item.currency, share)}/人',
                  style: TStyle.sans(12, color: C.ink2),
                ),
              ],
            ),
          ),
          Text(fmt(item.currency, item.cost),
              style: TStyle.mono(14, color: C.ink)),
        ],
      ),
    );
  }
}

// ─── Payment row ──────────────────────────────────────────────────────────────
class _PaymentRow extends StatelessWidget {
  final Payment item;
  final String Function(Currency, double) fmt;

  const _PaymentRow({required this.item, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 14,
      tint: const Color(0xCCF0FFF4),
      child: Row(
        children: [
          const Icon(Icons.swap_horiz_rounded,
              size: 20, color: Color(0xFF2F8F5B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${item.from} → ${item.to}',
              style: TStyle.sans(14, fw: FontWeight.w700),
            ),
          ),
          Text(fmt(item.currency, item.amount),
              style: TStyle.mono(14,
                  color: const Color(0xFF2F8F5B))),
        ],
      ),
    );
  }
}
