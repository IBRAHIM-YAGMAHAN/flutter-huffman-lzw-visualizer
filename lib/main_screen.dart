import 'dart:async';
import 'package:flutter/material.dart';
import 'compression_model.dart';
import 'colors.dart';
import 'algorithms.dart';
import 'custom_buttons.dart';
import 'huffman_painter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  String _algo = 'huffman';
  final _algos = ['huffman', 'lzw'];
  final _algoNames = {'huffman': 'HUFFMAN', 'lzw': 'LZW'};

  List<CompressStep> _steps = [];
  int _stepIdx = 0;
  Timer? _timer;
  bool _running = false;
  double _speed = 1.0;

  late TabController _tabCtrl;
  final _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() {
          _algo = _algos[_tabCtrl.index];
          _resetViz();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _resetViz() {
    _timer?.cancel();
    _running = false;
    _steps = [];
    _stepIdx = 0;
  }

  void _runAlgo() {
    final input = _textCtrl.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _resetViz();
      switch (_algo) {
        case 'huffman': _steps = Algorithms.huffman(input); break;
        case 'lzw': _steps = Algorithms.lzw(input); break;
      }
      _running = true;
    });
    _animate();
  }

  void _animate() {
    if (_stepIdx >= _steps.length) { setState(() => _running = false); return; }
    setState(() => _stepIdx++);
    final delayMs = (400 / _speed).round();
    _timer = Timer(Duration(milliseconds: delayMs), _animate);
  }

  CompressStep? get _curStep => _stepIdx > 0 && _steps.isNotEmpty ? _steps[_stepIdx - 1] : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: SafeArea(
        child: Column(children: [
          _header(),
          _inputBar(),
          _controlBar(),
          Expanded(child: _algo == 'huffman' ? _huffmanCanvas() : _lzwCanvas()),
        ]),
      ),
    );
  }

  Widget _header() {
    final ac = AC.forAlgo(_algo);
    return Container(
      decoration: BoxDecoration(
        color: AC.bg2,
        border: Border(bottom: BorderSide(color: ac, width: 1)),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: ac, indicatorWeight: 3,
        labelColor: ac, unselectedLabelColor: AC.text2,
        tabAlignment: TabAlignment.center,
        isScrollable: true,
        labelStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold),
        tabs: _algos.map((a) => Tab(text: _algoNames[a])).toList(),
      ),
    );
  }

  Widget _controlBar() {
    final ac = AC.forAlgo(_algo);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AC.bg3,
        border: Border(bottom: BorderSide(color: AC.border)),
      ),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              flex: 3,
              child: FuturisticButton(
                label: _running
                    ? '⏸ DURDUR'
                    : (_steps.isNotEmpty && _stepIdx > 0 && _stepIdx < _steps.length)
                    ? '▶ DEVAM ET'
                    : '▶ ÇALIŞTIR',
                color: ac,
                onTap: () {
                  if (_running) {
                    _timer?.cancel();
                    setState(() => _running = false);
                  } else if (_steps.isNotEmpty && _stepIdx > 0 && _stepIdx < _steps.length) {
                    setState(() => _running = true);
                    _animate();
                  } else {
                    _runAlgo();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FuturisticButton(label: '↺ SIFIRLA', color: AC.red, onTap: () {
                setState(() { _textCtrl.clear(); _resetViz(); });
              }),
            ),
          ]),

          const SizedBox(height: 12),

          Row(children: [
            const Icon(Icons.speed, size: 16, color: AC.text2),
            const SizedBox(width: 8),
            const Text('HIZ:', style: TextStyle(color: AC.text2, fontSize: 11, fontWeight: FontWeight.bold)),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: ac, thumbColor: ac,
                  inactiveTrackColor: AC.border, trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: _speed, min: 0.25, max: 2.0, divisions: 7,
                  onChanged: (v) => setState(() => _speed = v),
                ),
              ),
            ),
            Text('${_speed.toStringAsFixed(2)}x', style: TextStyle(color: ac, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      height: 44, color: AC.bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        const Icon(Icons.keyboard, size: 16, color: AC.text2),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _textCtrl,
            style: const TextStyle(color: AC.text, fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Sıkıştırılacak metni girin...',
              hintStyle: TextStyle(color: AC.text2, fontSize: 12),
              border: InputBorder.none,
            ),
            onChanged: (_) => setState(() => _resetViz()),
          ),
        ),
      ]),
    );
  }

// ─────────────────────────────────────────────
  // RENKLİ KOD ÇIKTISI OLUŞTURUCU METOT (GÜNCELLENDİ)
  // ─────────────────────────────────────────────
  Widget _buildColorizedOutput(CompressStep step) {
    final color1 = const Color(0xFF7C4DFF); // Mor
    final color2 = AC.primary; // Mavi
    List<TextSpan> spans = [];

    if (_algo == 'huffman') {
      final input = _textCtrl.text.trim();
      final codes = step.huffCodes;
      for (int i = 0; i < input.length; i++) {
        final char = input[i];
        final code = codes[char] ?? '';
        spans.add(TextSpan(
          text: code,
          style: TextStyle(color: i % 2 == 0 ? color1 : color2),
        ));
      }
    } else {
      // ─── LZW İÇİN İKİLİ (BINARY) KODLAMA ───
      final finalDict = step.initialDict;
      // 1. Sözlükteki en büyük değeri (toplam eleman sayısını) bul
      int maxCode = 0;
      if (finalDict.isNotEmpty) {
        maxCode = finalDict.values.reduce((a, b) => a > b ? a : b);
      }
      // 2. Bu en büyük sayıyı ifade edebilmek için kaç bit gerektiğini hesapla
      int requiredBits = maxCode.toRadixString(2).length;

      // Tablodan '-' olmayan çıktıları al
      final outputList = step.lzwTableRows
          .where((r) => r.output != '-')
          .map((r) => finalDict[r.output])
          .whereType<int>() // null olmayanları int olarak al
          .toList();

      for (int i = 0; i < outputList.length; i++) {
        final binaryStr = outputList[i].toRadixString(2).padLeft(requiredBits, '0');

        spans.add(TextSpan(
          text: '$binaryStr ',
          style: TextStyle(color: i % 2 == 0 ? color1 : color2),
        ));
      }
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'monospace', fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.bold),
        children: spans,
      ),
    );
  }
  Widget _huffmanCanvas() {
    final step = _curStep;
    final forest = step?.huffForest ?? [];
    final codes = step?.huffCodes ?? {};
    final highlight = step?.highlightChar ?? '';

    return Stack(
      children: [
        LayoutBuilder(builder: (ctx, c) {
          if (forest.isEmpty) return _gridBackground(c.biggest);
          return InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(2000),
            minScale: 0.1, maxScale: 3.0,
            child: SizedBox(
              width: c.maxWidth, height: c.maxHeight,
              child: CustomPaint(
                painter: HuffmanPainter(forest: forest, codes: codes, highlightChar: highlight, canvasSize: c.biggest),
              ),
            ),
          );
        }),

        if (step != null && step.type == StepType.done)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AC.bg.withOpacity(0.95),
                border: Border.all(color: AC.primary, width: 2),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: AC.primary.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('KODLANMIŞ ÇIKTI (SONUÇ)', style: TextStyle(color: AC.primary, fontSize: 10, letterSpacing: 2, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildColorizedOutput(step),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _lzwCanvas() {
    final step = _curStep;
    if (step == null || step.lzwTableRows.isEmpty) {
      return LayoutBuilder(builder: (_, c) => _gridBackground(c.biggest));
    }

    final ac = AC.forAlgo(_algo);

    return Stack(children: [
      LayoutBuilder(builder: (_, c) => _gridBackground(c.biggest)),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AC.bg.withOpacity(0.95),
                border: Border.all(color: AC.border),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AC.bg2),
                    // ─── BAŞLIK BOYUTU VE BOŞLUKLAR KÜÇÜLTÜLDÜ ───
                    headingTextStyle: TextStyle(color: ac, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11),
                    dataTextStyle: const TextStyle(color: AC.text, fontFamily: 'monospace', fontSize: 13),
                    columnSpacing: 22, // Sütunlar arası boşluk iyice daraltıldı
                    columns: const [
                      DataColumn(label: Text('Step')),
                      DataColumn(label: Text('Input')),
                      DataColumn(label: Text('Str\n+Char', textAlign: TextAlign.center)), // İki satır yapıldı
                      DataColumn(label: Text('In Dict\nTable', textAlign: TextAlign.center)), // İki satır yapıldı
                      DataColumn(label: Text('Temp')),
                      DataColumn(label: Text('Add to\nDict', textAlign: TextAlign.center)), // İki satır yapıldı
                      DataColumn(label: Text('Output')),
                    ],
                    rows: step.lzwTableRows.map((r) => DataRow(
                        cells: [
                          DataCell(Text('${r.step}', style: const TextStyle(color: AC.text2))),
                          DataCell(Text(r.input)),
                          DataCell(Text(r.stringPlusChar)),
                          DataCell(Text(r.inTable, style: const TextStyle(color: AC.red, fontWeight: FontWeight.bold))),
                          DataCell(Text(r.temp)),
                          DataCell(Text(r.addToDict)),
                          DataCell(Text(r.output, style: TextStyle(color: ac, fontWeight: FontWeight.w900))),
                        ]
                    )).toList(),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 80),
        ]),
      ),

      if (step.type == StepType.done)
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AC.bg.withOpacity(0.95),
              border: Border.all(color: ac, width: 2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: ac.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KODLANMIŞ ÇIKTI (SONUÇ)', style: TextStyle(color: ac, fontSize: 10, letterSpacing: 2, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildColorizedOutput(step),
              ],
            ),
          ),
        ),
    ]);
  }

  Widget _gridBackground(Size size) {
    return CustomPaint(size: size, painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const gridSize = 25.0;
    final p = Paint()..color = const Color(0xFF80A0D0).withOpacity(0.5)..strokeWidth = 0.5;
    for (double y = -2000; y < size.height + 2000; y += gridSize) {
      canvas.drawLine(Offset(-2000, y), Offset(size.width + 2000, y), p);
    }
    for (double x = -2000; x < size.width + 2000; x += gridSize) {
      canvas.drawLine(Offset(x, -2000), Offset(x, size.height + 2000), p);
    }
  }
  @override bool shouldRepaint(_) => false;
}