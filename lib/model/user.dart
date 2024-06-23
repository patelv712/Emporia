class UserModel {
  final String uid;
  final String name;
  final String email;
  final String image;
  final bool isOnline;

  const UserModel({
    required this.name,
    required this.image,
    required this.uid,
    required this.email,
    this.isOnline = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['uid'],
        name: json['name'],
        image: json['image'],
        email: json['email'],
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'image': image,
        'email': email,
      };
}