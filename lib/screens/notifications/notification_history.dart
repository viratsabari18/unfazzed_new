import 'package:provider/provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/models/notification_item.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/services/notification_service.dart';

class NotificationHistory extends StatefulWidget {
  const NotificationHistory({super.key});

  @override
  State<NotificationHistory> createState() => _NotificationHistoryState();
}

class _NotificationHistoryState extends State<NotificationHistory> {
  final NotificationService _notificationService = NotificationService();
  String searchQuery = "";
  NotificationType? selectedFilter;
  final TextEditingController searchController = TextEditingController();

  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Using back-end user ID (customer_id)
    final response = await _notificationService.fetchNotificationList(
      customerId: userProvider.backendUserId ?? "166", 
      token: userProvider.apiToken,
    );

    if (mounted) {
      setState(() {
        _notifications = response['notification_data'] ?? [];
        _isLoading = false;
      });
    }
  }

  String _stripHtml(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), '').trim();
  }

  List<dynamic> getFiltered() {
    return _notifications.where((item) {
      final data = item['data'] ?? {};
      final title = data['notification-type']?.toString().replaceAll('_', ' ') ?? "Notification";
      final message = _stripHtml(data['message']?.toString() ?? "");
      final description = _stripHtml(data['description']?.toString() ?? "");
      
      final matchesSearch = title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          message.toLowerCase().contains(searchQuery.toLowerCase()) ||
          description.toLowerCase().contains(searchQuery.toLowerCase());
          
      return matchesSearch;
    }).toList();
  }

  Widget filterChip(String label, NotificationType? type) {
    final isSelected = selectedFilter == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: EdgeInsets.symmetric(horizontal: Insets.sm, vertical: Insets.xxs),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed : AppColors.naturalWhite,
          borderRadius: BorderRadius.circular(Insets.xs),
          border: Border.all(color: AppColors.primaryRed),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.naturalWhite : AppColors.primaryRed,
            fontSize: AppSizes.w(context, 12),
          ),
        ),
      ),
    );
  }

  Widget buildStatus(String type) {
    IconData icon;
    Color color;
    String label = type.replaceAll('_', ' ').toUpperCase();

    if (type.contains('cancel')) {
      icon = Icons.cancel_outlined;
      color = Colors.red;
    } else if (type.contains('accept')) {
      icon = Icons.check_circle_outline;
      color = Colors.green;
    } else if (type.contains('payment')) {
      icon = Icons.payment;
      color = Colors.blue;
    } else {
      icon = Icons.notifications_none;
      color = Colors.grey;
    }

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: AppSizes.w(context, 10), color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget notificationCard(dynamic item) {
    final data = item['data'] ?? {};
    final isRead = item['read_at'] != null;
    final time = item['created_at'] ?? "";
    final title = data['notification-type']?.toString().replaceAll('_', ' ').toUpperCase() ?? "NOTIFICATION";
    final message = _stripHtml(data['message']?.toString() ?? "");
    final description = _stripHtml(data['description']?.toString() ?? "");
    final typeStr = data['notification-type']?.toString() ?? "";

    return Container(
      margin: EdgeInsets.only(bottom: Insets.sm),
      padding: EdgeInsets.all(Insets.xsm),
      decoration: BoxDecoration(
        color: isRead ? AppColors.notificationCardBg : Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Insets.xsm),
        border: isRead ? null : Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: AppSizes.w(context, 22),
                backgroundColor: Colors.grey.shade200,
                backgroundImage: item['profile_image'] != null ? NetworkImage(item['profile_image']) : null,
                child: item['profile_image'] == null ? const Icon(Icons.person, color: Colors.grey) : null,
              ),
              if (!isRead)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    height: 10,
                    width: 10,
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          SizedBox(width: Insets.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(fontWeight: isRead ? FontWeight.w500 : FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    Text(time, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  ],
                ),
                const SizedBox(height: 4),
                buildStatus(typeStr),
                const SizedBox(height: 4),
                if (message.isNotEmpty)
                  Text(message, style: TextStyle(fontSize: AppSizes.w(context, 12), fontWeight: isRead ? FontWeight.normal : FontWeight.w600)),
                if (description.isNotEmpty)
                  Text(description, style: TextStyle(fontSize: AppSizes.w(context, 11), color: Colors.grey[600])),
                
                if (data['booking_id'] != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                       Navigator.pushNamed(
                        context, 
                        AppRoutes.bookingDetail,
                        arguments: data['booking_id'].toString(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "View Details",
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = getFiltered();

    return Scaffold(
      backgroundColor: AppColors.notificationBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.naturalWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryRed),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Notifications", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(Insets.xsm),
              child: Container(
                height: AppSizes.h(context, 40),
                padding: EdgeInsets.symmetric(horizontal: Insets.xs),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Insets.md),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: Colors.grey),
                    SizedBox(width: Insets.xxs),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: (val) {
                          setState(() {
                            searchQuery = val;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: UserMessages.searchNotifications,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                : list.isEmpty
                  ? const Center(
                      child: Text(
                        UserMessages.noNotificationsFound,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      color: AppColors.primaryRed,
                      child: ListView.builder(
                        padding: EdgeInsets.all(Insets.sm),
                        itemCount: list.length,
                        itemBuilder: (_, i) => notificationCard(list[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
