import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_banner/src/indicators_widget.dart';

import '../flutter_banner.dart';

typedef ItemBuilder = Widget Function(BuildContext context, dynamic value);

class KBanner extends StatefulWidget {
  const KBanner({Key? key, required this.banners, required this.itemBuilder, this.activeColor, this.disableColor, this.aspectRatio, this.onPageChanged}) : super(key: key);

  final List banners;
  final ItemBuilder itemBuilder;

  final Color? activeColor;

  final Color? disableColor;
  final double? aspectRatio;

  final ValueChanged? onPageChanged;

  @override
  _KBannerState createState() => _KBannerState();
}

class _KBannerState extends State<KBanner> with WidgetsBindingObserver {
  late PageController _controller;

  var currentIndex = 1;
  var realPosition = 0;

  Timer? _timer;

  ///重新生成banner数据
  List<dynamic> get _banners => initValues(widget.banners);

  Color get _activeColor => widget.activeColor ?? Colors.white;

  Color get _disableColor => widget.disableColor ?? Color(0xFFC2C2C2);

  List<Widget> get rowIndicator => List.filled(_banners.length - 2, 0)
      .asMap()
      .entries
      .map(
        (e) => CarouselIndicatorWidget(
          key: Key("Indicator${e.key}"),
          active: realPosition == e.key,
          color: realPosition == e.key ? _activeColor : _disableColor,
          animation: true,
          sizeIndicator: IndicatorModel.animation(width: 8, height: 8, spaceBetween: 3.0),
        ),
      )
      .toList();

  @override
  void initState() {
    super.initState();
    _controller = PageController(keepPage: true, initialPage: 1);
    WidgetsBinding.instance?.addObserver(this);
    _start();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio ?? 2.5,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          NotificationListener(
            onNotification: onNotification,
            child: PageView.builder(
              controller: _controller,
              itemBuilder: (context, index) => widget.itemBuilder(context, _banners[index]),
              onPageChanged: _onChangePage,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: rowIndicator,
            ),
          ),
        ],
      ),
    );
  }

  /// Method for when to change the page
  /// returning an integer value
  Future<void> _onChangePage(int index) async {
    widget.onPageChanged?.call(_banners[index]);
    if (index == 0) {
      //当前选中的是第一个位置，自动选中倒数第二个位置
      currentIndex = _banners.length - 2;
      await Future.delayed(Duration(milliseconds: 200));
      _controller.jumpToPage(currentIndex);
      realPosition = currentIndex - 1;
    } else if (index == _banners.length - 1) {
      //当前选中的是倒数第一个位置，自动选中第二个索引
      currentIndex = 1;
      await Future.delayed(Duration(milliseconds: 200));
      _controller.jumpToPage(currentIndex);
      realPosition = 0;
    } else {
      currentIndex = index;
      realPosition = index - 1;
      if (realPosition < 0) realPosition = 0;
    }

    setState(() => realPosition);
  }

  ///初始化Value
  List<dynamic> initValues(List<dynamic> values) {
    final realValue = [];
    realValue.add(values.last);
    realValue.addAll(values);
    realValue.add(values.first);

    return realValue;
  }

  ///滑动监听
  bool onNotification(notification) {
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse) {
        _stop();
      }
      if (notification.direction == ScrollDirection.idle) {
        _start();
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive: // 处于这种状态的应用程序应该假设它们可能在任何时候暂停。
        break;
      case AppLifecycleState.resumed: //从后台切换前台，界面可见
        _start();
        break;
      case AppLifecycleState.paused: // 界面不可见，后台
        _stop();
        break;
      case AppLifecycleState.detached: // APP结束时调用
        break;
    }
  }

  ///创建定时器
  void createTimer() {
    cancelTimer();
    _timer = Timer.periodic(Duration(seconds: 3), (timer) => _scrollPage());
  }

  ///定时切换PageView的页面
  void _scrollPage() {
    ++currentIndex;
    var next = currentIndex % _banners.length;
    _controller.animateToPage(
      next,
      duration: kTabScrollDuration,
      curve: Curves.ease,
    );
  }

  ///开始定时滑动
  void _start() {
    if (_banners.length <= 1) return;
    createTimer();
  }

  ///停止定时滑动
  void _stop() {
    cancelTimer();
  }

  ///取消定时器
  void cancelTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    _stop();
    super.dispose();
  }
}
