// users.dart (in your models folder)
class Users {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String tel;
  final String role;

  Users({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.tel,
    required this.role,
  });

  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      id: json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      email: json['email'] as String? ?? '',
      tel: json['tel'] as String? ?? '',
      role: json['role'] as String? ?? 'user', // Default here as well if needed
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'tel': tel,
      'role': role,
    };
  }
}
