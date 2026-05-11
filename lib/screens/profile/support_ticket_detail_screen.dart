import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/services/helpdesk_service.dart';

class SupportTicketDetailScreen extends StatefulWidget {
  final String ticketId;
  const SupportTicketDetailScreen({super.key, required this.ticketId});

  @override
  State<SupportTicketDetailScreen> createState() => _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState extends State<SupportTicketDetailScreen> {
  final HelpDeskService _helpDeskService = HelpDeskService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  
  Map<String, dynamic>? _ticketData;
  bool _isLoading = true;
  bool _isSending = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadTicketDetail();
  }

  Future<void> _loadTicketDetail() async {
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final detail = await _helpDeskService.fetchTicketDetail(
      widget.ticketId, 
      token: userProvider.apiToken,
    );
    if (mounted) {
      setState(() {
        _ticketData = detail;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    setState(() => _isSending = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    final success = await _helpDeskService.addMessage(
      ticketId: widget.ticketId,
      description: text,
      token: userProvider.apiToken,
      attachment: _selectedImage,
    );

    if (mounted) {
      setState(() {
        _isSending = false;
        if (success) {
          _messageController.clear();
          _selectedImage = null;
        }
      });
      if (success) {
        _loadTicketDetail(); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    }
  }

  Future<void> _closeTicket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Ticket'),
        content: const Text('Are you sure you want to close this ticket?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await _helpDeskService.closeTicket(
        widget.ticketId, 
        token: userProvider.apiToken,
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket closed')));
          _loadTicketDetail();
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to close ticket')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = (_ticketData?['status'] ?? '').toString().toLowerCase() == 'closed';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _ticketData?['subject'] ?? 'Ticket Detail',
              style: GoogleFonts.poppins(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'ID: #${widget.ticketId}',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (!isClosed && !_isLoading)
            TextButton(
              onPressed: _closeTicket,
              child: const Text('Close', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildTicketInfo(),
                      const Divider(height: 32),
                      ..._buildActivities(),
                    ],
                  ),
                ),
                if (!isClosed) _buildInputArea(),
              ],
            ),
    );
  }

  Widget _buildTicketInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Original Query', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
            _buildStatusBadge(),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _ticketData?['description'] ?? '',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
        ),
        if (_ticketData?['helpdesk_attachment'] != null && _ticketData!['helpdesk_attachment'].isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(_ticketData!['helpdesk_attachment'], height: 150, fit: BoxFit.cover),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final status = (_ticketData?['status'] ?? 'open').toString().toUpperCase();
    final isOpen = status == 'OPEN';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: isOpen ? Colors.green : Colors.grey),
      ),
    );
  }

  List<Widget> _buildActivities() {
    final List<dynamic> activities = _ticketData?['helpdesk_activity'] ?? [];
    return activities.map((activity) {
      final isCustomer = activity['mode'] == 'app'; // Assuming 'app' means customer
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: isCustomer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCustomer ? AppColors.primaryRed.withOpacity(0.05) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isCustomer ? AppColors.primaryRed.withOpacity(0.1) : Colors.transparent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity['description'] ?? '', style: GoogleFonts.poppins(fontSize: 13)),
                  if (activity['helpdesk_activity_attachment'] != null && activity['helpdesk_activity_attachment'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(activity['helpdesk_activity_attachment'], height: 100, fit: BoxFit.cover),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(activity['created_at'] ?? '', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 8, 
        bottom: MediaQuery.of(context).padding.bottom + 8
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_selectedImage!, height: 60, width: 60, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: -5, right: -5,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImage = null),
                          child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(onPressed: _pickImage, icon: const Icon(Icons.image_outlined, color: AppColors.primaryRed)),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(25)),
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Type a message...', border: InputBorder.none, hintStyle: TextStyle(fontSize: 14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _isSending
                ? const SizedBox(width: 40, height: 40, child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
                : CircleAvatar(
                    backgroundColor: AppColors.primaryRed,
                    child: IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send, color: Colors.white, size: 18)),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
