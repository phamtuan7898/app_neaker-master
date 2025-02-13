class Admin {
  final String id;
  final String adminname;

  Admin({
    required this.id,
    required this.adminname,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['_id'],
      adminname: json['adminname'],
    );
  }
}
