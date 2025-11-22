import 'package:flutter/material.dart';
import '../models/enums/user_type.dart';

class UserTypeToggle extends StatelessWidget {
  final UserType selectedType;
  final ValueChanged<UserType> onTypeChanged;
  final Color toggleColor;

  const UserTypeToggle({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    this.toggleColor = const Color.fromARGB(255, 101, 150, 255),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: SizedBox(
        width: 280,
        height: 52,
        child: Stack(
          children: [
            // 1. Background Track & Text Labels
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: AnimatedScale(
                        scale: selectedType == UserType.seeker ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutCubicEmphasized,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubicEmphasized,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 15,
                            fontWeight: selectedType == UserType.seeker 
                                ? FontWeight.w800 
                                : FontWeight.w600,
                            color: selectedType == UserType.seeker
                                ? theme.primaryColor
                                : Colors.grey.shade500,
                            letterSpacing: 0.3,
                          ),
                          child: const Text('Seeker'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: AnimatedScale(
                        scale: selectedType == UserType.company ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutCubicEmphasized,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubicEmphasized,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 15,
                            fontWeight: selectedType == UserType.company 
                                ? FontWeight.w800 
                                : FontWeight.w600,
                            color: selectedType == UserType.company
                                ? theme.primaryColor
                                : Colors.grey.shade500,
                            letterSpacing: 0.3,
                          ),
                          child: const Text('Company'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Glass Indicator (Custom Implementation)
            AnimatedAlign(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubicEmphasized,
              alignment: selectedType == UserType.seeker
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Container(
                  width: 136,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: toggleColor.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: toggleColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        toggleColor.withValues(alpha: 0.15),
                        toggleColor.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Touch Handlers
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => onTypeChanged(UserType.seeker),
                    child: const SizedBox(height: 52),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => onTypeChanged(UserType.company),
                    child: const SizedBox(height: 52),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
