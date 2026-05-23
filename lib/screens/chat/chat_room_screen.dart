import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zeerah/core/common/app_exports.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String _bookingId = '';

  String _providerName = 'Professional';

  String _providerImage = '';

  String? _providerPhone;

  String _targetChatId = '';

  String _myUid = '';

  final String _myName =
      FirebaseAuth.instance.currentUser
          ?.displayName ??
      'Customer';

  bool _initialized = false;

  bool _isHandymanChat = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {

      _initialized = true;

      final args =
          ModalRoute.of(context)
              ?.settings
              .arguments
          as Map<String, dynamic>?;

      if (args != null) {

        setState(() {

          _isHandymanChat =
              args['is_handyman_chat'] ==
                  true;

          _bookingId =
              args['booking_id']
                      ?.toString() ??

                  args['bookingId']
                      ?.toString() ??

                  (args['booking_data']
                              ?['booking_detail']
                          ?['id']
                      ?.toString() ??
                      'default');

          _providerName =
              args['name'] ??
                  args['provider_name'] ??
                  'Professional';

          _providerImage =
              args['image'] ??
                  args['provider_image'] ??
                  '';

          _providerPhone =
              args['phone']
                      ?.toString() ??
                  args['contact_number']
                      ?.toString();

          _myUid =
              args['my_chat_id']
                      ?.toString() ??
                  '';

          _targetChatId =
              args['provider_uid']
                      ?.toString() ??

                  args['handyman_uid']
                      ?.toString() ??

                  args['target_chat_id']
                      ?.toString() ??

                  '';
        });

        debugPrint(
            "========== CHAT DEBUG ==========");

        debugPrint(
            "Booking ID => $_bookingId");

        debugPrint(
            "Provider Name => $_providerName");

        debugPrint(
            "Provider UID => $_targetChatId");

        debugPrint(
            "My UID => $_myUid");

        debugPrint(
            "Is Handyman Chat => $_isHandymanChat");

        debugPrint(
            "Chat Room ID => $_chatRoomId");

        debugPrint(
            "================================");
      }
    }
  }

  String get _chatRoomId {

    return 'booking_${_bookingId}_$_targetChatId';
  }

  CollectionReference get _messagesRef =>
      _firestore

          .collection('chats')

          .doc(_chatRoomId)

          .collection('messages');

  Future<void> _sendMessage() async {

    final text =
        _controller.text.trim();

    if (text.isEmpty) return;

    _controller.clear();

    debugPrint(
        "========== SEND MESSAGE ==========");

    debugPrint(
        "Room ID => $_chatRoomId");

    debugPrint(
        "Sender ID => $_myUid");

    debugPrint(
        "Target Chat ID => $_targetChatId");

    debugPrint(
        "Booking ID => $_bookingId");

    debugPrint(
        "Is Handyman Chat => $_isHandymanChat");

    debugPrint(
        "Message => $text");

    debugPrint(
        "==================================");

    try {

      final messageRef =
          _messagesRef.doc();

      final messageData = {

        'messageId':
            messageRef.id,

        // ✅ NEW FORMAT
        'message': text,

        // ✅ OLD FORMAT SUPPORT
        'text': text,

        'senderId': _myUid,

        'senderName': _myName,

        'receiverId':
            _targetChatId,

        'bookingId':
            _bookingId,

        'participants': [
          _myUid,
          _targetChatId,
        ],

        'timestamp':
            FieldValue.serverTimestamp(),

        'isRead': false,

        'isDelivered': false,
      };

      await messageRef.set(
          messageData);

      debugPrint(
          "✅ Message sent successfully: ${messageRef.id}");

      final chatRoomRef =
          _firestore

              .collection('chats')

              .doc(_chatRoomId);

      final chatRoomData = {

        'bookingId':
            _bookingId,

        'chatRoomId':
            _chatRoomId,

        'chatType':
            _isHandymanChat
                ? 'handyman'
                : 'provider',

        'receiverId':
            _targetChatId,

        'targetUid':
            _targetChatId,

        'lastMessage':
            text,

        'lastMessageTime':
            FieldValue.serverTimestamp(),

        'lastTimestamp':
            FieldValue.serverTimestamp(),

        'lastMessageSenderId':
            _myUid,

        'participants': [
          _myUid,
          _targetChatId,
        ],

        'providerName':
            _providerName,

        'providerImage':
            _providerImage,

        'updatedAt':
            FieldValue.serverTimestamp(),
      };

      debugPrint(
          "========== CHAT ROOM SAVE ==========");

      debugPrint(
          "CHAT ROOM ID => $_chatRoomId");

      debugPrint(
          "PARTICIPANTS => ${[_myUid, _targetChatId]}");

      debugPrint(
          "CHAT TYPE => ${_isHandymanChat ? 'handyman' : 'provider'}");

      debugPrint(
          "====================================");

      await chatRoomRef.set(
        chatRoomData,
        SetOptions(
          merge: true,
        ),
      );

      debugPrint(
          "✅ Chat room updated: $_chatRoomId");

      WidgetsBinding.instance
          .addPostFrameCallback((_) {

        if (_scrollController
            .hasClients) {

          _scrollController
              .animateTo(

            _scrollController
                .position
                .maxScrollExtent,

            duration:
                const Duration(
                    milliseconds: 300),

            curve:
                Curves.easeOut,
          );
        }
      });

    } catch (e, stackTrace) {

      debugPrint(
          "❌ Error sending message: $e");

      debugPrint(
          "Stack trace: $stackTrace");

      if (mounted) {

        ScaffoldMessenger.of(
                context)
            .showSnackBar(

          SnackBar(

            content: Text(
              'Failed to send message: ${e.toString()}',
            ),

            backgroundColor:
                Colors.red,

            duration:
                const Duration(
                    seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _markMessagesRead(
      List<QueryDocumentSnapshot>
          docs) async {

    final batch =
        _firestore.batch();

    bool hasUnread = false;

    for (final doc in docs) {

      final data =
          doc.data()
              as Map<String, dynamic>;

      if (data['senderId'] !=
              _myUid &&
          data['isRead'] ==
              false) {

        hasUnread = true;

        batch.update(
          doc.reference,
          {
            'isRead': true,
          },
        );
      }
    }

    if (hasUnread) {

      await batch.commit();

      debugPrint(
          "✅ Messages marked as read");
    }
  }

  String _formatTimestamp(
      Timestamp? ts) {

    if (ts == null) return '';

    final dt = ts.toDate();

    final hour =
        dt.hour
            .toString()
            .padLeft(2, '0');

    final min =
        dt.minute
            .toString()
            .padLeft(2, '0');

    return '$hour:$min';
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          AppColors.chatBgColor,

      appBar: AppBar(

        backgroundColor:
            AppColors.primaryRed,

        elevation: 0,

        automaticallyImplyLeading:
            false,

        title: Row(

          children: [

            IconButton(

              icon: const Icon(
                Icons.arrow_back,
                color:
                    AppColors.naturalWhite,
              ),

              onPressed: () =>
                  Navigator.pop(context),
            ),

            SizedBox(
                width: Insets.xxs),

            CircleAvatar(

              radius:
                  AppSizes.w(
                      context,
                      20),

              backgroundColor:
                  Colors.grey.shade200,

              backgroundImage:
                  _providerImage
                          .startsWith(
                              'http')
                      ? NetworkImage(
                          _providerImage,
                          headers:
                              const {},
                        )
                      : null,

              child:
                  !_providerImage
                          .startsWith(
                              'http')
                      ? const Icon(
                          Icons.person,
                          color:
                              Colors.grey,
                        )
                      : null,
            ),

            SizedBox(
                width: Insets.xsm),

            Expanded(

              child: Text(

                _providerName,

                style:
                    const TextStyle(

                  color:
                      AppColors.naturalWhite,

                  fontWeight:
                      FontWeight.w600,

                  fontSize: 16,
                ),

                overflow:
                    TextOverflow
                        .ellipsis,
              ),
            ),
          ],
        ),

        actions: [

          if (_providerPhone !=
              null)

            IconButton(

              icon: const Icon(
                Icons.call,
                color:
                    AppColors.naturalWhite,
              ),

              onPressed: () async {

                final phone =
                    _providerPhone
                        ?.replaceAll(
                            ' ',
                            '');

                if (phone != null &&
                    phone.isNotEmpty) {

                  try {

                    final Uri url =
                        Uri(

                      scheme: 'tel',

                      path: phone,
                    );

                    await launchUrl(
                      url,
                      mode: LaunchMode
                          .externalApplication,
                    );

                  } catch (e) {

                    debugPrint(
                        'Could not launch call: $e');
                  }
                }
              },
            ),

          const SizedBox(
              width: 8),
        ],
      ),

      body: SafeArea(

        child: Column(

          children: [

            Expanded(

              child:
                  StreamBuilder<QuerySnapshot>(

                stream:
                    _messagesRef

                        .orderBy(
                          'timestamp',
                          descending: false,
                        )

                        .snapshots(),

                builder:
                    (context, snapshot) {

                  debugPrint(
                      "=========== CHAT STREAM ===========");

                  debugPrint(
                      "HAS DATA => ${snapshot.hasData}");

                  debugPrint(
                      "DOC COUNT => ${snapshot.data?.docs.length}");

                  debugPrint(
                      "ERROR => ${snapshot.error}");

                  debugPrint(
                      "===================================");

                  if (snapshot
                          .connectionState ==
                      ConnectionState
                          .waiting) {

                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  if (snapshot
                      .hasError) {

                    return Center(

                      child: Text(

                        'Error: ${snapshot.error}',

                        style:
                            const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    );
                  }

                  final docs =
                      snapshot.data?.docs ??
                          [];

                  if (docs.isNotEmpty) {

                    _markMessagesRead(
                        docs);
                  }

                  if (docs.isEmpty) {

                    return Center(

                      child: Column(

                        mainAxisSize:
                            MainAxisSize.min,

                        children: [

                          Icon(
                            Icons
                                .chat_bubble_outline,
                            size: 64,
                            color: Colors
                                .grey
                                .shade400,
                          ),

                          const SizedBox(
                              height: 12),

                          Text(

                            'No messages yet.\nSay hi to your professional!',

                            textAlign:
                                TextAlign.center,

                            style: TextStyle(
                              color: Colors
                                  .grey
                                  .shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  WidgetsBinding
                      .instance
                      .addPostFrameCallback(
                          (_) {

                    if (_scrollController
                        .hasClients) {

                      _scrollController
                          .animateTo(

                        _scrollController
                            .position
                            .maxScrollExtent,

                        duration:
                            const Duration(
                                milliseconds:
                                    200),

                        curve:
                            Curves.easeOut,
                      );
                    }
                  });

                  return ListView.builder(

                    controller:
                        _scrollController,

                    padding:
                        EdgeInsets.all(
                            Insets.xs),

                    itemCount:
                        docs.length,

                    itemBuilder:
                        (_, index) {

                      final data =
                          docs[index]
                                  .data()
                              as Map<String,
                                  dynamic>;

                      debugPrint(
                          "FULL MESSAGE DATA => $data");

                      final isMe =
                          data['senderId'] ==
                              _myUid;

                      final text =

                          data['message'] ??

                          data['text'] ??

                          data['msg'] ??

                          '';

                      debugPrint(
                          "MESSAGE => $text");

                      final time =
                          _formatTimestamp(

                        data['timestamp']
                            as Timestamp?,
                      );

                      final isRead =
                          data['isRead'] ==
                              true;

                      return _ChatBubble(

                        text: text,

                        time: time,

                        isMe: isMe,

                        isRead: isRead,
                      );
                    },
                  );
                },
              ),
            ),

            Container(

              padding:
                  EdgeInsets.symmetric(

                horizontal:
                    Insets.xs,

                vertical:
                    Insets.xxs,
              ),

              color:
                  AppColors.naturalBlack,

              child: Row(

                children: [

                  Expanded(

                    child: TextField(

                      controller:
                          _controller,

                      textInputAction:
                          TextInputAction.send,

                      onSubmitted: (_) =>
                          _sendMessage(),

                      decoration:
                          InputDecoration(

                        hintText:
                            UserMessages
                                .messageHint,

                        fillColor:
                            AppColors
                                .naturalWhite,

                        filled: true,

                        border:
                            OutlineInputBorder(

                          borderRadius:
                              BorderRadius.all(

                            Radius.circular(
                                Insets.md),
                          ),

                          borderSide:
                              BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                      width: Insets.xxs),

                  CircleAvatar(

                    backgroundColor:
                        AppColors
                            .sendButtonColor,

                    child:
                        IconButton(

                      icon: const Icon(
                        Icons.send,
                        color: AppColors
                            .naturalWhite,
                      ),

                      onPressed:
                          _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {

    _scrollController.dispose();

    _controller.dispose();

    super.dispose();
  }
}

class _ChatBubble extends StatelessWidget {

  final String text;

  final String time;

  final bool isMe;

  final bool isRead;

  const _ChatBubble({

    required this.text,

    required this.time,

    required this.isMe,

    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {

    return Row(

      mainAxisAlignment:

          isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,

      children: [

        Container(

          margin:
              EdgeInsets.symmetric(

            vertical:
                AppSizes.h(
                    context,
                    4),
          ),

          padding:
              EdgeInsets.symmetric(

            horizontal:
                Insets.xs,

            vertical:
                Insets.xxs,
          ),

          constraints:
              BoxConstraints(

            maxWidth:
                MediaQuery.of(context)
                        .size
                        .width *
                    0.72,
          ),

          decoration:
              BoxDecoration(

            color:

                isMe
                    ? AppColors
                        .chatBubbleMe
                    : AppColors
                        .naturalWhite,

            borderRadius:
                BorderRadius.only(

              topLeft:
                  const Radius.circular(
                      12),

              topRight:
                  const Radius.circular(
                      12),

              bottomLeft:
                  Radius.circular(
                      isMe
                          ? 12
                          : 0),

              bottomRight:
                  Radius.circular(
                      isMe
                          ? 0
                          : 12),
            ),
          ),

          child: Column(

            mainAxisSize:
                MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment.end,

            children: [

              Align(

                alignment:
                    Alignment.centerLeft,

                child: Text(

                  text,

                  style: TextStyle(
                    fontSize:
                        AppSizes.w(
                            context,
                            14),
                  ),
                ),
              ),

              SizedBox(
                  height:
                      AppSizes.h(
                          context,
                          2)),

              Row(

                mainAxisSize:
                    MainAxisSize.min,

                children: [

                  Text(

                    time,

                    style: TextStyle(

                      fontSize:
                          AppSizes.w(
                              context,
                              10),

                      color:
                          Colors.black54,
                    ),
                  ),

                  if (isMe) ...[

                    SizedBox(
                        width:
                            Insets.xxs),

                    Icon(

                      Icons.done_all,

                      size:
                          AppSizes.w(
                              context,
                              14),

                      color:
                          isRead
                              ? AppColors
                                  .pauseBlue
                              : AppColors
                                  .naturalGray,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}