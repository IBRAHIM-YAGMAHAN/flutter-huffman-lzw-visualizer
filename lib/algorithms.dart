import 'package:collection/collection.dart';
import 'compression_model.dart';

class Algorithms {
  static double _nextLeafX = 0.0;

  // HUFFMAN CODING
  static List<CompressStep> huffman(String input) {
    if (input.isEmpty) return [];
    final steps = <CompressStep>[];

    final freq = <String, int>{};
    for (final c in input.split('')) {
      freq[c] = (freq[c] ?? 0) + 1;
    }
    final freqList = freq.entries.map((e) => MapEntry(e.key, e.value)).toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final pq = PriorityQueue<HuffNode>((a, b) => a.freq.compareTo(b.freq));
    for (final e in freqList) {
      pq.add(HuffNode(char: e.key, freq: e.value));
    }

    if (pq.length == 1) {
      final single = pq.removeFirst();
      pq.add(HuffNode(freq: single.freq, left: single, right: HuffNode(char: '', freq: 0)));
    }

    _assignForestPositions(pq.toList());
    steps.add(CompressStep(
      type: StepType.init,
      huffForest: pq.toList(),
    ));

    while (pq.length > 1) {
      final l = pq.removeFirst();
      final r = pq.removeFirst();
      final merged = HuffNode(freq: l.freq + r.freq, left: l, right: r);
      pq.add(merged);

      _assignForestPositions(pq.toList());
      steps.add(CompressStep(
        type: StepType.build,
        huffForest: pq.toList(),
      ));
    }

    final root = pq.first;
    final codes = <String, String>{};
    _buildCodes(root, '', codes);

    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final c = input[i];
      buffer.write(codes[c] ?? '');
      steps.add(CompressStep(
        type: StepType.encode,
        huffForest: [root],
        huffCodes: Map.from(codes),
        encodedBits: buffer.toString(),
        highlightChar: c,
      ));
    }

    steps.add(CompressStep(
      type: StepType.done,
      huffForest: [root],
      huffCodes: Map.from(codes),
      encodedBits: buffer.toString(),
    ));

    return steps;
  }

  static void _buildCodes(HuffNode node, String prefix, Map<String, String> codes) {
    if (node.isLeaf && node.char != null && node.char!.isNotEmpty) {
      codes[node.char!] = prefix.isEmpty ? '0' : prefix;
      return;
    }
    if (node.left != null) _buildCodes(node.left!, '${prefix}0', codes);
    if (node.right != null) _buildCodes(node.right!, '${prefix}1', codes);
  }

  static void _assignForestPositions(List<HuffNode> forest) {
    _nextLeafX = 0.0;
    for (var node in forest) {
      _assignPositions(node, 0.0);
      _nextLeafX += 90.0;
    }
  }

  static void _assignPositions(HuffNode node, double y) {
    node.y = y;
    const xOffset = 70.0;
    const yOffset = 90.0;

    if (node.isLeaf) {
      node.x = _nextLeafX;
      _nextLeafX += xOffset;
    } else {
      if (node.left != null) _assignPositions(node.left!, y + yOffset);
      if (node.right != null) _assignPositions(node.right!, y + yOffset);

      if (node.left != null && node.right != null) {
        node.x = (node.left!.x + node.right!.x) / 2;
      } else if (node.left != null) {
        node.x = node.left!.x;
      } else if (node.right != null) {
        node.x = node.right!.x;
      }
    }
  }

  // LZW COMPRESSION
  static List<CompressStep> lzw(String input) {
    if (input.isEmpty) return [];
    final steps = <CompressStep>[];

    final dict = <String, int>{};
    final uniqueChars = input.split('').toSet().toList()..sort();
    for (int i = 0; i < uniqueChars.length; i++) {
      dict[uniqueChars[i]] = i;
    }
    int nextCode = uniqueChars.length;

    steps.add(CompressStep(
      type: StepType.init,
      initialDict: Map.from(dict),
    ));

    final rows = <LzwTableRow>[];
    String p = '';
    int stepCount = 1;

    for (int i = 0; i < input.length; i++) {
      final c = input[i];
      final pPlusC = p + c;

      String inTable = '';
      String temp = '';
      String addToDict = '';
      String output = '';

      if (p.isEmpty) {
        // İlk adım (Step 1)
        inTable = '';
        temp = c;
        addToDict = '-';
        output = '-';
        p = c;
      } else if (dict.containsKey(pPlusC)) {
        // Tabloda var
        inTable = '';
        temp = pPlusC;
        addToDict = '-';
        output = '-';
        p = pPlusC;
      } else {
        // Tabloda yok 'N'
        inTable = 'N';
        temp = c;
        addToDict = '$pPlusC($nextCode)';
        output = p;

        dict[pPlusC] = nextCode;
        nextCode++;
        p = c;
      }

      rows.add(LzwTableRow(
        step: stepCount,
        input: c,
        stringPlusChar: pPlusC,
        inTable: inTable,
        temp: temp,
        addToDict: addToDict,
        output: output,
      ));

      steps.add(CompressStep(
        type: StepType.encode,
        lzwTableRows: List.from(rows),
        initialDict: Map.from(dict),
      ));

      stepCount++;
    }

    if (p.isNotEmpty) {
      rows.add(LzwTableRow(
        step: stepCount,
        input: '-',
        stringPlusChar: '-',
        inTable: '-',
        temp: '-',
        addToDict: '-',
        output: p,
      ));
      steps.add(CompressStep(
        type: StepType.encode,
        lzwTableRows: List.from(rows),
        initialDict: Map.from(dict),
      ));
    }

    steps.add(CompressStep(
      type: StepType.done,
      lzwTableRows: List.from(rows),
      initialDict: Map.from(dict),
    ));
    return steps;
  }
}