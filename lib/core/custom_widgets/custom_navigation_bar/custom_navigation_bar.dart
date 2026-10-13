import 'package:flutter/material.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';

class CustomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;

  const CustomNavigationBar({super.key, required this.currentIndex, required this.onTap, required this.items});

  @override
  Widget build(BuildContext context) {
    // No shadow wrapper here: a shadow on the transparent 78px box painted a grey band
    // behind the bar. The bar itself carries its own shadow.
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / items.length;

        return SizedBox(
          height: 78,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 64,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.white.withValues(alpha: 0.9), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.07),
                        blurRadius: 24,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.04),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 64,
                child: Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = currentIndex == index;

                    return SizedBox(
                      width: itemWidth,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(index),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutBack,
                              top: isSelected ? -18 : 10,
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutBack,
                                scale: isSelected ? 1 : 0.75,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 180),
                                  opacity: isSelected ? 1 : 0,
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [AppColors.yellowg, AppColors.primary],
                                      ),
                                      border: Border.all(color: AppColors.white.withValues(alpha: 0.9), width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.52),
                                          blurRadius: 14,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: AnimatedScale(
                                      duration: const Duration(milliseconds: 250),
                                      scale: isSelected ? 1 : 0.8,
                                      child: Center(
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: FittedBox(fit: BoxFit.contain, child: item.activeIcon),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              top: isSelected ? 42 : 19,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: isSelected ? 0 : 1,
                                child: Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: FittedBox(fit: BoxFit.contain, child: item.icon),
                                  ),
                                ),
                              ),
                            ),

                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              top: 42,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 220),
                                opacity: 1,
                                child: CustomText(
                                  text: item.label,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.grey800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class NavItem {
  final Widget icon;
  final Widget activeIcon;
  final String label;

  const NavItem({required this.icon, required this.activeIcon, required this.label});
}
