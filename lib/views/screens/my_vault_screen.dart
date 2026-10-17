import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/constants.dart';
import '../../viewmodels/orb_provider.dart';
import '../widgets/orb_detail_dialog.dart';

class MyVaultScreen extends StatelessWidget {
  const MyVaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrbProvider>();
    final orbs = provider.orbs;

    return Scaffold(
      backgroundColor: AppColors.spaceBlack,
      appBar: AppBar(title: const Text('個人記憶庫')),
      body: !provider.isReady
          ? const Center(child: Text('正在打開星海…'))
          : orbs.isEmpty
          ? const Center(
              child: Text(
                '記憶庫還是空的',
                style: TextStyle(color: AppColors.starlightWhite),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: orbs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final orb = orbs[index];
                final color = orb.emotion.color;
                return Material(
                  color: AppColors.deepCharcoal,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => showOrbDetailDialog(context, orb),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withValues(alpha: 0.75)),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.8),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  orb.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${orb.emotion.label} · ${formatOrbTime(orb.createdAt)}',
                                  style: TextStyle(
                                    color: AppColors.starlightWhite.withValues(
                                      alpha: 0.75,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: '收回',
                            onPressed: () => confirmAndDeleteOrb(context, orb),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
