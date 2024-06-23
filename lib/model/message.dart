class Message {
  final String senderId;
  final String content;
  final DateTime sentTime;
  final MessageType messageType;

  const Message({
    required this.senderId,
    required this.sentTime,
    required this.content,
    required this.messageType,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        senderId: json['senderId'],
        sentTime: json['sentTime'].toDate(),
        content: json['content'],
        messageType: MessageType.fromJson(json['messageType']),
      );

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'sentTime': sentTime,
        'content': content,
        'messageType': messageType.toJson(),
      };
}

enum MessageType {
  text,
  image,
  payment,
  paymentConfirmation;

  String toJson() => name;

  factory MessageType.fromJson(String json) => values.byName(json);
}
