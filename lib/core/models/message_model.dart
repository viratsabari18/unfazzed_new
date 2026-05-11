class MessageModel {
  final String id;
  final String text;
  final String time;
  final String senderId; 
  final bool isRead;

  MessageModel({
    required this.id,
    required this.text,
    required this.time,
    required this.senderId,
    required this.isRead,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      text: json['text'],
      time: json['time'],
      senderId: json['sender_id'],
      isRead: json['is_read'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "text": text,
      "time": time,
      "sender_id": senderId,
      "is_read": isRead,
    };
  }
}
