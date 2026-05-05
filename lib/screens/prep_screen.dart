import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as s;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'info_screen.dart' show PageHeader;

// ─── Todo model ───────────────────────────────────────────────────────────────
class TodoItem {
  final String id;
  String title;
  String note;
  String link;
  bool done;

  TodoItem({
    required this.id,
    required this.title,
    this.note = '',
    this.link = '',
    this.done = false,
  });

  factory TodoItem.fromMap(Map<String, dynamic> m) => TodoItem(
        id: m['id'] as String? ?? _newId(),
        title: m['title'] as String? ?? '',
        note: m['note'] as String? ?? '',
        link: m['link'] as String? ?? '',
        done: m['done'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'note': note,
        'link': link,
        'done': done,
      };

  static String _newId() =>
      DateTime.now().microsecondsSinceEpoch.toString();
}

// ─── Packing icons ────────────────────────────────────────────────────────────
const _carryIconMap = <String, IconData>{
  '護照': Icons.badge_outlined,
  '錢包': Icons.account_balance_wallet_outlined,
  '信用卡': Icons.credit_card_outlined,
  '手機': Icons.phone_android_outlined,
  '行動電源': Icons.battery_charging_full_outlined,
  '耳機': Icons.headphones_outlined,
  '充電線': Icons.usb_rounded,
  '口罩': Icons.masks_outlined,
  '外套': Icons.dry_cleaning_outlined,
  '雨傘 / 折傘': Icons.umbrella_outlined,
  '換洗衣物（一天份）': Icons.checkroom_outlined,
  '藥品急救包': Icons.medical_services_outlined,
};

const _checkIconMap = <String, IconData>{
  '衣物（4天份）': Icons.checkroom_outlined,
  '內衣褲': Icons.dry_cleaning_outlined,
  '鞋子（備用）': Icons.directions_run_outlined,
  '盥洗用品': Icons.soap_outlined,
  '保養品': Icons.face_retouching_natural,
  '防曬乳': Icons.wb_sunny_outlined,
  '洗髮潤髮': Icons.shower_outlined,
  '吹風機（如需）': Icons.air_outlined,
  '旅行插座 / 轉接頭': Icons.electrical_services_outlined,
  '托運鎖頭': Icons.lock_outline_rounded,
  '空袋子（買東西用）': Icons.shopping_bag_outlined,
};

// ─── Provider ────────────────────────────────────────────────────────────────
final _checklistProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final raw = await s.rootBundle.loadString('assets/data/checklists.json');
  return jsonDecode(raw) as Map<String, dynamic>;
});

// ─── Screen ───────────────────────────────────────────────────────────────────
class PrepScreen extends ConsumerStatefulWidget {
  final List<String> members;
  const PrepScreen({super.key, required this.members});

  @override
  ConsumerState<PrepScreen> createState() => _PrepScreenState();
}

class _PrepScreenState extends ConsumerState<PrepScreen> {
  late String _curUser;
  List<TodoItem> _todos = [];
  Map<String, Set<String>> _carryChecked = {};
  Map<String, Set<String>> _checkChecked = {};
  bool _todosLoaded = false; // ignore: unused_field

  @override
  void initState() {
    super.initState();
    _curUser = widget.members.isNotEmpty ? widget.members.first : 'Kerwin';
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // Todos: load from prefs, or seed from bundled JSON
    List<TodoItem> todos;
    final todosJson = prefs.getString('todos_data');
    if (todosJson != null) {
      final list = jsonDecode(todosJson) as List<dynamic>;
      todos = list.map((m) => TodoItem.fromMap(m as Map<String, dynamic>)).toList();
    } else {
      // Seed from assets
      try {
        final raw = await s.rootBundle.loadString('assets/data/todos.json');
        final list = jsonDecode(raw) as List<dynamic>;
        todos = list.map((m) => TodoItem.fromMap(m as Map<String, dynamic>)).toList();
        await prefs.setString('todos_data',
            jsonEncode(todos.map((t) => t.toMap()).toList()));
      } catch (_) {
        todos = [];
      }
    }

    // Per-user carry & check
    final Map<String, Set<String>> carry = {};
    final Map<String, Set<String>> check = {};
    for (final u in widget.members) {
      carry[u] = (prefs.getStringList('carry_$u') ?? []).toSet();
      check[u] = (prefs.getStringList('check_$u') ?? []).toSet();
    }
    if (mounted) {
      setState(() {
        _todos = todos;
        _todosLoaded = true;
        _carryChecked = carry;
        _checkChecked = check;
      });
    }
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'todos_data', jsonEncode(_todos.map((t) => t.toMap()).toList()));
  }

  Future<void> _saveCarry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('carry_$_curUser',
        (_carryChecked[_curUser] ?? {}).toList());
  }

  Future<void> _saveCheck() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('check_$_curUser',
        (_checkChecked[_curUser] ?? {}).toList());
  }

  void _toggleTodo(int i) {
    HapticFeedback.selectionClick();
    setState(() => _todos[i].done = !_todos[i].done);
    _saveTodos();
  }

  void _deleteTodo(int i) {
    HapticFeedback.mediumImpact();
    setState(() => _todos.removeAt(i));
    _saveTodos();
  }

  void _toggleCarry(String item) {
    HapticFeedback.selectionClick();
    setState(() {
      _carryChecked[_curUser] ??= {};
      if (_carryChecked[_curUser]!.contains(item)) {
        _carryChecked[_curUser]!.remove(item);
      } else {
        _carryChecked[_curUser]!.add(item);
      }
    });
    _saveCarry();
  }

  void _toggleCheck(String item) {
    HapticFeedback.selectionClick();
    setState(() {
      _checkChecked[_curUser] ??= {};
      if (_checkChecked[_curUser]!.contains(item)) {
        _checkChecked[_curUser]!.remove(item);
      } else {
        _checkChecked[_curUser]!.add(item);
      }
    });
    _saveCheck();
  }

  void _showTodoSheet({TodoItem? existing, int? editIndex}) {
    final titleCtrl =
        TextEditingController(text: existing?.title ?? '');
    final noteCtrl =
        TextEditingController(text: existing?.note ?? '');
    final linkCtrl =
        TextEditingController(text: existing?.link ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: C.bgBody,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: C.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(existing == null ? '新增待辦' : '編輯待辦',
                  style: TStyle.serifTitle(18)),
              const SizedBox(height: 16),
              _SheetField(ctrl: titleCtrl, label: '標題', hint: '例：韓圜換匯'),
              const SizedBox(height: 12),
              _SheetField(
                  ctrl: noteCtrl, label: '備註', hint: '例：建議到明洞換匯'),
              const SizedBox(height: 12),
              _SheetField(
                  ctrl: linkCtrl,
                  label: '連結 URL',
                  hint: 'https://...',
                  keyboardType: TextInputType.url),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: C.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    setState(() {
                      if (editIndex != null && existing != null) {
                        existing.title = titleCtrl.text.trim();
                        existing.note = noteCtrl.text.trim();
                        existing.link = linkCtrl.text.trim();
                      } else {
                        _todos.add(TodoItem(
                          id: TodoItem._newId(),
                          title: titleCtrl.text.trim(),
                          note: noteCtrl.text.trim(),
                          link: linkCtrl.text.trim(),
                        ));
                      }
                    });
                    _saveTodos();
                    Navigator.pop(ctx);
                  },
                  child: Text(existing == null ? '新增' : '儲存',
                      style: TStyle.sans(15,
                          fw: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checklistAsync = ref.watch(_checklistProvider);
    final carryDone = _carryChecked[_curUser] ?? {};
    final checkDone = _checkChecked[_curUser] ?? {};

    final bottomPad = MediaQuery.of(context).padding.bottom + 100;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: const PageHeader(title: '行前'),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // ── 出發前待辦 ──────────────────────────────────
              Row(
                children: [
                  SectionTitle('出發前待辦', icon: Icons.task_alt_rounded),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showTodoSheet(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: C.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add_rounded,
                              size: 14, color: C.accent),
                          const SizedBox(width: 3),
                          Text('新增',
                              style: TStyle.sans(12,
                                  fw: FontWeight.w700, color: C.accent)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _todos.length,
                itemBuilder: (context, i) {
                  final t = _todos[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SwipeToDelete(
                      key: Key(t.id),
                      onDelete: () => _deleteTodo(i),
                      onEdit: () => _showTodoSheet(existing: t, editIndex: i),
                      confirmLabel: '刪除',
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        radius: 16,
                        tint: t.done
                            ? const Color(0xCCE8F5E9)
                            : const Color(0xBEFFFFFF),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _toggleTodo(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: t.done
                                      ? const Color(0xFF34C759)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: t.done
                                        ? const Color(0xFF34C759)
                                        : C.divider,
                                    width: 1.5,
                                  ),
                                ),
                                child: t.done
                                    ? const Icon(Icons.check_rounded,
                                        size: 14,
                                        color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    style: TStyle.sans(14,
                                        fw: FontWeight.w700,
                                        color: t.done ? C.ink2 : C.ink),
                                  ),
                                  if (t.note.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(t.note,
                                        style: TStyle.sans(12,
                                            color: C.ink2
                                                .withValues(alpha: 0.75))),
                                  ],
                                  if (t.link.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () async {
                                        final uri = Uri.tryParse(t.link);
                                        if (uri != null &&
                                            await canLaunchUrl(uri)) {
                                          await launchUrl(uri,
                                              mode: LaunchMode
                                                  .externalApplication);
                                        }
                                      },
                                      child: Row(
                                        children: [
                                          Icon(Icons.link_rounded,
                                              size: 13,
                                              color: C.accent
                                                  .withValues(alpha: 0.8)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              t.link,
                                              style: TStyle.sans(11,
                                                  color: C.accent
                                                      .withValues(alpha: 0.85)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // ── 個人行李清單 ────────────────────────────────
              SectionTitle('個人行李清單', icon: Icons.luggage_rounded),
              const SizedBox(height: 10),
              UserTabRow(
                users: widget.members,
                selected: _curUser,
                onSelect: (u) => setState(() => _curUser = u),
              ),
              const SizedBox(height: 14),

              checklistAsync.when(
                data: (data) {
                  final carry =
                      (data['carry'] as List<dynamic>).cast<String>();
                  final check =
                      (data['check'] as List<dynamic>).cast<String>();
                  final total = carry.length + check.length;
                  final done = carryDone.length + checkDone.length;
                  final progress = total > 0 ? done / total : 0.0;

                  return Column(
                    children: [
                      // Progress bar
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        radius: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('打包進度',
                                    style: TStyle.sans(13,
                                        fw: FontWeight.w700,
                                        color: C.ink)),
                                const Spacer(),
                                Text('$done / $total',
                                    style: TStyle.mono(12, color: C.ink2)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: C.divider,
                                valueColor:
                                    const AlwaysStoppedAnimation(
                                        Color(0xFF34C759)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _CheckGrid(
                        label: '隨身行李',
                        icon: Icons.backpack_outlined,
                        items: carry,
                        iconMap: _carryIconMap,
                        checked: carryDone,
                        onToggle: _toggleCarry,
                      ),
                      const SizedBox(height: 12),
                      _CheckGrid(
                        label: '托運行李',
                        icon: Icons.luggage_outlined,
                        items: check,
                        iconMap: _checkIconMap,
                        checked: checkDone,
                        onToggle: _toggleCheck,
                      ),
                    ],
                  );
                },
                loading: () => Center(
                    child: CircularProgressIndicator(
                        color: C.accent, strokeWidth: 2)),
                error: (_, __) => const SizedBox.shrink(),
              ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sheet text field ─────────────────────────────────────────────────────────
class _SheetField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final TextInputType keyboardType;

  const _SheetField({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TStyle.sans(12, fw: FontWeight.w700, color: C.ink2)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: TStyle.sans(14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TStyle.sans(14, color: C.ink2.withValues(alpha: 0.4)),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: C.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: C.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: C.accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Check grid with icons ────────────────────────────────────────────────────
class _CheckGrid extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> items;
  final Map<String, IconData> iconMap;
  final Set<String> checked;
  final ValueChanged<String> onToggle;

  const _CheckGrid({
    required this.label,
    required this.icon,
    required this.items,
    required this.iconMap,
    required this.checked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final doneCount = items.where(checked.contains).length;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: C.ink2),
              const SizedBox(width: 7),
              Text(label,
                  style: TStyle.sans(13,
                      fw: FontWeight.w800, color: C.primary)),
              const Spacer(),
              Text('$doneCount/${items.length}',
                  style: TStyle.mono(11, color: C.ink2)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemCount: items.length,
            itemBuilder: (_, idx) {
              final item = items[idx];
              final done = checked.contains(item);
              final itemIcon = iconMap[item] ?? Icons.check_box_outline_blank;
              return GestureDetector(
                onTap: () => onToggle(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  decoration: BoxDecoration(
                    color: done
                        ? const Color(0xFF34C759).withValues(alpha: 0.12)
                        : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: done
                          ? const Color(0xFF34C759).withValues(alpha: 0.45)
                          : C.divider,
                      width: done ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        done ? Icons.check_circle_rounded : itemIcon,
                        size: 26,
                        color: done
                            ? const Color(0xFF34C759)
                            : C.ink2.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        item,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TStyle.sans(12,
                            fw: FontWeight.w700,
                            color: done ? C.ink2 : C.ink),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
