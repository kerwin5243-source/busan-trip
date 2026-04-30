import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/itinerary_item.dart';
import '../providers/trip_provider.dart';
import '../theme/app_theme.dart';

class EditItemSheet extends ConsumerStatefulWidget {
  final ItineraryItem item;
  final String date;

  const EditItemSheet({super.key, required this.item, required this.date});

  @override
  ConsumerState<EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends ConsumerState<EditItemSheet> {
  late final TextEditingController _time;
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _detail;
  late final TextEditingController _addr;
  late final TextEditingController _hours;
  late final TextEditingController _price;
  late final TextEditingController _stay;
  late final TextEditingController _parking;
  late final TextEditingController _mapcode;
  late ItemTag _tag;
  late String _subtag;
  late bool _highlight;
  late bool _reserved;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _time = TextEditingController(text: i.time);
    _title = TextEditingController(text: i.title);
    _desc = TextEditingController(text: i.desc);
    _detail = TextEditingController(text: i.detail);
    _addr = TextEditingController(text: i.addr);
    _hours = TextEditingController(text: i.hours);
    _price = TextEditingController(text: i.price);
    _stay = TextEditingController(text: i.stay);
    _parking = TextEditingController(text: i.parking);
    _mapcode = TextEditingController(text: i.mapcode);
    _tag = i.tag;
    _subtag = i.subtag;
    _highlight = i.highlight;
    _reserved = i.reserved;
  }

  @override
  void dispose() {
    for (final c in [
      _time, _title, _desc, _detail, _addr, _hours, _price, _stay, _parking, _mapcode
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final updated = widget.item.copyWith(
      time: _time.text.trim(),
      title: _title.text.trim(),
      desc: _desc.text.trim(),
      detail: _detail.text.trim(),
      addr: _addr.text.trim(),
      hours: _hours.text.trim(),
      price: _price.text.trim(),
      stay: _stay.text.trim(),
      parking: _parking.text.trim(),
      mapcode: _mapcode.text.trim(),
      tag: _tag,
      subtag: _subtag,
      highlight: _highlight,
      reserved: _reserved,
    );
    ref.read(tripProvider.notifier).updateItem(widget.date, updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHandle(),
          _SheetTitle(onSave: _save),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TagSelector(
                    selected: _tag,
                    onChanged: (t) => setState(() => _tag = t),
                  ),
                  const SizedBox(height: 16),
                  _FieldRow(
                    children: [
                      _Field('時間', _time, hint: '09:00'),
                      _Field('停留', _stay, hint: '1 hr'),
                    ],
                  ),
                  _Field('標題', _title, hint: '景點/活動名稱', required: true),
                  _Field('子標籤', TextEditingController(text: _subtag),
                      hint: '神社・餐廳・交通…',
                      onChanged: (v) => setState(() => _subtag = v)),
                  _Field('簡介', _desc, hint: '一行描述', maxLines: 2),
                  _Field('詳細說明', _detail,
                      hint: '注意事項、步驟、特色…', maxLines: 4),
                  _Field('地址', _addr, hint: '完整地址'),
                  _FieldRow(
                    children: [
                      _Field('營業時間', _hours, hint: '09:00–18:00'),
                      _Field('費用', _price, hint: '₩10,000'),
                    ],
                  ),
                  _FieldRow(
                    children: [
                      _Field('停車', _parking, hint: '停車場說明'),
                      _Field('Mapcode', _mapcode, hint: '000 000 000*00'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _Toggles(
                    highlight: _highlight,
                    reserved: _reserved,
                    onHighlight: (v) => setState(() => _highlight = v),
                    onReserved: (v) => setState(() => _reserved = v),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  final VoidCallback onSave;

  const _SheetTitle({required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
      child: Row(
        children: [
          const Text(
            '編輯行程',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }
}

class _TagSelector extends StatelessWidget {
  final ItemTag selected;
  final ValueChanged<ItemTag> onChanged;

  const _TagSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('類型',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: ItemTag.values
              .where((t) => t != ItemTag.route)
              .map(
                (t) => GestureDetector(
                  onTap: () => onChanged(t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected == t
                          ? tagColor(t)
                          : tagColor(t).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tagIcon(t),
                          size: 13,
                          color: selected == t
                              ? Colors.white
                              : tagColor(t),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          t.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected == t
                                ? Colors.white
                                : tagColor(t),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final bool required;
  final ValueChanged<String>? onChanged;

  const _Field(
    this.label,
    this.controller, {
    this.hint,
    this.maxLines = 1,
    this.required = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              if (required)
                const Text(' *',
                    style: TextStyle(color: AppColors.accent, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14, color: Color(0xFF2C2C4E)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primaryLight, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final List<Widget> children;

  const _FieldRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children
          .expand((w) => [Expanded(child: w), const SizedBox(width: 12)])
          .take(children.length * 2 - 1)
          .toList(),
    );
  }
}

class _Toggles extends StatelessWidget {
  final bool highlight;
  final bool reserved;
  final ValueChanged<bool> onHighlight;
  final ValueChanged<bool> onReserved;

  const _Toggles({
    required this.highlight,
    required this.reserved,
    required this.onHighlight,
    required this.onReserved,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Toggle(
            label: '重點行程',
            icon: Icons.star_outline,
            value: highlight,
            activeColor: AppColors.accent,
            onChanged: onHighlight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Toggle(
            label: '已預訂',
            icon: Icons.bookmark_outline,
            value: reserved,
            activeColor: AppColors.primaryLight,
            onChanged: onReserved,
          ),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _Toggle({
    required this.label,
    required this.icon,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value ? activeColor.withOpacity(0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value ? activeColor : Colors.grey[300]!,
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: value ? activeColor : Colors.grey[400]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: value ? activeColor : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
