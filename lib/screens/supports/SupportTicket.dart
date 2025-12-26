import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// Models
enum TicketStatus { open, inProgress, resolved, closed }

enum TicketPriority { low, medium, high, urgent }

class SupportTicket {
  final String id;
  final String subject;
  final String category;
  final TicketStatus status;
  final TicketPriority priority;
  final String createdAt;
  final String lastReply;
  final List<TicketMessage> messages;

  SupportTicket({
    required this.id,
    required this.subject,
    required this.category,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.lastReply,
    required this.messages,
  });
}

class TicketMessage {
  final String id;
  final String sender; // 'user' or 'support'
  final String message;
  final String timestamp;
  final List<String>? attachments;

  TicketMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.timestamp,
    this.attachments,
  });
}

class SupportOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool available;
  final String responseTime;

  SupportOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.available,
    required this.responseTime,
  });
}

class FAQCategory {
  final String category;
  final List<FAQItem> questions;

  FAQCategory({required this.category, required this.questions});
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  // View state
  String _activeView = 'main'; // main, new-ticket, ticket-details, faq
  SupportTicket? _selectedTicket;
  String _newMessage = '';

  // New ticket form data
  final Map<String, dynamic> _ticketData = {
    'subject': '',
    'category': '',
    'priority': 'medium',
    'description': '',
  };

  // Support options
  final List<SupportOption> _supportOptions = [
    SupportOption(
      id: 'chat',
      title: 'Live Chat',
      description: 'Get instant help from our support team',
      icon: Iconsax.message,
      color: const Color(0xFF0a1866),
      bgColor: const Color(0xFFEFF6FF),
      available: true,
      responseTime: '< 2 minutes',
    ),
    SupportOption(
      id: 'email',
      title: 'Email Support',
      description: 'Send us a detailed message',
      icon: Iconsax.sms,
      color: const Color(0xFFF97316),
      bgColor: const Color(0xFFFEF3C7),
      available: true,
      responseTime: '< 4 hours',
    ),
    SupportOption(
      id: 'phone',
      title: 'Phone Support',
      description: 'Call us for urgent matters',
      icon: Iconsax.call,
      color: const Color(0xFF10B981),
      bgColor: const Color(0xFFECFDF5),
      available: false,
      responseTime: 'Mon-Fri 9AM-6PM',
    ),
  ];

  // FAQ categories
  final List<FAQCategory> _faqCategories = [
    FAQCategory(
      category: 'Account',
      questions: [
        FAQItem(
          question: 'How do I reset my password?',
          answer: 'Go to login page and click "Forgot Password"',
        ),
        FAQItem(
          question: 'How do I verify my account?',
          answer: 'Complete the verification steps in your profile',
        ),
        FAQItem(
          question: 'Can I change my phone number?',
          answer: 'Yes, update it in Profile > Security settings',
        ),
      ],
    ),
    FAQCategory(
      category: 'Groups',
      questions: [
        FAQItem(
          question: 'How do I join a group?',
          answer: 'Browse groups in Community tab and request to join',
        ),
        FAQItem(
          question: 'What happens if I miss a payment?',
          answer: 'A 2.5% penalty fee will be applied to your contribution',
        ),
        FAQItem(
          question: 'Can I leave a group early?',
          answer: 'Contact group admin or support for early exit options',
        ),
      ],
    ),
    FAQCategory(
      category: 'Payments',
      questions: [
        FAQItem(
          question: 'How do I add money to my wallet?',
          answer:
              'Use bank transfer, card payment, or USSD in Transactions tab',
        ),
        FAQItem(
          question: 'When do I receive my payout?',
          answer: 'Payouts are processed on your scheduled turn date',
        ),
        FAQItem(
          question: 'What banks do you support?',
          answer: 'We support all major Nigerian banks',
        ),
      ],
    ),
  ];

  // Sample tickets
  final List<SupportTicket> _tickets = [
    SupportTicket(
      id: '1',
      subject: 'Unable to make payment',
      category: 'Technical',
      status: TicketStatus.open,
      priority: TicketPriority.high,
      createdAt: '2 hours ago',
      lastReply: '1 hour ago',
      messages: [
        TicketMessage(
          id: '1',
          sender: 'user',
          message:
              'I\'m having trouble making a payment to my group. The app keeps showing an error.',
          timestamp: '2 hours ago',
        ),
        TicketMessage(
          id: '2',
          sender: 'support',
          message:
              'Hi! I\'m sorry to hear about this issue. Can you please tell me which payment method you\'re trying to use?',
          timestamp: '1 hour ago',
        ),
      ],
    ),
    SupportTicket(
      id: '2',
      subject: 'Group payout inquiry',
      category: 'Financial',
      status: TicketStatus.resolved,
      priority: TicketPriority.medium,
      createdAt: '1 day ago',
      lastReply: '4 hours ago',
      messages: [
        TicketMessage(
          id: '1',
          sender: 'user',
          message:
              'When will I receive my group payout? It\'s been 2 days since my turn.',
          timestamp: '1 day ago',
        ),
        TicketMessage(
          id: '2',
          sender: 'support',
          message:
              'Your payout has been processed and should reflect in your account within 24 hours. Reference: PAY123456',
          timestamp: '4 hours ago',
        ),
      ],
    ),
  ];

  // Helper methods
  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return const Color(0xFFF97316);
      case TicketStatus.inProgress:
        return const Color(0xFF0a1866);
      case TicketStatus.resolved:
        return const Color(0xFF10B981);
      case TicketStatus.closed:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.urgent:
        return Colors.red;
      case TicketPriority.high:
        return const Color(0xFFF97316);
      case TicketPriority.medium:
        return const Color(0xFF0a1866);
      case TicketPriority.low:
        return Colors.grey;
    }
  }

  String _getStatusText(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return 'open';
      case TicketStatus.inProgress:
        return 'in-progress';
      case TicketStatus.resolved:
        return 'resolved';
      case TicketStatus.closed:
        return 'closed';
    }
  }

  String _getPriorityText(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return 'low';
      case TicketPriority.medium:
        return 'medium';
      case TicketPriority.high:
        return 'high';
      case TicketPriority.urgent:
        return 'urgent';
    }
  }

  // View renderers
  Widget _renderMainView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Center(
            child: Column(
              children: [
                Text(
                  'How can we help?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0a1866),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Choose how you\'d like to get support',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Support Options
          Text(
            'Support Options',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),

          Column(
            children: _supportOptions.map((option) {
              return GestureDetector(
                onTap: option.available && option.id == 'email'
                    ? () => setState(() => _activeView = 'new-ticket')
                    : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: option.available
                          ? Colors.grey[200]!
                          : Colors.grey[100]!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: option.bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(option.icon, color: option.color),
                      ),

                      const SizedBox(width: 16),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  option.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                if (!option.available) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Offline',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              option.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Iconsax.clock,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  option.responseTime,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),

          // FAQ Button
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _activeView = 'faq'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Iconsax.message_question,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FAQ',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Find answers to common questions',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Iconsax.arrow_right_3,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Contact Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Other Ways to Reach Us',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Iconsax.sms, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'support@hoop.app',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Iconsax.call, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '+234 700 HOOP (4667)',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderNewTicketView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _activeView = 'main'),
                icon: const Icon(Iconsax.arrow_left),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Support Ticket',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0a1866),
                    ),
                  ),
                  Text(
                    'Tell us about your issue',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Form
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Dropdown
              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _ticketData['category'].isEmpty
                        ? null
                        : _ticketData['category'],
                    hint: const Text('Select category'),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'technical',
                        child: Text('Technical Issue'),
                      ),
                      DropdownMenuItem(
                        value: 'financial',
                        child: Text('Financial/Payment'),
                      ),
                      DropdownMenuItem(
                        value: 'account',
                        child: Text('Account Related'),
                      ),
                      DropdownMenuItem(
                        value: 'group',
                        child: Text('Group Management'),
                      ),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _ticketData['category'] = value!;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Priority Dropdown
              const Text(
                'Priority',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _ticketData['priority'],
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _ticketData['priority'] = value!;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Subject
              const Text(
                'Subject',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Brief description of your issue',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _ticketData['subject'] = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Description
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Provide detailed information about your issue...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _ticketData['description'] = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Attachment hint
              Row(
                children: [
                  const Icon(Iconsax.paperclip, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Attach files (optional)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle ticket submission
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ticket submitted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    setState(() => _activeView = 'main');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0a1866),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.send_2, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Submit Ticket',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _renderTicketDetailsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _activeView = 'main'),
                icon: const Icon(Iconsax.arrow_left),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support Tickets',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0a1866),
                    ),
                  ),
                  Text(
                    'Your support history',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Tickets list
          Column(
            children: _tickets.map((ticket) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket.subject,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ticket.category,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(ticket.status),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _getStatusText(ticket.status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_getPriorityText(ticket.priority)} priority',
                                    style: TextStyle(
                                      color: _getPriorityColor(ticket.priority),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              ticket.createdAt,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Last reply: ${ticket.lastReply}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Colors.grey),
                    const SizedBox(height: 12),

                    // Last message preview
                    Text(
                      ticket.messages.last.message,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _renderFAQView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _activeView = 'main'),
                icon: const Icon(Iconsax.arrow_left),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0a1866),
                    ),
                  ),
                  Text(
                    'Quick answers to common questions',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // FAQ Categories
          Column(
            children: _faqCategories.map((category) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0a1866),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: category.questions.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.question,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.answer,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Contact support button
          Center(
            child: Column(
              children: [
                Text(
                  'Didn\'t find what you\'re looking for?',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _activeView = 'new-ticket'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0a1866),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Contact Support',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 24.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _activeView == 'new-ticket'
              ? _renderNewTicketView()
              : _activeView == 'ticket-details'
              ? _renderTicketDetailsView()
              : _activeView == 'faq'
              ? _renderFAQView()
              : _renderMainView(),
        ),
      ),
    );
  }
}
