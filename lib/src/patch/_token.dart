class Token {
  Token(this.text, this.type);

  final String text;
  final int type;

  static const number = 1;
  static const string = 2;
  static const operator = 3;
  static const separator = 4;
  static const identifier = 5;
  static const parameterValue = 6;
}
