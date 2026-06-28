class HuffNode {
  final String? char;
  final int freq;
  final HuffNode? left, right;
  double x = 0, y = 0;

  HuffNode({this.char, required this.freq, this.left, this.right});
  bool get isLeaf => left == null && right == null;
}

// LZW Tablo Satırı Modeli
class LzwTableRow {
  final int step;
  final String input;
  final String stringPlusChar;
  final String inTable;
  final String temp;
  final String addToDict;
  final String output;

  LzwTableRow({
    required this.step,
    required this.input,
    required this.stringPlusChar,
    required this.inTable,
    required this.temp,
    required this.addToDict,
    required this.output,
  });
}

enum StepType { init, build, encode, done }

class CompressStep {
  final StepType type;

  // Huffman
  final List<HuffNode> huffForest;
  final Map<String, String> huffCodes;
  final String encodedBits;
  final String highlightChar;

  // LZW
  final List<LzwTableRow> lzwTableRows;
  final Map<String, int> initialDict;

  const CompressStep({
    required this.type,
    this.huffForest = const [],
    this.huffCodes = const {},
    this.encodedBits = '',
    this.highlightChar = '',
    this.lzwTableRows = const [],
    this.initialDict = const {},
  });
}