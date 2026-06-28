import 'dart:math';
import 'package:flutter/material.dart';
import 'compression_model.dart';
import 'colors.dart';

class HuffmanPainter extends CustomPainter {
  final List<HuffNode> forest; // Root yerine forest alıyor
  final Map<String, String> codes;
  final String highlightChar;
  final Size canvasSize;

  const HuffmanPainter({
    required this.forest,
    required this.codes,
    this.highlightChar = '',
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _grid(canvas, size);
    if (forest.isEmpty) {
      _emptyHint(canvas, size);
      return;
    }

    final allNodes = <HuffNode>[];
    for (var root in forest) {
      _collectNodes(root, allNodes);
    }
    if (allNodes.isEmpty) return;

    double minX = allNodes.map((n) => n.x).reduce(min);
    double maxX = allNodes.map((n) => n.x).reduce(max);
    double minY = allNodes.map((n) => n.y).reduce(min);

    final treeWidth = maxX - minX;

    // Tüm ormanı ekrana ortala
    final offsetX = (size.width - treeWidth) / 2 - minX;
    final offsetY = 60.0 - minY;

    Offset transform(HuffNode n) => Offset(n.x + offsetX, n.y + offsetY);

    for (var root in forest) {
      _drawEdges(canvas, root, transform);
    }
    for (var root in forest) {
      _drawNodes(canvas, root, transform);
    }
  }

  void _collectNodes(HuffNode node, List<HuffNode> result) {
    result.add(node);
    if (node.left != null) _collectNodes(node.left!, result);
    if (node.right != null) _collectNodes(node.right!, result);
  }

  void _drawEdges(Canvas canvas, HuffNode node, Offset Function(HuffNode) t) {
    const r = 20.0;
    if (node.left != null) {
      final s = t(node), e = t(node.left!);
      final dx = e.dx - s.dx, dy = e.dy - s.dy;
      final len = sqrt(dx * dx + dy * dy);

      if (len > r * 2) {
        final ux = dx / len, uy = dy / len;
        final start = Offset(s.dx + ux * r, s.dy + uy * r);
        final end = Offset(e.dx - ux * r, e.dy - uy * r);
        canvas.drawLine(start, end, Paint()..color = AC.text2.withOpacity(0.35)..strokeWidth = 1.5);
        _edgeLabel(canvas, '0', Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2), isLeft: true);
      }
      _drawEdges(canvas, node.left!, t);
    }
    if (node.right != null) {
      final s = t(node), e = t(node.right!);
      final dx = e.dx - s.dx, dy = e.dy - s.dy;
      final len = sqrt(dx * dx + dy * dy);

      if (len > r * 2) {
        final ux = dx / len, uy = dy / len;
        final start = Offset(s.dx + ux * r, s.dy + uy * r);
        final end = Offset(e.dx - ux * r, e.dy - uy * r);
        canvas.drawLine(start, end, Paint()..color = AC.text2.withOpacity(0.35)..strokeWidth = 1.5);
        _edgeLabel(canvas, '1', Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2), isLeft: false);
      }
      _drawEdges(canvas, node.right!, t);
    }
  }

  void _drawNodes(Canvas canvas, HuffNode node, Offset Function(HuffNode) t) {
    const r = 20.0;
    final pos = t(node);
    final isLeaf = node.isLeaf && node.char != null && node.char!.isNotEmpty;
    final isHighlight = isLeaf && node.char == highlightChar;

    if (isHighlight) {
      canvas.drawCircle(pos, r + 6, Paint()
        ..color = AC.primary.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }

    canvas.drawCircle(pos, r, Paint()
      ..color = isHighlight ? AC.primary : isLeaf ? AC.bg2 : const Color(0xFFE8F4FF));

    canvas.drawCircle(pos, r, Paint()
      ..color = isHighlight ? AC.primary : isLeaf ? AC.primary.withOpacity(0.5) : AC.text2.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isLeaf ? 2.0 : 1.0);

    _txt(canvas, '${node.freq}', pos + const Offset(0, -5),
        color: isHighlight ? Colors.white : AC.text, size: 11, bold: true);

    if (isLeaf) {
      final label = node.char == ' ' ? '⎵' : (node.char ?? '');
      _txt(canvas, '"$label"', pos + const Offset(0, 7),
          color: isHighlight ? Colors.white.withOpacity(0.85) : AC.primary, size: 9, bold: false);
    }

    if (node.left != null) _drawNodes(canvas, node.left!, t);
    if (node.right != null) _drawNodes(canvas, node.right!, t);
  }

  void _edgeLabel(Canvas canvas, String t, Offset pos, {required bool isLeft}) {
    final offset = Offset(isLeft ? -8 : 8, 0);
    _txt(canvas, t, pos + offset,
        color: t == '0' ? AC.text2 : AC.text, size: 10, bold: true, bg: true);
  }

  void _grid(Canvas canvas, Size size) {
    const gridSize = 25.0;
    final gridPaint = Paint()
      ..color = const Color(0xFF80A0D0).withOpacity(0.5)
      ..strokeWidth = 0.5;
    for (double y = -2000; y < size.height + 2000; y += gridSize) {
      canvas.drawLine(Offset(-2000, y), Offset(size.width + 2000, y), gridPaint);
    }
    for (double x = -2000; x < size.width + 2000; x += gridSize) {
      canvas.drawLine(Offset(x, -2000), Offset(x, size.height + 2000), gridPaint);
    }
  }

  void _emptyHint(Canvas canvas, Size size) {
    _txt(canvas, 'Metin girin ve ÇALIŞTIR\'a basın',
        Offset(size.width / 2, size.height / 2),
        color: AC.text2, size: 12, bold: false);
  }

  void _txt(Canvas canvas, String t, Offset pos,
      {Color color = Colors.white, double size = 12, bool bold = false, bool bg = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          color: color, fontSize: size,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    if (bg) {
      final rect = Rect.fromCenter(center: pos, width: tp.width + 6, height: tp.height + 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = AC.bg.withOpacity(0.9),
      );
    }
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(HuffmanPainter old) => true;
}