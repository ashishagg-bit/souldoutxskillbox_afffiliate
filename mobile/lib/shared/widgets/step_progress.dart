import 'package:flutter/material.dart';
import '../app_colors.dart';

/// Direct port of `shared/step-progress/step-progress.component.ts`.
class StepProgress extends StatelessWidget {
  final int total;
  final int current; // 1-indexed; this step and earlier are "done"

  const StepProgress({super.key, this.total = 4, required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: List.generate(total, (i) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
              height: 4,
              decoration: BoxDecoration(
                color: i < current ? AppColors.ink : AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
