import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:uuid/uuid.dart';

typedef SectionReciver = void Function(PieChartSectionData? section);

class MultiLevelPieChart extends StatefulWidget {
  const MultiLevelPieChart({
    super.key,
    required this.data,
    this.center,
    this.onSectionHover,
    this.onSectionTap,
  });

  final List<PieChartSectionData> data;
  final Widget? center;
  final SectionReciver? onSectionHover;
  final SectionReciver? onSectionTap;

  @override
  State<MultiLevelPieChart> createState() => _MultiLevelPieChartState();
}

class _MultiLevelPieChartState extends State<MultiLevelPieChart> {
  PieChartSectionData? _selectedSection;
  Offset? _selectedSectionPosition;

  _MultiLevelPieChartLayoutBuilder? _chartLayoutBuilder;

  @override
  void initState() {
    super.initState();

    _constructChartLayoutBuilder();
  }

  void _constructChartLayoutBuilder() {
    _chartLayoutBuilder = _MultiLevelPieChartLayoutBuilder(
      widget.data,
      innerRadius: 50,
      selected: _selectedSection,
    );
  }

  @override
  void didUpdateWidget(covariant MultiLevelPieChart oldWidget) {
    _constructChartLayoutBuilder();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (_chartLayoutBuilder == null) {
      return const Placeholder();
    }
    final renderObject = context.findRenderObject();
    Size? size;
    if (renderObject is RenderBox) {
      size = renderObject.size;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: MouseRegion(
            onHover: (event) {
              if (size != null) {
                final section = _chartLayoutBuilder!.getSectionAt(
                  position: event.localPosition,
                  size: size,
                );

                setState(() {
                  _selectedSection = section;
                  if (_selectedSection != null) {
                    _selectedSectionPosition = event.localPosition;
                  } else {
                    _selectedSectionPosition = null;
                  }

                  _constructChartLayoutBuilder();
                });

                widget.onSectionHover?.call(section);
              }
            },
            child: GestureDetector(
              onTapUp: (details) {
                if (size != null) {
                  final section = _chartLayoutBuilder!.getSectionAt(
                    position: details.localPosition,
                    size: size,
                  );

                  if (section != null) {
                    widget.onSectionTap?.call(section);
                  }
                }
              },
              child: CustomPaint(
                painter: _MultiLevelPieChartPainter(
                  layoutBuilder: _chartLayoutBuilder!,
                ),
                child: Center(
                  child: widget.center,
                ),
              ),
            ),
          ),
        ),
        if (_selectedSection != null)
          Positioned.fill(
            child: FloatingLabel(
              cursorPosition: _selectedSectionPosition!,
              child: ChartLabel(title: _selectedSection!.title),
            ),
          ),
      ],
    );
  }
}

class ChartLabel extends StatelessWidget {
  const ChartLabel({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            blurRadius: 8.0,
            offset: Offset(8.0, 8.0),
            color: Colors.black12,
          ),
        ],
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 6.0,
        vertical: 3.0,
      ),
      child: Text(title),
    );
  }
}

class FloatingLabel extends SingleChildRenderObjectWidget {
  const FloatingLabel({
    super.key,
    required this.cursorPosition,
    Widget? child,
  }) : super(child: child);

  final Offset cursorPosition;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return FloatingLabelRenderObject(cursorPosition);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as FloatingLabelRenderObject).cursorPosition = cursorPosition;
  }
}

class FlaotingLabelChild extends ContainerBoxParentData<RenderBox>
    with ContainerParentDataMixin<RenderBox> {}

class FloatingLabelRenderObject extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, FlaotingLabelChild>,
        RenderBoxContainerDefaultsMixin<RenderBox, FlaotingLabelChild>,
        RenderObjectWithChildMixin {
  Offset _cursorPosition;

  Offset get cursorPosition => _cursorPosition;

  set cursorPosition(Offset value) {
    _cursorPosition = value;
    markNeedsLayout();
  }

  FloatingLabelRenderObject(this._cursorPosition);

  @override
  void setupParentData(covariant RenderObject child) {
    child.parentData = FlaotingLabelChild();
  }

  @override
  void performLayout() {
    if (child is RenderBox) {
      final label = child as RenderBox;
      final labelConstraints = constraints.loosen();
      final labelSize = label.getDryLayout(labelConstraints);

      const labelOffset = Offset(10, 0);
      var labelPosition = cursorPosition + labelOffset;

      final labelRight = labelPosition.dx + labelSize.width;

      if (labelRight >= constraints.maxWidth) {
        labelPosition = labelPosition.translate(
          constraints.maxWidth - labelRight,
          15,
        );
      }

      final labelParentData = label.parentData as FlaotingLabelChild;
      label.layout(labelConstraints, parentUsesSize: true);
      labelParentData.offset = labelPosition;
    }

    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final parentData = child?.parentData as FlaotingLabelChild?;
    child?.paint(context, offset + (parentData?.offset ?? const Offset(0, 0)));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}

class PieChartSectionData<T> {
  final String id;
  final String title;
  final T data;
  final double value;
  final Color color;
  final List<PieChartSectionData>? subcategories;

  PieChartSectionData({
    required this.value,
    required this.color,
    required this.data,
    required this.title,
    this.subcategories,
  }) : id = const Uuid().v1();

  @override
  String toString() =>
      'PieChartSectionData(value: $value, color: $color, subcategories: $subcategories)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PieChartSectionData<T> &&
        other.id == id &&
        other.title == title &&
        other.data == data &&
        other.value == value &&
        other.color == color &&
        listEquals(other.subcategories, subcategories);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        data.hashCode ^
        value.hashCode ^
        color.hashCode ^
        subcategories.hashCode;
  }
}

class _MultiLevelPieChartPainter extends CustomPainter {
  final _MultiLevelPieChartLayoutBuilder layoutBuilder;

  _MultiLevelPieChartPainter({
    required this.layoutBuilder,
  });

  @override
  void paint(Canvas canvas, Size size) {
    layoutBuilder.biuldLayoutForEachUntil(
      size: size,
      needToProceed: (category, layout) {
        _drawCategory(
          canvas: canvas,
          size: size,
          category: category,
          layout: layout,
        );

        return true;
      },
    );

    return;
  }

  void _drawCategory({
    required Canvas canvas,
    required Size size,
    required PieChartSectionData category,
    required _MultiLevelPieChartLayout layout,
  }) {
    final subcategoryPaint = Paint()
      ..color =
          layout.isSelected ? category.color.withOpacity(0.5) : category.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = layout.width;

    canvas.drawArc(
      Rect.fromCircle(center: size.center(Offset.zero), radius: layout.radius),
      layout.startAngle,
      layout.sweepAngle,
      false,
      subcategoryPaint,
    );
  }

  @override
  bool shouldRepaint(_MultiLevelPieChartPainter oldDelegate) => true;
}

typedef _NeedToProceedCallback = bool Function(
  PieChartSectionData category,
  _MultiLevelPieChartLayout layout,
);

class _MultiLevelPieChartLayoutBuilder {
  final List<PieChartSectionData> data;
  final PieChartSectionData? selected;
  final double innerRadius;

  _MultiLevelPieChartLayoutBuilder(
    this.data, {
    required this.innerRadius,
    this.selected,
  });

  PieChartSectionData? getSectionAt({required Size size, required position}) {
    double touchX = position.dx - size.width / 2;
    double touchY = position.dy - size.height / 2;
    double touchAngle = math.atan2(touchY, touchX);
    final touchRadius = Offset(touchX, touchY).distance;
    final levelWidth = _calculateLevelWidth(size);

    if (touchAngle < 0) {
      touchAngle += 2 * math.pi;
    }

    void findTargetRecursive(
      List<PieChartSectionData> data,
      double startAngle,
      double sweepAngle,
      int level,
      void Function(PieChartSectionData target) onFound,
    ) {
      var totalValue =
          data.fold<double>(0.0, (sum, section) => sum + section.value);

      for (final section in data) {
        final sectionSweepAngle = (section.value / totalValue) * sweepAngle;

        final endAngle = startAngle + sectionSweepAngle;
        if (startAngle <= touchAngle && touchAngle <= endAngle) {
          final startWidth = innerRadius + level * levelWidth;
          final endWidth = startWidth + levelWidth;
          if (startWidth <= touchRadius && touchRadius <= endWidth) {
            onFound(section);

            break;
          }
        }

        if (section.subcategories != null &&
            section.subcategories!.isNotEmpty) {
          findTargetRecursive(
            section.subcategories!,
            startAngle,
            sectionSweepAngle,
            level + 1,
            onFound,
          );
        }

        startAngle += sectionSweepAngle;
      }
    }

    PieChartSectionData? maybeSection;
    void onFound(PieChartSectionData target) {
      maybeSection = target;
    }

    findTargetRecursive(data, 0, 2 * math.pi, 0, onFound);

    return maybeSection;
  }

  /// Throws [CategoryNotFoundException] if category is not found
  _MultiLevelPieChartLayout buildLayoutFor({
    required PieChartSectionData category,
    required Size size,
  }) {
    _MultiLevelPieChartLayout? maybeLayout;

    _biuldLayoutForEachUntil(
      categories: data,
      startAngle: 0.0,
      sweepAngle: 2 * math.pi,
      levelIndex: 0,
      size: size,
      needToProceed: (possibleCategory, layout) {
        if (possibleCategory == category) {
          maybeLayout = layout;
          return false;
        }

        return true;
      },
    );

    if (maybeLayout == null) {
      throw CategoryNotFoundException();
    }

    return maybeLayout!;
  }

  void biuldLayoutForEachUntil({
    required Size size,
    required _NeedToProceedCallback needToProceed,
  }) {
    _biuldLayoutForEachUntil(
      categories: data,
      startAngle: 0.0,
      sweepAngle: 2 * math.pi,
      levelIndex: 0,
      size: size,
      needToProceed: needToProceed,
    );
  }

  /// Return [true] if need to continue search, [false] otherwise. Return value
  /// is used only for recurcive.
  bool _biuldLayoutForEachUntil({
    required List<PieChartSectionData> categories,
    required double startAngle,
    required double sweepAngle,
    required int levelIndex,
    required Size size,
    required _NeedToProceedCallback needToProceed,
  }) {
    for (final category in categories) {
      final subcategoriesTotalValue = categories.fold<double>(
        0.0,
        (sum, category) => sum + category.value,
      );

      final categorySweepAngle =
          (category.value / subcategoriesTotalValue) * sweepAngle;

      final levelWidth = _calculateLevelWidth(size);

      final radius =
          (innerRadius - levelWidth / 2) + levelIndex * levelWidth + levelWidth;

      final layout = _MultiLevelPieChartLayout(
        startAngle: startAngle,
        sweepAngle: categorySweepAngle,
        radius: radius,
        width: levelWidth,
        isSelected: category == selected,
      );

      final needToContinue = needToProceed(category, layout);

      if (!needToContinue) {
        return false;
      }

      if (category.subcategories != null &&
          category.subcategories!.isNotEmpty) {
        final needToContinue = _biuldLayoutForEachUntil(
          categories: category.subcategories!,
          levelIndex: levelIndex + 1,
          startAngle: startAngle,
          sweepAngle: categorySweepAngle,
          size: size,
          needToProceed: needToProceed,
        );

        if (!needToContinue) {
          return false;
        }
      }

      startAngle += categorySweepAngle;
    }

    return levelIndex != 0;
  }

  double _calculateLevelWidth(Size size) {
    const safePadding = 4.0;
    final levelWidth =
        (size.width / 2 - innerRadius - safePadding) / _calculateMaxDepth(data);

    return levelWidth;
  }

  int _calculateMaxDepth(List<PieChartSectionData> data) {
    int maxDepth = 1; // Начальное значение глубины - 1 (текущий уровень)

    for (var item in data) {
      if (item.subcategories != null) {
        int depth = _calculateMaxDepth(item.subcategories!) + 1;
        if (depth > maxDepth) {
          maxDepth = depth;
        }
      }
    }

    return maxDepth;
  }
}

class _MultiLevelPieChartLayout {
  final double startAngle;
  final double sweepAngle;
  final double radius;
  final double width;
  final bool isSelected;

  _MultiLevelPieChartLayout({
    required this.startAngle,
    required this.sweepAngle,
    required this.radius,
    required this.width,
    this.isSelected = false,
  });
}

class CategoryNotFoundException implements Exception {}
