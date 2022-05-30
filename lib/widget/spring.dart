import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Spring extends StatefulWidget {
  const Spring({Key? key}) : super(key: key);
  /// 默认spring高度
  final double _kDefaultSpringHeight = 100;

  /// 移动的距离和形变脸的比例
  final double _kRateOfMove = 1.5;

  @override
  State<Spring> createState() => _SpringState();
}

class _SpringState extends State<Spring> with SingleTickerProviderStateMixin {

  late final ValueNotifier<double> height;
  final double _containerHeight = 200;
  final double _containerWidth = 200;
  double lastMoveLen = 0;
  double s = 0; // 移动距离
  late Animation<double> animation;
  final Duration animationDuration = const Duration(milliseconds: 400);
  late final AnimationController _animationController = AnimationController(vsync: this, duration: animationDuration);

  @override
  void initState() {
    super.initState();
    height = ValueNotifier(widget._kDefaultSpringHeight);
    _animationController.addListener(_updateHeightByAnimation);
    animation = CurvedAnimation(parent: _animationController, curve: const Interpolator());
  }

  @override
  void dispose() {
    height.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _containerWidth,
      height: _containerHeight,
      color: Colors.grey.withAlpha(11),
      child: GestureDetector(
        onVerticalDragUpdate: _updateSpace,
        onVerticalDragCancel: onDragCancel,
        onVerticalDragEnd: _animateToDefault,
        child: CustomPaint(
          painter: SpringPainter(
            height: height,
          ),
        ),
      ),
    );
  }

  void _updateSpace(DragUpdateDetails details) {
    final currentS = s;
    s += details.delta.dy;
    final updateHeight = widget._kDefaultSpringHeight + dx;
    if(updateHeight > _containerHeight || updateHeight < 0) {
      s = currentS;
      return;
    }
    height.value = widget._kDefaultSpringHeight + dx;

  }

  void onDragCancel() => print('cancel');

  void _updateHeightByAnimation() {
    /// animation controller的 value 从 0 -> 1
    s = lastMoveLen * (1 - _animationController.value);
    height.value = widget._kDefaultSpringHeight + dx;
  }

  void _animateToDefault(DragEndDetails details) {
    lastMoveLen = s;
    _animationController.forward(from: 0);
  }

  double get dx => -s/widget._kRateOfMove;
}


class SpringPainter extends CustomPainter {
  final int count;
  final ValueListenable<double> height;
  final double _kSpringWidth = 30;
  late final _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  SpringPainter({this.count = 20, required this.height}): super(repaint: height);

  @override
  void paint(Canvas canvas, Size size) {

    /// 拿到当前的size的一半 + spring的一半宽度作为x（这样做是因为spring是从右边绘向左边，
    /// 其实的起点还要+上spring的一半宽度是因为我们需要确保spring的绘制始终在container中间）
    /// 从底部开始绘画 所以用size.height
    canvas.translate(size.width / 2 + _kSpringWidth / 2, size.height);

    Path springPath = Path();
    /// 当前的 0 已经是 size的height的一半 + spring的宽度的一半， 所以使用 -spring的宽度能够让spring的第一条线是处于container的一半
    springPath.relativeLineTo(-_kSpringWidth, 0);

    /// 假设 一个spring只有3跳线，他的空间应该只有2个
    /// 我们计算空间的方式就是 现将线的总数 - 1 拿到空间的数量/ 我们拥有的空间大小
    /// exp: 100 /(3-1)
    double space = height.value / (count - 1);

    /// flutter canvas 的特性是 绘制完了之后不会回到起始的点，这点和js的canvas不同
    for(int i =1; i < count; i++) {
      /// 判断是单数或者双数
      if(i.isOdd) {
        /// 如果是单数 是从右往左边绘制
        /// 所以这时我们的x是spring的宽度，因为我们是往上绘制所以y是计算好的每个count然后给予负数
        springPath.relativeLineTo(_kSpringWidth, -space);
      } else {
        /// 反之，从左边向右边绘制
        springPath.relativeLineTo(-_kSpringWidth, -space);
      }
    }

    /// 因为结尾的spring不需要往上绘制只需要直线，所以y是0， 然而我们要判断 count是双数或者单数
    /// 单数就往右边向左边绘制，反之左边向右边绘制
    springPath.relativeLineTo(count.isOdd ? _kSpringWidth: -_kSpringWidth, 0);
    /// 确定好了绘制逻辑讲我们的path和paint交给canvas渲染
    canvas.drawPath(springPath, _paint);

  }

  @override
  bool shouldRepaint(SpringPainter oldDelegate) =>
      oldDelegate.height != height || oldDelegate.count != count;

}


class Interpolator extends Curve {
  const Interpolator();

  @override
  double transform(double t) {
   t -= 1.0;
   return t * t * t * t * t + 1.0;
  }
}
