import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/constants.dart';
import '../../models/mind_orb.dart';
import '../../viewmodels/orb_provider.dart';

Future<void> showOrbDetailDialog(BuildContext context, MindOrb orb) {
  return showDialog<void>(
    context: context,
    builder: (context) => OrbDetailDialog(orb: orb),
  );
}

Future<bool> confirmAndDeleteOrb(BuildContext context, MindOrb orb) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('收回這顆心球？'),
        content: Text('「${orb.title}」會從這台裝置刪除，無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('收回'),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) return false;
  await context.read<OrbProvider>().deleteOrb(orb.id);
  return true;
}

class OrbDetailDialog extends StatelessWidget {
  const OrbDetailDialog({super.key, required this.orb});

  final MindOrb orb;

  @override
  Widget build(BuildContext context) {
    final color = orb.emotion.color;
    final cloudEnabled = context.watch<OrbProvider>().cloudEnabled;
    final releaseLabel = switch ((orb.isPublic, cloudEnabled)) {
      (true, true) => '已在大眾星海',
      (true, false) => '已標記放流，雲端接通後送出',
      (false, _) => '只留在個人星系',
    };

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.8),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${orb.emotion.label} · ${orb.emotion.body}',
                      style: TextStyle(color: color, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                orb.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatOrbTime(orb.createdAt),
                style: TextStyle(
                  color: AppColors.starlightWhite.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                orb.content.isEmpty ? '（沒有內文）' : orb.content,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                releaseLabel,
                style: TextStyle(
                  color: AppColors.starlightWhite.withValues(alpha: 0.8),
                ),
              ),
              if (orb.hugCount > 0) ...[
                const SizedBox(height: 6),
                Text('星光 ${orb.hugCount}'),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      final deleted = await confirmAndDeleteOrb(context, orb);
                      if (deleted && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('收回'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('關閉'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
