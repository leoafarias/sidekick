import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart'
    hide ImplicitlyAnimatedWidget, ImplicitlyAnimatedWidgetState;
import 'package:flutter/services.dart';

import '../material_floating_search_bar_2.dart';

import 'floating_search_bar_dismissable.dart';
import 'search_bar_style.dart';
import 'text_controller.dart';
import 'util/util.dart';
import 'widgets/widgets.dart';

part 'floating_search_app_bar.dart';

// ignore_for_file: public_member_api_docs

typedef FloatingSearchBarBuilder = Widget Function(
    BuildContext context, Animation<double> transition);

/// An expandable material floating search bar with customizable
/// transitions similar to the ones used extensively
/// by Google in their apps.
class FloatingSearchBar extends ImplicitlyAnimatedWidget {
  const FloatingSearchBar({
    Key? key,
    Duration implicitDuration = const Duration(milliseconds: 600),
    Curve implicitCurve = Curves.linear,
    this.body,
    this.accentColor,
    this.backgroundColor,
    this.shadowColor = Colors.black87,
    this.iconColor,
    this.backdropColor,
    this.margins,
    this.padding,
    this.insets,
    this.height = 48.0,
    this.elevation = 4.0,
    this.width,
    this.openWidth,
    this.axisAlignment = 0.0,
    this.openAxisAlignment,
    this.border,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.hintStyle,
    this.queryStyle,
    this.clearQueryOnClose = true,
    this.automaticallyImplyDrawerHamburger = true,
    this.automaticallyImplyBackButton = true,
    this.closeOnBackdropTap = true,
    this.progress = false,
    this.transitionDuration = const Duration(milliseconds: 500),
    this.transitionCurve = Curves.ease,
    this.debounceDelay = Duration.zero,
    this.title,
    this.hint = 'Search...',
    this.actions,
    this.leadingActions,
    this.onQueryChanged,
    this.onSubmitted,
    this.onFocusChanged,
    this.transition,
    required this.builder,
    this.controller,
    this.textInputAction = TextInputAction.search,
    this.textInputType = TextInputType.text,
    this.autocorrect = true,
    this.contextMenuBuilder,
    Duration? showAfter,
    this.isScrollControlled = false,
    this.physics,
    this.scrollController,
    this.scrollPadding = const EdgeInsets.symmetric(vertical: 16),
    this.showCursor = true,
    bool initiallyHidden = false,
    this.onKeyEvent,
  })  : showAfter =
            showAfter ?? (initiallyHidden ? const Duration(days: 1) : null),
        super(key, implicitDuration, implicitCurve);

  /// The widget displayed below the `FloatingSearchBar`.
  ///
  /// This is useful, if the `FloatingSearchBar` should react
  /// to scroll events (i.e. hide from view when a [Scrollable]
  /// is being scrolled down and show it again when scrolled up).
  final Widget? body;
  // * --- Style properties --- *

  /// The color used for elements such as the progress
  /// indicator.
  ///
  /// Defaults to the themes accent color if not specified.
  final Color? accentColor;

  /// The color of the card.
  ///
  /// If not specified, defaults to `theme.cardColor`.
  final Color? backgroundColor;

  /// The color of the shadow drawn when `elevation > 0`.
  ///
  /// If not specified, defaults to `Colors.black54`.
  final Color? shadowColor;

  /// When specified, overrides the themes icon color for
  /// this `FloatingSearchBar`, for example to easily adjust
  /// the icon color for all [actions] and [leadingActions].
  final Color? iconColor;

  /// The color that fills the available space when the
  /// `FloatingSearchBar` is opened.
  ///
  /// Typically a black-ish color.
  ///
  /// If not specified, defaults to `Colors.black26`.
  final Color? backdropColor;

  /// The insets from the edges of its parent.
  ///
  /// This can be used to position the `FloatingSearchBar`.
  ///
  /// If not specifed, the `FloatingSearchBar` will try to
  /// position itself at the top offsetted by
  /// `MediaQuery.of(context).viewPadding.top` to avoid
  /// the status bar.
  final EdgeInsetsGeometry? margins;

  /// The padding of the card.
  ///
  /// Only the horizontal values will be honored.
  final EdgeInsetsGeometry? padding;

  /// The padding between [leadingActions], the input field and [actions],
  /// respectively.
  ///
  /// Only the horizontal values will be honored.
  final EdgeInsetsGeometry? insets;

  /// The height of the card.
  ///
  /// If not specified, defaults to `48.0` pixels.
  final double height;

  /// The elevation of the card.
  ///
  /// See also:
  /// * [shadowColor] to adjust the color of the shadow.
  final double elevation;

  /// The max width of the `FloatingSearchBar`.
  ///
  /// By default the `FloatingSearchBar` will expand
  /// to fill all the available width. This value can
  /// be set to avoid this.
  final double? width;

  /// The max width of the `FloatingSearchBar` when opened.
  ///
  /// This can be used, when the max width when opened should
  /// be different from the one specified by [width].
  ///
  /// When not specified, will use the value of [width].
  final double? openWidth;

  /// How the `FloatingSearchBar` should be aligned when the
  /// available width is bigger than the width specified by [width].
  ///
  /// When not specified, defaults to `0.0` which centers
  /// the `FloatingSearchBar`.
  final double? axisAlignment;

  /// How the `FloatingSearchBar` should be aligned when the
  /// available width is bigger than the width specified by [openWidth].
  ///
  /// When not specified, will use the value of [axisAlignment].
  final double? openAxisAlignment;

  /// The border of the card.
  final BorderSide? border;

  /// The [BorderRadius] of the card.
  ///
  /// When not specified, defaults to `BorderRadius.circular(4)`.
  final BorderRadius? borderRadius;

  /// The [TextStyle] for the hint in the [TextField].
  final TextStyle? hintStyle;

  /// The [TextStyle] for the input of the [TextField].
  final TextStyle? queryStyle;

  // * --- Utility --- *
  /// {@template floating_search_bar.clearQueryOnClose}
  /// Whether the current query should be cleared when
  /// the `FloatingSearchBar` was closed.
  ///
  /// When not specifed, defaults to `true`.
  /// {@endtemplate}
  final bool clearQueryOnClose;

  /// {@template floating_search_bar.automaticallyImplyDrawerHamburger}
  /// Whether a hamburger menu should be shown when
  /// there is a [Scaffold] with a [Drawer] in the widget
  /// tree.
  ///
  /// When not specified, defaults to `true`.
  /// {@endtemplate}
  final bool automaticallyImplyDrawerHamburger;

  /// {@template floating_search_bar.automaticallyImplyBackButton}
  /// Whether to automatically display a back button if the enclosing route
  /// can be popped.
  ///
  /// When not specified, defaults to `true`.
  /// {@endtemplate}
  final bool automaticallyImplyBackButton;

  /// Whether the `FloatingSearchBar` should be closed when
  /// the backdrop was tapped.
  ///
  /// When not specified, defaults to `true`.
  final bool closeOnBackdropTap;

  /// {@template floating_search_bar.progress}
  /// The progress of the [LinearProgressIndicator] inside the bar.
  ///
  /// When set to a `double` between [0..1], will show
  /// show a determined [LinearProgressIndicator].
  ///
  /// When set to `true`, the `FloatingSearchBar` will
  /// show an indetermined [LinearProgressIndicator].
  ///
  /// When `null` or `false`, will hide the [LinearProgressIndicator].
  /// {@endtemplate}
  final dynamic progress;

  /// {@template floating_search_bar.transitionDuration}
  /// The duration of the animation between opened and closed
  /// state.
  /// {@endtemplate}
  final Duration transitionDuration;

  /// {@template floating_search_bar.transitionCurve}
  /// The curve for the animation between opened and closed
  /// state.
  /// {@endtemplate}
  final Curve transitionCurve;

  /// {@template floating_search_bar.debounceDelay}
  /// The delay between the time the user stopped typing
  /// and the invocation of the [onQueryChanged] callback.
  ///
  /// This is useful for example if you want to avoid doing
  /// expensive tasks, such as making a network call, for every
  /// single character.
  /// {@endtemplate}
  final Duration debounceDelay;

  /// {@template floating_search_bar.title}
  /// A widget that is shown in place of the [TextField] when the
  /// `FloatingSearchBar` is closed.
  /// {@endtemplate}
  final Widget? title;

  /// {@template floating_search_bar.hint}
  /// The text value of the hint of the [TextField].
  /// {@endtemplate}
  final String? hint;

  /// {@template floating_search_bar.actions}
  /// A list of widgets displayed in a row after the [TextField].
  ///
  /// Consider using [FloatingSearchBarAction]s for more advanced
  /// actions that can interact with the `FloatingSearchBar`.
  ///
  /// In LTR languages, they will be displayed to the left of
  /// the [TextField].
  /// {@endtemplate}
  final List<Widget>? actions;

  /// {@template floating_search_bar.leadingActions}
  /// A list of widgets displayed in a row before the [TextField].
  ///
  /// Consider using [FloatingSearchBarAction]s for more advanced
  /// actions that can interact with the `FloatingSearchBar`.
  ///
  /// In LTR languages, they will be displayed to the right of
  /// the [TextField].
  /// {@endtemplate}
  final List<Widget>? leadingActions;

  /// {@template floating_search_bar.onQueryChanged}
  /// A callback that gets invoked when the input of
  /// the query inside the [TextField] changed.
  ///
  /// See also:
  ///   * [debounceDelay] to delay the invocation of the callback
  ///   until the user stopped typing.
  /// {@endtemplate}
  final OnQueryChangedCallback? onQueryChanged;

  /// {@template floating_search_bar.onSubmitted}
  /// A callback that gets invoked when the user submitted
  /// their query (e.g. hit the search button).
  /// {@endtemplate}
  final OnQueryChangedCallback? onSubmitted;

  /// {@template floating_search_bar.onFocusChanged}
  /// A callback that gets invoked when the `FloatingSearchBar`
  /// receives or looses focus.
  /// {@endtemplate}
  final OnFocusChangedCallback? onFocusChanged;

  /// The transition to be used for animating between closed
  /// and opened state.
  ///
  /// See also:
  ///  * [FloatingSearchBarTransition], which is the base class for all transitions
  ///    and can be used to create your own custom transition.
  ///  * [ExpandingFloatingSearchBarTransition], which expands to eventually fill
  ///    all of its available space, similar to the ones in Gmail or Google Maps.
  ///  * [CircularFloatingSearchBarTransition], which clips its child in an
  ///    expanding circle while animating.
  ///  * [SlideFadeFloatingSearchBarTransition], which fades and translate its
  ///    child.
  final FloatingSearchBarTransition? transition;

  /// The builder for the body of this `FloatingSearchBar`.
  ///
  /// Usually, a list of items. Note that unless [isScrollControlled]
  /// is set to `true`, the body of a `FloatingSearchBar` must not
  /// have an unbounded height meaning that `shrinkWrap` should be set
  /// to `true` on all [Scrollable]s.
  final FloatingSearchBarBuilder builder;

  /// {@template floating_search_bar.controller}
  /// The controller for this `FloatingSearchBar` which can be used
  /// to programatically open, close, show or hide the `FloatingSearchBar`.
  /// {@endtemplate}
  final FloatingSearchBarController? controller;

  /// {@template floating_search_bar.textInputAction}
  /// The [TextInputAction] to be used by the [TextField]
  /// of this `FloatingSearchBar`.
  /// {@endtemplate}
  final TextInputAction textInputAction;

  /// {@template floating_search_bar.textInputType}
  /// The [TextInputType] of the [TextField]
  /// of this `FloatingSearchBar`.
  /// {@endtemplate}
  final TextInputType textInputType;

  /// {@template floating_search_bar.autocorrect}
  /// Enable or disable autocorrection of the [TextField] of
  /// this `FloatingSearchBar`.
  /// {@endtemplate}
  final bool autocorrect;

  /// {@template floating_search_bar. contextMenuBuilder}
  /// The [EditableTextContextMenuBuilder] of the [TextField] of
  /// this `FloatingSearchBar`.
  /// {@endtemplate}
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// Hides the `FloatingSearchBar` intially for the specified
  /// duration and then translates it from the top to its position.
  ///
  /// This can be used as a simple enrance animation.
  final Duration? showAfter;

  // * --- Scrolling --- *
  /// Whether the builder of this `FloatingSearchBar` is using its
  /// own [Scrollable].
  ///
  /// This will allow the body of the `FloatingSearchBar` to have an
  /// unbounded height.
  ///
  ///
  /// to dismiss itself when tapped below the height of child inside the
  /// [Scrollable], when the child is smaller than the avaialble height.
  final bool isScrollControlled;

  /// The [ScrollPhysics] of the [SingleChildScrollView] for the body of
  /// this `FloatingSearchBar`.
  final ScrollPhysics? physics;

  /// The [ScrollController] of the [SingleChildScrollView] for the body of
  /// this `FloatingSearchBar`.
  final ScrollController? scrollController;

  /// To show the cursor in the textfield or not
  final bool showCursor;

  /// Allow processing any keypress into the input text.
  final ValueChanged<KeyEvent>? onKeyEvent;

  /// The [EdgeInsets] of the [SingleChildScrollView] holding the expandable body of
  /// this `FloatingSearchBar`.
  final EdgeInsets scrollPadding;

  @override
  FloatingSearchBarState createState() => FloatingSearchBarState();

  static FloatingSearchBarState? of(BuildContext context) {
    return context.findAncestorStateOfType<FloatingSearchBarState>();
  }
}

class FloatingSearchBarState extends ImplicitlyAnimatedWidgetState<
    FloatingSearchBarStyle, FloatingSearchBar> {
  final GlobalKey<FloatingSearchAppBarState> barKey = GlobalKey();
  FloatingSearchAppBarState? get barState => barKey.currentState;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: duration,
  )..addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        _onClosed();
      }
    });

  late CurvedAnimation animation =
      CurvedAnimation(parent: _controller, curve: curve);

  late final AnimationController _translateController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  late CurvedAnimation _translateAnimation = CurvedAnimation(
    parent: _translateController,
    curve: Curves.easeInOut,
  );

  late Widget body;
  final ValueNotifier<int> rebuilder = ValueNotifier<int>(0);

  late FloatingSearchBarTransition transition =
      widget.transition ?? SlideFadeFloatingSearchBarTransition();
  late ScrollController _scrollController =
      widget.scrollController ?? ScrollController();

  dynamic get progress => widget.progress;

  FloatingSearchBarStyle get style => value;

  Widget? get title => widget.title;
  String get hint => widget.hint?.toString() ?? '';

  Curve get curve => widget.transitionCurve;
  Duration get duration => widget.transitionDuration;
  Duration get queryCallbackDelay => widget.debounceDelay;

  bool get isOpen => barState?.isOpen ?? false;
  set isOpen(bool value) {
    if (value != isOpen) {
      barState?.isOpen = value;
    }
    value ? _controller.forward() : _controller.reverse();
  }

  bool get isVisible => _translateController.isDismissed;
  set isVisible(bool value) {
    if (value == isVisible) {
      return;
    }

    // Only hide the bar when it is not opened.
    if (!isOpen) {
      value ? _translateController.reverse() : _translateController.forward();
    }
  }

  void rebuild() => rebuilder.value++;

  double _offset = 0.0;
  double get offset => _offset;

  double get v => animation.value;
  bool get isAnimating => _controller.isAnimating;

  @override
  void initState() {
    super.initState();

    if (widget.showAfter != null) {
      _translateController.value = 1.0;

      if (widget.showAfter! < const Duration(days: 1)) {
        Future<void>.delayed(widget.showAfter!, show);
      }
    }

    transition = widget.transition ?? SlideFadeFloatingSearchBarTransition();
    transition.searchBar = this;

    _assignController();

    postFrame(rebuild);
  }

  @override
  void didUpdateWidget(FloatingSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (curve != oldWidget.transitionCurve) {
      animation = CurvedAnimation(parent: _controller, curve: curve);
    }

    if (duration != oldWidget.transitionDuration) {
      _controller.duration = duration;
    }

    if (widget.transition != null) {
      transition = widget.transition!;
      transition.searchBar = this;
    }

    if (widget.scrollController != null &&
        widget.scrollController != _scrollController) {
      _scrollController = widget.scrollController!;
    }

    _assignController();
  }

  void _assignController() => widget.controller?._searchBarState = this;

  void show() => isVisible = true;
  void hide() => isVisible = false;

  void open() => isOpen = true;
  void close() => isOpen = false;

  Future<bool> _onPop() async {
    if (isOpen) {
      close();
      return false;
    }

    return true;
  }

  void _onClosed() {
    _offset = 0.0;

    if (!widget.isScrollControlled) {
      _scrollController.jumpTo(0.0);
    }
  }

  EdgeInsets _resolve(EdgeInsetsGeometry insets) =>
      insets.resolve(Directionality.of(context));

  bool _onBuilderScroll(ScrollNotification notification) {
    _offset = notification.metrics.pixels;
    transition.onBodyScrolled();
    return false;
  }

  double _lastPixel = 0.0;

  void _setTranslateCurve(Curve curve) {
    _translateAnimation = CurvedAnimation(
      parent: _translateController,
      curve: curve,
    );
  }

  bool _onBodyScroll(FloatingSearchBarScrollNotification notification) {
    if (_controller.isDismissed) {
      final double pixel = notification.metrics.pixels;
      final bool didReleasePointer = pixel == _lastPixel;

      if (didReleasePointer) {
        _setTranslateCurve(Curves.easeInOutCubic);
        final bool hide = pixel > 0.0 && _translateController.value > 0.5;
        hide ? _translateController.forward() : _translateController.reverse();
      } else {
        _setTranslateCurve(Curves.linear);

        final double delta = pixel - _lastPixel;

        // ScrollView jumped, do nothing in this case.
        if (delta.abs() > 100) {
          _lastPixel = pixel;
          return false;
        }

        _translateController.value +=
            delta / (style.height + style.margins.top);
        _lastPixel = pixel;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    transition.searchBar = this;
    body = widget.builder(context, animation);

    final SizedBox searchBar = SizedBox.expand(
      child: isAvailableSwipeBack
          ? _getSearchBarWidget()
          : WillPopScope(
              onWillPop: _onPop,
              child: _getSearchBarWidget(),
            ),
    );

    if (widget.body != null) {
      final NotificationListener<FloatingSearchBarScrollNotification> body =
          NotificationListener<FloatingSearchBarScrollNotification>(
        onNotification: _onBodyScroll,
        child: widget.body!,
      );

      return Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: <Widget>[
          body,
          RepaintBoundary(
            child: searchBar,
          ),
        ],
      );
    } else {
      return searchBar;
    }
  }

  NotificationListener<ScrollNotification> _getSearchBarWidget() {
    return NotificationListener<ScrollNotification>(
      onNotification: _onBuilderScroll,
      child: ValueListenableBuilder<int>(
        valueListenable: rebuilder,
        builder: (BuildContext context, __, _) => AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, _) => Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              _buildBackdrop(),
              _buildSearchBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final EdgeInsets padding = _resolve(transition.lerpPadding());
    final BorderRadius borderRadius = transition.lerpBorderRadius();

    final Semantics container = Semantics(
      hidden: !isVisible,
      focusable: true,
      focused: isOpen,
      child: Padding(
        padding: transition.lerpMargin(),
        child: AnimatedBuilder(
          animation: CurvedAnimation(
            parent: _translateAnimation,
            curve: const Interval(0.95, 1.0),
          ),
          builder: (BuildContext context, Widget? child) => Material(
            elevation: transition.lerpElevation() *
                (1.0 - interval(0.95, 1.0, _translateAnimation.value)),
            shadowColor: style.shadowColor,
            borderRadius: borderRadius,
            child: child,
          ),
          child: Container(
            width: transition.lerpWidth(),
            height: transition.lerpHeight(),
            padding: EdgeInsets.only(top: padding.top, bottom: padding.bottom),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: transition.lerpBackgroundColor(),
              border: Border.fromBorderSide(style.border),
              borderRadius: borderRadius,
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: _buildInnerBar(),
            ),
          ),
        ),
      ),
    );

    final SlideTransition bar = SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0.0, -1.0),
      ).animate(_translateAnimation),
      child: container,
    );

    return AnimatedAlign(
      duration: isAnimating ? duration : Duration.zero,
      curve: widget.transitionCurve,
      alignment: Alignment(
          isOpen ? style.openAxisAlignment : style.axisAlignment, -1.0),
      child: transition.isBodyInsideSearchBar
          ? bar
          : Column(
              children: <Widget>[
                bar,
                Expanded(child: _buildBody()),
              ],
            ),
    );
  }

  Widget _buildInnerBar() {
    final FloatingSearchAppBar textField = FloatingSearchAppBar(
      showCursor: widget.showCursor,
      body: null,
      key: barKey,
      height: 1000,
      controller: widget.controller,
      color: transition.lerpBackgroundColor(),
      onFocusChanged: (bool isFocused) {
        isOpen = isFocused;
        widget.onFocusChanged?.call(isFocused);
      },
      implicitDuration: widget.duration,
      implicitCurve: widget.curve,
      title: widget.title,
      actions: widget.actions,
      leadingActions: widget.leadingActions,
      autocorrect: widget.autocorrect,
      clearQueryOnClose: widget.clearQueryOnClose,
      debounceDelay: widget.debounceDelay,
      hint: widget.hint,
      onQueryChanged: widget.onQueryChanged,
      onSubmitted: widget.onSubmitted,
      progress: widget.progress,
      automaticallyImplyDrawerHamburger:
          widget.automaticallyImplyDrawerHamburger,
      automaticallyImplyBackButton: widget.automaticallyImplyBackButton,
      contextMenuBuilder: widget.contextMenuBuilder,
      transitionDuration: widget.transitionDuration,
      transitionCurve: widget.transitionCurve,
      textInputAction: widget.textInputAction,
      textInputType: widget.textInputType,
      accentColor: widget.accentColor,
      hintStyle: widget.hintStyle,
      iconColor: widget.iconColor,
      insets: style.insets,
      padding: style.padding,
      titleStyle: widget.queryStyle,
      shadowColor: style.shadowColor,
      onKeyEvent: widget.onKeyEvent,
    );

    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: <Widget>[
          if (transition.isBodyInsideSearchBar && v > 0.0)
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(top: style.height),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _buildBody(),
                ),
              ),
            ),
          Material(
            elevation: transition.lerpInnerElevation(),
            shadowColor: style.shadowColor,
            child: Container(
              height: style.height,
              color: transition.lerpBackgroundColor(),
              alignment: Alignment.topCenter,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: <Widget>[
                  SizedBox(
                    width: transition.lerpInnerWidth(),
                    child: textField,
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: transition.buildDivider(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final Widget body = transition.buildTransition(
      widget.isScrollControlled
          ? this.body
          : FloatingSearchBarDismissable(
              controller: _scrollController,
              padding: widget.scrollPadding,
              physics: widget.physics,
              child: this.body,
            ),
    );

    return IgnorePointer(
      ignoring: v < 1.0,
      child: SizedBox(
        width: (transition.isBodyInsideSearchBar
                ? transition.lerpInnerWidth()
                : transition.lerpWidth()) +
            transition.lerpMargin().horizontal,
        child: body,
      ),
    );
  }

  Widget _buildBackdrop() {
    if (v == 0.0) {
      return const SizedBox(height: 0);
    }

    return FadeTransition(
      opacity: animation,
      child: GestureDetector(
        onTap: () {
          if (widget.closeOnBackdropTap) {
            close();
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: style.backdropColor,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    widget.controller?._searchBarState = null;

    super.dispose();
  }

  // * Implicit stuff

  @override
  FloatingSearchBarStyle get newValue {
    final ThemeData theme = Theme.of(context);
    final TextDirection direction = Directionality.of(context);

    return FloatingSearchBarStyle(
      height: widget.height,
      elevation: widget.elevation,
      maxWidth: widget.width,
      openMaxWidth: widget.openWidth,
      axisAlignment: widget.axisAlignment ?? 0.0,
      openAxisAlignment:
          widget.openAxisAlignment ?? widget.axisAlignment ?? 0.0,
      backgroundColor: widget.backgroundColor ?? theme.cardColor,
      shadowColor: widget.shadowColor ?? Colors.black45,
      backdropColor: widget.backdropColor ??
          widget.transition?.backdropColor ??
          Colors.black26,
      border: widget.border ?? BorderSide.none,
      borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
      margins: (widget.margins ??
              EdgeInsets.fromLTRB(
                  8, MediaQuery.of(context).viewPadding.top + 6, 8, 0))
          .resolve(direction),
      padding: widget.padding?.resolve(direction) ??
          const EdgeInsets.symmetric(horizontal: 12),
      insets: widget.insets?.resolve(direction) ??
          const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  @override
  FloatingSearchBarStyle lerp(
          FloatingSearchBarStyle a, FloatingSearchBarStyle b, double t) =>
      a.scaleTo(b, t);
}

/// A controller for a [FloatingSearchBar].
class FloatingSearchBarController {
  /// Creates a controller for a [FloatingSearchBar].
  FloatingSearchBarController();

  FloatingSearchAppBarState? _appBarState;
  FloatingSearchBarState? _searchBarState;

  /// Opens/Expands the [FloatingSearchBar].
  void open() => _appBarState?.open();

  /// Closes/Collapses the [FloatingSearchBar].
  void close() => _appBarState?.close();

  /// Visually reveals the [FloatingSearchBar] when
  /// it was previously hidden via [hide].
  void show() => _searchBarState?.show();

  /// Visually hides the [FloatingSearchBar].
  void hide() => _searchBarState?.hide();

  /// Sets the query of the input of the [FloatingSearchBar].
  set query(String query) {
    if (_appBarState == null) {
      postFrame(() => _appBarState?.query = query);
    } else {
      _appBarState?.query = query;
    }
  }

  /// The current query of the [FloatingSearchBar].
  String get query => _appBarState?.query ?? '';

  /// Cleares the current query.
  void clear() => _appBarState?.clear();

  /// Whether the [FloatingSearchBar] is currently
  /// opened/expanded.
  bool get isOpen => _appBarState?.isOpen ?? false;

  /// Whether the [FloatingSearchBar] is currently
  /// closed/collapsed.
  bool get isClosed => _appBarState?.isOpen == false;

  /// Whether the [FloatingSearchBar] is currently
  /// not hidden.
  bool get isVisible => _searchBarState?.isVisible ?? false;

  /// Whether the [FloatingSearchBar] is currently
  /// not visible.
  bool get isHidden => _searchBarState?.isVisible == false;

  /// Disposes this controller.
  void dispose() {
    _searchBarState = null;
    _appBarState = null;
  }
}
