import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class DonutChart extends StatefulWidget {
  const DonutChart({
    super.key,
    required this.values,
    required this.colors,
    required this.centerText,
    required this.totalText,
  });

  final List<double> values;
  final List<Color> colors;
  final String centerText;
  final String totalText;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();

  @override
  void didUpdateWidget(covariant DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.values, widget.values) ||
        !listEquals(oldWidget.colors, widget.colors)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) => CustomPaint(
      painter: DonutChartPainter(
        values: widget.values,
        colors: widget.colors,
        progress: Curves.easeOutCubic.transform(_controller.value),
        centerText: widget.centerText,
        totalText: widget.totalText,
        foreground: Theme.of(context).colorScheme.onSurface,
        track: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: const SizedBox.expand(),
    ),
  );
}

class DonutChartPainter extends CustomPainter {
  const DonutChartPainter({
    required this.values,
    required this.colors,
    required this.progress,
    required this.centerText,
    required this.totalText,
    required this.foreground,
    required this.track,
  });

  final List<double> values;
  final List<Color> colors;
  final double progress;
  final String centerText;
  final String totalText;
  final Color foreground;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = math.min(size.width, size.height) * 0.13;
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2 - 2;
    if (radius <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final total = values.fold<double>(0, (sum, value) => sum + value);
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);
    if (total > 0) {
      var startAngle = -math.pi / 2;
      for (var index = 0; index < values.length; index++) {
        if (values[index] <= 0) continue;
        final sweep = values[index] / total * math.pi * 2 * progress;
        final paint = Paint()
          ..color = colors[index % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt
          ..strokeWidth = strokeWidth;
        canvas.drawArc(
          rect,
          startAngle,
          math.max(0, sweep - 0.025),
          false,
          paint,
        );
        startAngle += sweep;
      }
    }
    _drawCenteredText(
      canvas,
      center,
      centerText,
      TextStyle(
        color: foreground.withValues(alpha: 0.65),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      -10,
    );
    _drawCenteredText(
      canvas,
      center,
      totalText,
      TextStyle(color: foreground, fontSize: 16, fontWeight: FontWeight.bold),
      11,
    );
  }

  void _drawCenteredText(
    Canvas canvas,
    Offset center,
    String text,
    TextStyle style,
    double verticalOffset,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 110);
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy + verticalOffset),
    );
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) =>
      !listEquals(oldDelegate.values, values) ||
      !listEquals(oldDelegate.colors, colors) ||
      oldDelegate.progress != progress ||
      oldDelegate.centerText != centerText ||
      oldDelegate.totalText != totalText ||
      oldDelegate.foreground != foreground ||
      oldDelegate.track != track;
}

class WeeklyBarChart extends StatefulWidget {
  const WeeklyBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void didUpdateWidget(covariant WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.values, widget.values) ||
        !listEquals(oldWidget.labels, widget.labels)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) => CustomPaint(
      painter: WeeklyBarChartPainter(
        values: widget.values,
        labels: widget.labels,
        color: widget.color,
        progress: Curves.easeOutCubic.transform(_controller.value),
        labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        gridColor: Theme.of(context).colorScheme.outlineVariant,
      ),
      child: const SizedBox.expand(),
    ),
  );
}

class WeeklyBarChartPainter extends CustomPainter {
  const WeeklyBarChartPainter({
    required this.values,
    required this.labels,
    required this.color,
    required this.progress,
    required this.labelColor,
    required this.gridColor,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final double progress;
  final Color labelColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 8.0;
    const right = 8.0;
    const top = 13.0;
    const bottom = 29.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    if (chartWidth <= 0 || chartHeight <= 0 || values.isEmpty) return;
    final maximum = values.fold<double>(
      0,
      (current, value) => math.max(current, value),
    );
    final scaleMaximum = maximum == 0 ? 1.0 : maximum;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var line = 0; line <= 2; line++) {
      final y = top + chartHeight * line / 2;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }
    final slotWidth = chartWidth / values.length;
    final barWidth = math.min(24.0, slotWidth * 0.55);
    for (var index = 0; index < values.length; index++) {
      final height = values[index] / scaleMaximum * chartHeight * progress;
      final x = left + slotWidth * index + (slotWidth - barWidth) / 2;
      final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          top + chartHeight - height,
          barWidth,
          math.max(0, height),
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        bar,
        Paint()
          ..color = values[index] == 0
              ? color.withValues(alpha: 0.18)
              : color.withValues(alpha: 0.92),
      );
      if (values[index] > 0) {
        final amountPainter = TextPainter(
          text: TextSpan(
            text: _compactAmount(values[index]),
            style: TextStyle(
              color: labelColor,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: slotWidth);
        amountPainter.paint(
          canvas,
          Offset(
            left + slotWidth * index + (slotWidth - amountPainter.width) / 2,
            math.max(top, top + chartHeight - height - 13),
          ),
        );
      }
      final labelPainter = TextPainter(
        text: TextSpan(
          text: labels[index],
          style: TextStyle(color: labelColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: slotWidth);
      labelPainter.paint(
        canvas,
        Offset(
          left + slotWidth * index + (slotWidth - labelPainter.width) / 2,
          size.height - 20,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyBarChartPainter oldDelegate) =>
      !listEquals(oldDelegate.values, values) ||
      !listEquals(oldDelegate.labels, labels) ||
      oldDelegate.color != color ||
      oldDelegate.progress != progress ||
      oldDelegate.labelColor != labelColor ||
      oldDelegate.gridColor != gridColor;

  String _compactAmount(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}m';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toInt().toString();
  }
}
