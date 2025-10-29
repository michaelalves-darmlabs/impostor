enum PlayerColor {
  red('E63946', 'Vermelho'),
  blue('1F51BA', 'Azul'),
  green('50C878', 'Verde'),
  pink('FF62D9', 'Rosa'),
  orange('FF9900', 'Laranja'),
  yellow('FDD835', 'Amarelo'),
  black('3F474F', 'Preto'),
  white('F0F1F5', 'Branco'),
  cyan('38A8E1', 'Ciano'),
  lime('3FFF00', 'Lima'),
  maroon('AD1457', 'Bordô'),
  rose('F75A8C', 'Cereja');

  final String hex;
  final String displayName;

  const PlayerColor(this.hex, this.displayName);

  static PlayerColor fromHex(String hex) {
    return PlayerColor.values.firstWhere(
      (color) => color.hex == hex,
      orElse: () => PlayerColor.red,
    );
  }

  static PlayerColor random() {
    final colors = PlayerColor.values;
    return colors[DateTime.now().millisecondsSinceEpoch % colors.length];
  }
}
