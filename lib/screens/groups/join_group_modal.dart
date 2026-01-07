import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/primary_button.dart';

class JoinGroupModal {
  static void show({
    required BuildContext context,
    required Map<String, dynamic> group,
    required Function(int slots, String message) onJoin,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, controller) {
            return _JoinGroupContent(
              group: group,
              controller: controller,
              onJoin: onJoin,
            );
          },
        );
      },
    );
  }
}

class _JoinGroupContent extends StatefulWidget {
  final Map<String, dynamic> group;
  final ScrollController controller;
  final Function(int slots, String message) onJoin;

  const _JoinGroupContent({
    required this.group,
    required this.controller,
    required this.onJoin,
  });

  @override
  State<_JoinGroupContent> createState() => _JoinGroupContentState();
}

class _JoinGroupContentState extends State<_JoinGroupContent> {
  late double selectedSlots;
  late double minSelectableSlots;
  late double maxSelectableSlots;
  String message = '';
  bool showMessageBox = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    
    final bool allowPairing = widget.group['allowPairing'] ?? false;
    final int availableSlots = widget.group['availableSlots'] ?? 1;
    final int maxSlotsPerUser = widget.group['maxSlotsPerUser'] ?? 1;
    
    minSelectableSlots = allowPairing ? 0.5 : 1.0;
    maxSelectableSlots = (availableSlots < maxSlotsPerUser 
        ? availableSlots 
        : maxSlotsPerUser).toDouble();
    selectedSlots = minSelectableSlots;
  }

  double get totalContribution {
    final contributionAmount = widget.group['contributionAmount'] ?? 0;
    return selectedSlots * contributionAmount;
  }

  void handleSlotIncrement() {
    final bool allowPairing = widget.group['allowPairing'] ?? false;
    final increment = allowPairing ? 0.5 : 1.0;
    
    if (selectedSlots + increment <= maxSelectableSlots) {
      setState(() {
        selectedSlots += increment;
      });
    }
  }

  void handleSlotDecrement() {
    final bool allowPairing = widget.group['allowPairing'] ?? false;
    final decrement = allowPairing ? 0.5 : 1.0;
    
    if (selectedSlots - decrement >= minSelectableSlots) {
      setState(() {
        selectedSlots -= decrement;
      });
    }
  }

  Future<void> handleJoinGroup() async {
    setState(() => isLoading = true);
    
    try {
      await widget.onJoin(selectedSlots.toInt(), message);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool allowPairing = widget.group['allowPairing'] ?? false;
    final contributionAmount = widget.group['contributionAmount'] ?? 0;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D27) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        controller: widget.controller,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Join Group',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Slot Selection Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Slots',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (allowPairing)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withOpacity(0.2),
                          ),
                        ),
                        child: const Text(
                          'Pairing allowed • 0.5 increments',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Slot Counter
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F111A).withOpacity(0.5)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Decrement Button
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey[300]!,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              onPressed: (selectedSlots <= minSelectableSlots || isLoading)
                                  ? null
                                  : handleSlotDecrement,
                              icon: const Icon(Icons.remove, size: 18),
                              color: (selectedSlots <= minSelectableSlots || isLoading)
                                  ? Colors.grey
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),

                          // Slot Display
                          Column(
                            children: [
                              Text(
                                selectedSlots.toString(),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                              Text(
                                'slot${selectedSlots != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),

                          // Increment Button
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey[300]!,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              onPressed: (selectedSlots >= maxSelectableSlots || isLoading)
                                  ? null
                                  : handleSlotIncrement,
                              icon: const Icon(Icons.add, size: 18),
                              color: (selectedSlots >= maxSelectableSlots || isLoading)
                                  ? Colors.grey
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Min/Max Labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Min: $minSelectableSlots',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          Text(
                            'Max: $maxSelectableSlots',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Total Contribution Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF16A34A).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Contribution',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            '₦${totalContribution.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '$selectedSlots slot${selectedSlots != 1 ? 's' : ''} × ₦${contributionAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Optional Message Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Message (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => setState(() => showMessageBox = !showMessageBox),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: Text(
                        showMessageBox ? 'Remove' : 'Add Message',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                if (showMessageBox) ...[
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (value) => setState(() => message = value),
                    enabled: !isLoading,
                    maxLength: 500,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Introduce yourself or share why you want to join this group...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF3B82F6),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Optional message to group admin',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      Text(
                        '${message.length}/500',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child:HoopButton(
                    isLoading: isLoading,
                    
                    buttonText: 'Join Group • ₦${totalContribution.toStringAsFixed(0)}',
                    onPressed: isLoading ? null : handleJoinGroup,
                  ), 
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? Colors.white12 : Colors.grey[300]!,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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