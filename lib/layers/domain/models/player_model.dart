import 'package:impostor_ar/core/models/player_color.dart';

class Player {
  final String uid;
  final String name;
  final String? userPhotoUrl; // Foto original do usuário (se existir)
  final String avatar; // Avatar atual: pode ser foto ou cor hex
  final int joinedAt; // Timestamp em milissegundos quando player entrou
  final bool isReady; // Se o jogador marcou como pronto

  Player({
    required this.uid,
    required this.name,
    this.userPhotoUrl,
    required this.avatar,
    required this.joinedAt,
    this.isReady = false,
  });

  // Verificar se o avatar é uma cor (começa com número ou letra hexadecimal)
  bool get isAvatarColor {
    if (avatar.isEmpty) return false;
    // Se começa com # e tem 6 ou 8 caracteres depois, é cor
    if (avatar.startsWith('#')) {
      return avatar.length == 7 || avatar.length == 9;
    }
    // Se é só hexadecimal (sem #), é cor
    return RegExp(r'^[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$').hasMatch(avatar);
  }

  // Verificar se é foto (URL)
  bool get isAvatarPhoto => !isAvatarColor;

  // Verificar se o usuário tem foto original
  bool get hasUserPhoto => userPhotoUrl != null && userPhotoUrl!.isNotEmpty;

  // Retorna a cor hex do avatar (se for foto, retorna cor padrão)
  String get avatarColorHex => isAvatarColor ? avatar : PlayerColor.red.hex;

  // Retorna a URL da foto do avatar (se for foto)
  String? get avatarPhotoUrl => isAvatarPhoto ? avatar : null;

  // Copy with para facilitar atualizações
  Player copyWith({
    String? uid,
    String? name,
    String? userPhotoUrl,
    String? avatar,
    int? joinedAt,
    bool? isReady,
  }) {
    return Player(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      avatar: avatar ?? this.avatar,
      joinedAt: joinedAt ?? this.joinedAt,
      isReady: isReady ?? this.isReady,
    );
  }

  // Converter para Map para salvar no Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'userPhotoUrl': userPhotoUrl,
      'avatar': avatar,
      'joinedAt': joinedAt,
      'isReady': isReady,
    };
  }

  // Factory para criar a partir do Map (Firebase)
  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      uid: map['uid'] ?? '',
      name: map['name'] ?? 'Desconhecido',
      userPhotoUrl: map['userPhotoUrl'],
      avatar: map['avatar'] ?? PlayerColor.red.hex,
      joinedAt: map['joinedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      isReady: map['isReady'] ?? false,
    );
  }

  @override
  String toString() =>
      'Player(uid: $uid, name: $name, avatar: $avatar, isColor: $isAvatarColor, hasUserPhoto: $hasUserPhoto)';
}
