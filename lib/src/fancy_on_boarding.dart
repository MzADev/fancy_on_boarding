library fancy_on_boarding;

import 'dart:async';
import 'package:fancy_on_boarding/src/page_dragger.dart';
import 'package:fancy_on_boarding/src/page_reveal.dart';
import 'package:fancy_on_boarding/src/page_model.dart';
import 'package:fancy_on_boarding/src/pager_indicator.dart';
import 'package:fancy_on_boarding/src/pages.dart';
import 'package:flutter/material.dart';

class FancyOnBoarding extends StatefulWidget {
  final List<PageModel> pageList;
  final VoidCallback onDoneButtonPressed;
  final VoidCallback onSkipButtonPressed;
  final String doneButtonText;
  final String skipButtonText;
  final bool showSkipButton;
  final Color color;
  final Icon nextIcon;

  FancyOnBoarding({
    @required this.pageList,
    @required this.onDoneButtonPressed,
    this.onSkipButtonPressed,
    this.doneButtonText = "Done",
    this.skipButtonText = "Skip",
    this.showSkipButton = true,
    this.color,
    @required this.nextIcon,
  }) : assert(pageList.length != 0 && onDoneButtonPressed != null);

  @override
  _FancyOnBoardingState createState() => _FancyOnBoardingState();
}

class _FancyOnBoardingState extends State<FancyOnBoarding>
    with TickerProviderStateMixin {
  StreamController<SlideUpdate> slideUpdateStream;
  AnimatedPageDragger animatedPageDragger;
  List<PageModel> pageList;
  int activeIndex = 0;
  int nextPageIndex = 0;
  SlideDirection slideDirection = SlideDirection.none;
  double slidePercent = 0.0;

  @override
  void initState() {
    super.initState();
    this.pageList = widget.pageList;
    this.slideUpdateStream = StreamController<SlideUpdate>();
    _listenSlideUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Page(
          model: pageList[activeIndex],
          percentVisible: 1.0,
        ),
        PageReveal(
          revealPercent: slidePercent,
          child: Page(
            model: pageList[nextPageIndex],
            percentVisible: slidePercent,
          ),
        ),
        PagerIndicator(
          viewModel: PagerIndicatorViewModel(
            pageList,
            activeIndex,
            slideDirection,
            slidePercent,
          ),
        ),
        PageDragger(
          pageLength: pageList.length - 1,
          currentIndex: activeIndex,
          canDragLeftToRight: activeIndex > 0,
          canDragRightToLeft: activeIndex < pageList.length - 1,
          slideUpdateStream: this.slideUpdateStream,
        ),
        Positioned(
          bottom: 20,
          right: 16,
          child: Opacity(
            opacity: _getOpacity(),
            child: GestureDetector(
              child: Container(
                  padding: EdgeInsets.all(8),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: widget.color),
                  child: widget.nextIcon),
              onTap: _getOpacity() == 1.0 ? widget.onDoneButtonPressed : () {},
            ),
          ),
        ),
        widget.showSkipButton
            ? Positioned(
                top: MediaQuery.of(context).padding.top,
                right: 0,
                child: FlatButton(
                  child: Text(
                    widget.skipButtonText,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w800),
                  ),
                  onPressed: widget.onSkipButtonPressed,
                ),
              )
            : Offstage()
      ],
    );
  }

  _listenSlideUpdate() {
    slideUpdateStream.stream.listen((SlideUpdate event) {
      setState(() {
        if (event.updateType == UpdateType.dragging) {
          print('Sliding ${event.direction} at ${event.slidePercent}');
          slideDirection = event.direction;
          slidePercent = event.slidePercent;

          if (slideDirection == SlideDirection.leftToRight) {
            nextPageIndex = activeIndex - 1;
          } else if (slideDirection == SlideDirection.rightToLeft) {
            nextPageIndex = activeIndex + 1;
          } else {
            nextPageIndex = activeIndex;
          }
        } else if (event.updateType == UpdateType.doneDragging) {
          print('Done dragging.');
          if (slidePercent > 0.5) {
            animatedPageDragger = AnimatedPageDragger(
              slideDirection: slideDirection,
              transitionGoal: TransitionGoal.open,
              slidePercent: slidePercent,
              slideUpdateStream: slideUpdateStream,
              vsync: this,
            );
          } else {
            animatedPageDragger = AnimatedPageDragger(
              slideDirection: slideDirection,
              transitionGoal: TransitionGoal.close,
              slidePercent: slidePercent,
              slideUpdateStream: slideUpdateStream,
              vsync: this,
            );
            nextPageIndex = activeIndex;
          }

          animatedPageDragger.run();
        } else if (event.updateType == UpdateType.animating) {
          print('Sliding ${event.direction} at ${event.slidePercent}');
          slideDirection = event.direction;
          slidePercent = event.slidePercent;
        } else if (event.updateType == UpdateType.doneAnimating) {
          print('Done animating. Next page index: $nextPageIndex');
          activeIndex = nextPageIndex;

          slideDirection = SlideDirection.none;
          slidePercent = 0.0;

          animatedPageDragger.dispose();
        }
      });
    });
  }

  double _getOpacity() {
    if (pageList.length - 2 == activeIndex &&
        slideDirection == SlideDirection.rightToLeft) return slidePercent;
    if (pageList.length - 1 == activeIndex &&
        slideDirection == SlideDirection.leftToRight) return 1 - slidePercent;
    if (pageList.length - 1 == activeIndex) return 1.0;
    return 0.0;
  }

  @override
  void dispose() {
    slideUpdateStream?.close();
    super.dispose();
  }
}
