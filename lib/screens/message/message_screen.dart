import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeerah/core/common/app_exports.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
String _myUid = '';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
    bool _isLoading = true;  

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

_loadMyChatId();

  }

  Future<void> _loadMyChatId() async {
  final prefs = await SharedPreferences.getInstance();

  _myUid =
      prefs.getString('my_chat_id') ?? '';

  debugPrint("========== MESSAGE SCREEN ==========");
  debugPrint("MY CHAT ID => $_myUid");
  debugPrint("====================================");

   if (mounted) {
      setState(() {
        _isLoading = false;  // 🔴 ADD THIS
      });
    }
}

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } else if (diff.inDays == 1) {
      return "Yesterday";
    } else {
      return "${dt.day}/${dt.month}";
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
 
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE53935)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Messages',
          style: GoogleFonts.poppins(
            color: const Color(0xFFE53935),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: _myUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint("Firestore Error: ${snapshot.error}");
                  return Center(child: Text("Error loading chats: ${snapshot.error}"));
                }

                final docs = snapshot.data?.docs ?? [];
                
                // Sort locally to avoid composite index requirement
                final sortedDocs = List<QueryDocumentSnapshot>.from(docs)
                  ..sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aTs = aData['lastTimestamp'] as Timestamp?;
                    final bTs = bData['lastTimestamp'] as Timestamp?;
                    if (aTs == null) return 1;
                    if (bTs == null) return -1;
                    return bTs.compareTo(aTs); // Descending
                  });

                // Filter locally if searching
                final filteredDocs = _searchQuery.isEmpty 
                  ? sortedDocs 
                  : sortedDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
       final name = (

    data['name'] ??

    data['providerName'] ??

    ''

).toString().toLowerCase();
                      return name.contains(_searchQuery.toLowerCase());
                    }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? "No active conversations" : "No results for '$_searchQuery'",
                          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  itemCount: filteredDocs.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    return _buildChatItem(context, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(Insets.md),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFFBDBDBD),
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFBDBDBD), size: 20),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18), 
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                }
              ) 
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, Map<String, dynamic> chat) {
final String name =

    chat['name'] ??

    chat['providerName'] ??

    "Professional";

final String image =

    chat['image'] ??

    chat['providerImage'] ??

    "";
    final String lastMsg = chat['lastMessage'] ?? "";
    final String time = _formatTime(chat['lastTimestamp'] as Timestamp?);
    final String bookingId = chat['bookingId']?.toString() ?? "";


    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.chatHomeScreen,
arguments: {

  'booking_id': bookingId,

  // CURRENT USER
  'my_chat_id': _myUid,

  // TARGET USER
  'provider_uid': chat['targetUid'],

  'target_chat_id': chat['targetUid'],

  // UI
  'name': name,

  'image': image,

  // TYPE
  'is_handyman_chat':
      chat['chatType'] == 'handyman',
}
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[200],
              backgroundImage: image.startsWith('http') ? NetworkImage(image) : null,
              child: !image.startsWith('http') ? const Icon(Icons.person, color: Colors.grey) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF212121),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMsg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF757575),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: GoogleFonts.poppins(
                color: const Color(0xFF9E9E9E),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
