import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as s;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'info_screen.dart' show PageHeader;

// ─── Models ───────────────────────────────────────────────────────────────────
class ShopItem {
  String name;
  int qty;
  bool bought;
  int? amount; // price in KRW
  String? photoPath; // local file path from image_picker

  ShopItem({
    required this.name,
    this.qty = 1,
    this.bought = false,
    this.amount,
    this.photoPath,
  });

  factory ShopItem.fromJson(Map<String, dynamic> j) => ShopItem(
        name: j['name'] ?? '',
        qty: j['qty'] ?? 1,
        bought: j['bought'] ?? false,
        amount: j['amount'] as int?,
        photoPath: j['photoPath'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'qty': qty,
        'bought': bought,
        if (amount != null) 'amount': amount,
        if (photoPath != null) 'photoPath': photoPath,
      };
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final _souvenirDataProvider = FutureProvider<List<dynamic>>((ref) async {
  final raw = await s.rootBundle.loadString('assets/data/souvenirs.json');
  return jsonDecode(raw) as List<dynamic>;
});

// ─── Screen ───────────────────────────────────────────────────────────────────
class SouvenirScreen extends ConsumerStatefulWidget {
  final List<String> members;

  const SouvenirScreen({super.key, required this.members});

  @override
  ConsumerState<SouvenirScreen> createState() => _SouvenirScreenState();
}

class _SouvenirScreenState extends ConsumerState<SouvenirScreen> {
  late String _curUser;
  Map<String, List<ShopItem>> _lists = {};
  ImagePicker? _picker;

  @override
  void initState() {
    super.initState();
    _curUser =
        widget.members.isNotEmpty ? widget.members.first : 'Kerwin';
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> all = {};
    try {
      final raw = prefs.getString('shopping_list') ?? '{}';
      all = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      await prefs.remove('shopping_list');
    }
    if (!mounted) return;
    setState(() {
      _lists = {
        for (final u in widget.members)
          u: (all[u] as List<dynamic>?)
                  ?.map((e) =>
                      ShopItem.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
      };
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'shopping_list',
        jsonEncode(
            {for (final e in _lists.entries) e.key: e.value.map((i) => i.toJson()).toList()}));
  }

  void _showAddSheet({ShopItem? existing, int? editIndex}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final amountCtrl = TextEditingController(
        text: existing?.amount != null ? '${existing!.amount}' : '');
    String? photoPath = existing?.photoPath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: C.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(existing == null ? '新增代購' : '編輯代購',
                    style: TStyle.serifTitle(18)),
                const SizedBox(height: 16),
                // Photo picker
                GestureDetector(
                  onTap: () async {
                    _picker ??= ImagePicker();
                    final xfile = await _picker!.pickImage(
                        source: ImageSource.gallery, imageQuality: 80);
                    if (xfile != null) {
                      setSheet(() => photoPath = xfile.path);
                    }
                  },
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: C.divider),
                      image: photoPath != null
                          ? DecorationImage(
                              image: FileImage(File(photoPath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: photoPath == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 28,
                                  color: C.ink2.withValues(alpha: 0.5)),
                              const SizedBox(height: 6),
                              Text('從相簿選擇照片',
                                  style: TStyle.sans(13, color: C.ink2)),
                            ],
                          )
                        : Align(
                            alignment: Alignment.topRight,
                            child: GestureDetector(
                              onTap: () => setSheet(() => photoPath = null),
                              child: Container(
                                margin: const EdgeInsets.all(6),
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                // Name field
                _SouvenirField(
                    ctrl: nameCtrl, label: '商品名稱', hint: '例：海苔餅乾'),
                const SizedBox(height: 12),
                // Amount field
                _SouvenirField(
                  ctrl: amountCtrl,
                  label: '金額（韓幣）',
                  hint: '例：5000',
                  keyboardType: TextInputType.number,
                  prefix: '₩ ',
                ),
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
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      final amount = int.tryParse(amountCtrl.text.trim());
                      setState(() {
                        if (editIndex != null && existing != null) {
                          existing.name = name;
                          existing.amount = amount;
                          existing.photoPath = photoPath;
                        } else {
                          _lists[_curUser] ??= [];
                          _lists[_curUser]!.add(ShopItem(
                            name: name,
                            amount: amount,
                            photoPath: photoPath,
                          ));
                        }
                      });
                      _save();
                      Navigator.pop(ctx);
                    },
                    child: Text(existing == null ? '新增' : '儲存',
                        style: TStyle.sans(15,
                            fw: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggle(int i) {
    HapticFeedback.selectionClick();
    setState(() => _lists[_curUser]![i].bought = !_lists[_curUser]![i].bought);
    _save();
  }

  void _delete(int i) {
    setState(() => _lists[_curUser]!.removeAt(i));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final souvenirs = ref.watch(_souvenirDataProvider);
    final items = _lists[_curUser] ?? [];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: const PageHeader(title: '伴手禮'),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 0, 20,
              MediaQuery.of(context).padding.bottom + 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── 代購清單 ────────────────────────────────────
              SectionTitle('代購清單', icon: Icons.shopping_bag_outlined),
              // User tabs
              UserTabRow(
                users: widget.members,
                selected: _curUser,
                onSelect: (u) => setState(() => _curUser = u),
              ),
              const SizedBox(height: 14),
              // Add button
              GestureDetector(
                onTap: () => _showAddSheet(),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 13),
                  radius: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 18, color: C.accent),
                      const SizedBox(width: 8),
                      Text('新增代購項目',
                          style: TStyle.sans(14,
                              fw: FontWeight.w700, color: C.accent)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // List
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('尚無代購項目',
                        style: TStyle.sans(13, color: C.ink2)),
                  ),
                ),
              ...items.asMap().entries.map((e) {
                final i = e.key;
                final item = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SwipeToDelete(
                    key: ValueKey('shop_${_curUser}_$i'),
                    onDelete: () => _delete(i),
                    onEdit: () =>
                        _showAddSheet(existing: item, editIndex: i),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      radius: 14,
                      tint: item.bought
                          ? const Color(0xCCE8F5E9)
                          : const Color(0xBEFFFFFF),
                      child: Row(
                        children: [
                          // Photo thumbnail or checkbox
                          GestureDetector(
                            onTap: () => _toggle(i),
                            child: item.photoPath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Stack(
                                      children: [
                                        Image.file(
                                          File(item.photoPath!),
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                        ),
                                        if (item.bought)
                                          Container(
                                            width: 48,
                                            height: 48,
                                            color: Colors.black38,
                                            child: const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 22),
                                          ),
                                      ],
                                    ),
                                  )
                                : AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: item.bought
                                          ? const Color(0xFF34C759)
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: item.bought
                                            ? const Color(0xFF34C759)
                                            : C.divider,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: item.bought
                                        ? const Icon(Icons.check_rounded,
                                            size: 15, color: Colors.white)
                                        : null,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: TStyle.sans(14,
                                      fw: FontWeight.w700,
                                      color: item.bought ? C.ink2 : C.ink),
                                ),
                                if (item.amount != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '₩ ${_fmtNum(item.amount!)}',
                                    style: TStyle.mono(12, color: C.accent),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Qty control
                          Row(
                            children: [
                              _QtyBtn(
                                icon: Icons.remove_rounded,
                                onTap: () {
                                  if (item.qty > 1) {
                                    HapticFeedback.lightImpact();
                                    setState(() => item.qty--);
                                    _save();
                                  }
                                },
                              ),
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${item.qty}',
                                  textAlign: TextAlign.center,
                                  style: TStyle.mono(14, color: C.ink),
                                ),
                              ),
                              _QtyBtn(
                                icon: Icons.add_rounded,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => item.qty++);
                                  _save();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 28),
              // ── 伴手禮總覽 ───────────────────────────────────
              SectionTitle('伴手禮推薦', icon: Icons.card_giftcard_rounded),
              souvenirs.when(
                data: (list) => Column(
                  children: list
                      .map((r) =>
                          _SouvenirRegion(data: r as Map<String, dynamic>))
                      .toList(),
                ),
                loading: () => Center(child: CircularProgressIndicator(color: C.accent, strokeWidth: 2)),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

String _fmtNum(int n) {
  // Format with thousands separator
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

// ─── Souvenir sheet field ─────────────────────────────────────────────────────
class _SouvenirField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final String? prefix;

  const _SouvenirField({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.prefix,
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
            prefixText: prefix,
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

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: C.primary),
      ),
    );
  }
}

// ─── Souvenir region ──────────────────────────────────────────────────────────
class _SouvenirRegion extends StatelessWidget {
  final Map<String, dynamic> data;

  const _SouvenirRegion({required this.data});

  @override
  Widget build(BuildContext context) {
    final region = data['region'] ?? '';
    final items = (data['items'] as List<dynamic>?) ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: C.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(region,
                    style: TStyle.serifTitle(14, color: C.primary)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                final i = item as Map<String, dynamic>;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F3EE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: C.divider),
                  ),
                  child: Text(
                    i['name'] ?? '',
                    style: TStyle.sans(13, fw: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
