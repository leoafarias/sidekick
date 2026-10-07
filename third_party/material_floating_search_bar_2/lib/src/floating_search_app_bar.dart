// ignore_for_file: public_member_api_docs

part of 'floating_search_bar.dart';

typedef OnQueryChangedCallback = void Function(String query);

typedef OnFocusChangedCallback = void Function(bool isFocused);

/// An [AppBar] with implemented search functionality and other
/// utility functions to implement a material behavior.
///
/// This can be considered the base Widget for the full
/// [FloatingSearchBar].
class FloatingSearchAppBar extends ImplicitlyAnimatedWidget {
  const FloatingSearchAppBar({
    Key? key,
    Duration implicitDuration = const Duration(milliseconds: 500),
    Curve implicitCurve = Curves.linear,
    required this.body,
    this.accentColor,
    this.color,
    this.colorOnScroll,
    this.shadowColor,
    this.iconColor,
    this.padding,
    this.insets,
    this.height = 56.0,
    this.elevation = 0.0,
    this.liftOnScrollElevation = 4.0,
    this.hintStyle,
    this.titleStyle,
    this.brightness,
    this.bottom,
    this.showCursor = true,
    this.alwaysOpened = false,
    this.clearQueryOnClose = true,
    this.automaticallyImplyDrawerHamburger = true,
    this.hideKeyboardOnDownScroll = false,
    this.automaticallyImplyBackButton = true,
    this.progress = 0.0,
    this.transitionDuration = const Duration(milliseconds: 500),
    this.transitionCurve = Curves.easeOut,
    this.debounceDelay = Duration.zero,
    this.title,
    this.hint = 'Search...',
    this.actions,
    this.leadingActions,
    this.onQueryChanged,
    this.onSubmitted,
    this.onFocusChanged,
    this.controller,
    this.textInputAction = TextInputAction.search,
    this.textInputType = TextInputType.text,
    this.autocorrect = true,
    this.contextMenuBuilder,
    this.onKeyEvent,
  })  : assert(progress == null || (progress is num || progress is bool)),
        super(key, implicitDuration, implicitCurve);

  /// to show the cursor or not
  final bool showCursor;

  /// The widget displayed below the [FloatingSearchAppBar]
  final Widget? body;

  // * --- Style properties --- *

  /// The accent color used for example for the
  /// progress indicator
  final Color? accentColor;

  /// The background color of the bar
  final Color? color;

  /// The color of the bar when a [Scrollable]
  /// inside the [body] was scrolled (i.e. is not at the top)
  final Color? colorOnScroll;

  /// The shadow color for the elevation
  final Color? shadowColor;

  /// Can be used to override the `IconThemeDatas` color
  final Color? iconColor;

  /// The padding of the bar
  final EdgeInsetsGeometry? padding;

  /// The horizontal spacing between [leadingActions], the input
  /// field and [actions]
  final EdgeInsetsGeometry? insets;

  /// The height of the bar
  ///
  /// Defaults to `56.0`
  final double? height;

  /// The elevation of the bar
  final double? elevation;

  /// The elevation of the bar when a [Scrollable]
  /// inside the [body] was scrolled (i.e. it's not at the top)
  final double liftOnScrollElevation;

  /// The [TextStyle] for the hint of the input field
  final TextStyle? hintStyle;

  /// The [TextStyle] for the title of the bar
  final TextStyle? titleStyle;

  /// The [Brightness] that is used for adjusting the
  /// status bar icon brightness.
  ///
  /// By default the brightness is dynamically calculated
  /// based on the brightness of the [color] or
  /// the [colorOnScroll] respectively.
  final Brightness? brightness;

  // * --- Utility --- *
  final Widget? bottom;

  /// Whether the bar should be always in opened state.
  ///
  /// This is useful for example, if you have a page
  /// dedicated only for search.
  final bool alwaysOpened;

  /// {@macro floating_search_bar.clearQueryOnClose}
  final bool clearQueryOnClose;

  /// {@macro floating_search_bar.automaticallyImplyDrawerHamburger}
  final bool automaticallyImplyDrawerHamburger;

  /// {@macro floating_search_bar.automaticallyImplyBackButton}
  final bool automaticallyImplyBackButton;

  /// Hides the keyboard a [Scrollable] inside the [body] was scrolled and
  /// shows it again when the user scrolls to the top.
  final bool hideKeyboardOnDownScroll;

  /// {@macro floating_search_bar.progress}
  final dynamic progress;

  /// {@macro floating_search_bar.transitionDuration}
  final Duration transitionDuration;

  /// {@macro floating_search_bar.transitionCurve}
  final Curve transitionCurve;

  /// {@macro floating_search_bar.debounceDelay}
  final Duration debounceDelay;

  /// {@macro floating_search_bar.title}
  final Widget? title;

  /// {@macro floating_search_bar.hint}
  final String? hint;

  /// {@macro floating_search_bar.actions}
  final List<Widget>? actions;

  /// {@macro floating_search_bar.leadingActions}
  final List<Widget>? leadingActions;

  /// {@macro floating_search_bar.onQueryChanged}
  final OnQueryChangedCallback? onQueryChanged;

  /// {@macro floating_search_bar.onSubmitted}
  final OnQueryChangedCallback? onSubmitted;

  /// {@macro floating_search_bar.onFocusChanged}
  final OnFocusChangedCallback? onFocusChanged;

  /// {@macro floating_search_bar.controller}
  final FloatingSearchBarController? controller;

  /// {@macro floating_search_bar.textInputAction}
  final TextInputAction textInputAction;

  /// {@macro floating_search_bar.textInputType}
  final TextInputType textInputType;

  /// {@macro floating_search_bar.autocorrect}
  final bool autocorrect;

  /// {@macro floating_search_bar. contextMenuBuilder}
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  final ValueChanged<KeyEvent>? onKeyEvent;

  static FloatingSearchAppBarState? of(BuildContext context) {
    return context.findAncestorStateOfType<FloatingSearchAppBarState>();
  }

  @override
  FloatingSearchAppBarState createState() => FloatingSearchAppBarState();
}

class FloatingSearchAppBarState extends ImplicitlyAnimatedWidgetState<
    FloatingSearchAppBarStyle, FloatingSearchAppBar> {
  final ValueNotifier<String> queryNotifer = ValueNotifier<String>('');
  final Handler _handler = Handler();

  late final AnimationController controller =
      AnimationController(vsync: this, duration: transitionDuration)
        ..value = isAlwaysOpened ? 1.0 : 0.0
        ..addListener(() => setState(() {}))
        ..addStatusListener((AnimationStatus status) {
          _setInsets();

          if (status == AnimationStatus.dismissed) {
            if (widget.clearQueryOnClose) {
              clear();
            }
          }
        });

  late CurvedAnimation transitionAnimation = CurvedAnimation(
    parent: controller,
    curve: widget.transitionCurve,
  );

  late final AnimationController scrollController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  )..addListener(() => setState(() {}));

  late final CurvedAnimation scrollAnimation = CurvedAnimation(
    parent: scrollController,
    curve: Curves.easeInOutCubic,
  );

  late final TextController _input = TextController()
    ..addListener(() {
      if (_input.text != queryNotifer.value) {
        queryNotifer.value = _input.text;

        _handler.post(
          // Do not add a delay when the query is empty.
          _input.text.isEmpty ? Duration.zero : widget.debounceDelay,
          () => widget.onQueryChanged?.call(_input.text),
        );
      }
    });

  bool _wasUnfocusedOnScroll = false;

  bool _isAtTop = true;
  bool get isAtTop => _isAtTop;

  bool get isAppBar => widget.body != null;
  bool get isAlwaysOpened => widget.alwaysOpened;
  double get _statusBarHeight => MediaQuery.of(context).viewPadding.top;

  Duration get transitionDuration => widget.transitionDuration;

  FloatingSearchAppBarStyle get style => value;
  Color get backgroundColor => Color.lerp(
        style.backgroundColor,
        style.colorOnScroll,
        scrollAnimation.value,
      )!;

  bool get hasActions => actions.isNotEmpty;
  List<Widget> get actions {
    final List<Widget> actions =
        widget.actions ?? <Widget>[FloatingSearchBarAction.searchToClear()];
    final bool showHamburger = widget.automaticallyImplyDrawerHamburger &&
        Scaffold.of(context).hasEndDrawer;
    return showHamburger
        ? <Widget>[
            ...actions,
            FloatingSearchBarAction.hamburgerToBack(isLeading: false)
          ]
        : actions;
  }

  bool get hasleadingActions => leadingActions.isNotEmpty;
  List<Widget> get leadingActions {
    final List<Widget> actions = widget.leadingActions ?? const <Widget>[];
    final bool showHamburger = widget.automaticallyImplyDrawerHamburger &&
        Scaffold.of(context).hasDrawer;

    Widget? leading;
    if (showHamburger) {
      leading = FloatingSearchBarAction.hamburgerToBack();
    } else if (widget.automaticallyImplyBackButton &&
        (Navigator.canPop(context) || widget.body != null)) {
      leading = FloatingSearchBarAction.back(
        showIfClosed: Navigator.canPop(context),
      );
    }

    return leading != null ? <Widget>[leading, ...actions] : actions;
  }

  bool _isOpen = false;
  bool get isOpen => _isOpen;
  set isOpen(bool value) {
    if (value) {
      () async {
        await controller.forward();
        focus();
      }();
    } else {
      unfocus();

      if (!widget.alwaysOpened) {
        controller.reverse();
      }
    }

    if (widget.alwaysOpened) {
      _isOpen = true;
      return;
    }

    if (value != isOpen) {
      _isOpen = value;
      widget.onFocusChanged?.call(isOpen);
    }
  }

  bool get hasFocus => _input.hasFocus;
  set hasFocus(bool value) => value ? focus() : unfocus();

  String get query => _input.text;
  set query(String value) => _input.text = value;

  @override
  void initState() {
    super.initState();
    if (isAlwaysOpened) {
      _isOpen = true;
      postFrame(_input.requestFocus);
    }

    _assignController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _setInsets();
  }

  @override
  void didUpdateWidget(FloatingSearchAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    controller.duration = transitionDuration;

    if (widget.transitionCurve != oldWidget.transitionCurve) {
      transitionAnimation = CurvedAnimation(
        parent: controller,
        curve: widget.transitionCurve,
      );
    }

    _assignController();
  }

  void open() => isOpen = true;
  void close() => isOpen = false;

  void focus() {
    _wasUnfocusedOnScroll = false;
    _input.requestFocus();
  }

  void unfocus() {
    _wasUnfocusedOnScroll = false;
    _input.clearFocus();
  }

  void clear() => _input.clear();

  void _assignController() => widget.controller?._appBarState = this;

  late EdgeInsets insets;
  void _setInsets() {
    bool hasActions(List<Widget> actions) {
      final List<Widget> active = List<Widget>.from(actions)
        ..retainWhere((Widget action) {
          if (action is FloatingSearchBarAction) {
            return isOpen ? action.showIfOpened : action.showIfClosed;
          } else {
            return true;
          }
        });

      return active.isNotEmpty;
    }

    final bool hasleadingActions = hasActions(leadingActions);
    final bool hasEndActions = hasActions(actions);

    final bool isDefaultPadding = style.padding.horizontal == 24.0;
    final double inset = isDefaultPadding ? 4.0 : 0.0;

    insets = EdgeInsets.lerp(
      style.insets.copyWith(
        left: !hasleadingActions ? inset : null,
        right: !hasEndActions ? inset : null,
      ),
      style.insets,
      transitionAnimation.value,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    if (isAppBar) {
      return _buildAppBar();
    } else {
      return _buildBar();
    }
  }

  Widget _buildAppBar() {
    final double height = style.height + _statusBarHeight;
    double prevPixels = 0.0;

    final Brightness brightness = widget.brightness ??
        (backgroundColor.computeLuminance() > 0.7
            ? Brightness.light
            : Brightness.dark);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: brightness == Brightness.dark
          ? const SystemUiOverlayStyle(
              statusBarBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.light)
          : const SystemUiOverlayStyle(
              statusBarBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.dark),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification.metrics.axis != Axis.vertical) {
            return false;
          }

          final double pixels = notification.metrics.pixels;

          if (widget.hideKeyboardOnDownScroll) {
            final bool isDown = pixels > prevPixels;
            if (isDown && hasFocus) {
              unfocus();
              _wasUnfocusedOnScroll = true;
            } else if (pixels <= 1.0 && _wasUnfocusedOnScroll && !hasFocus) {
              focus();
            }
          }

          final bool isAtTop = pixels < 1.0;
          if (isAtTop != _isAtTop) {
            _isAtTop = isAtTop;
            isAtTop ? scrollController.reverse() : scrollController.forward();
          }

          prevPixels = pixels;

          return false;
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: height),
              child: widget.body,
            ),
            _buildBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBar() {
    final double statusBarHeight = isAppBar ? _statusBarHeight : 0.0;
    final double elevation = lerpDouble(
      style.elevation,
      style.liftOnScrollElevation,
      scrollAnimation.value,
    )!;

    final GestureDetector bar = GestureDetector(
      onTap: () {
        if (isOpen) {
          hasFocus = !hasFocus;
          _input.moveCursorToEnd();
        } else if (!isAppBar) {
          isOpen = true;
        }
      },
      child: Material(
        color: backgroundColor,
        elevation: elevation,
        child: Container(
          height: style.height + statusBarHeight,
          padding: style.padding.add(EdgeInsets.only(top: statusBarHeight)),
          child: _buildInputAndActions(),
        ),
      ),
    );
    return isAvailableSwipeBack
        ? _getBarWidget(bar)
        : WillPopScope(
            onWillPop: () async {
              if (isOpen && !widget.alwaysOpened) {
                isOpen = false;
                return false;
              }
              return true;
            },
            child: _getBarWidget(bar),
          );
  }

  Stack _getBarWidget(GestureDetector bar) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        bar,
        _FloatingSearchProgressBar(
          progress: widget.progress,
          color: style.accentColor,
        ),
      ],
    );
  }

  Widget _buildInputAndActions() {
    final IconThemeData iconTheme =
        Theme.of(context).iconTheme.copyWith(color: style.iconColor);

    return Row(
      children: <Widget>[
        FloatingSearchActionBar(
          animation: transitionAnimation,
          actions: leadingActions,
          iconTheme: iconTheme,
        ),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: AlignmentDirectional.centerStart,
            children: <Widget>[
              _buildInputField(),
              buildGradient(isLeft: true),
              buildGradient(isLeft: false),
            ],
          ),
        ),
        FloatingSearchActionBar(
          animation: transitionAnimation,
          actions: actions,
          iconTheme: iconTheme,
        ),
      ],
    );
  }

  Widget buildGradient({required bool isLeft}) {
    return Align(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Transform.rotate(
        angle: isLeft ? pi : 0.0,
        child: Container(
          width: isLeft ? insets.left : insets.right,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                backgroundColor.withOpacity(0.0),
                backgroundColor.withOpacity(1.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    final Animation<double> animation =
        transitionAnimation.drive(ValleyingTween());

    final bool hasQuery = !widget.clearQueryOnClose && query.isNotEmpty;
    final bool showTitle =
        widget.title != null || (!hasQuery && query.isNotEmpty);
    final double opacity = showTitle ? animation.value : 1.0;

    final bool showTextInput =
        showTitle ? controller.value > 0.5 : controller.value > 0.0;

    Widget input;
    if (showTextInput) {
      input = KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: widget.onKeyEvent,
        child: IntrinsicWidth(
          child: TextField(
            controller: _input,
            showCursor: widget.showCursor,
            scrollPadding: EdgeInsets.zero,
            scrollPhysics: const NeverScrollableScrollPhysics(),
            focusNode: _input.node,
            autocorrect: widget.autocorrect,
            contextMenuBuilder: widget.contextMenuBuilder,
            cursorColor: style.accentColor,
            style: style.queryStyle,
            textInputAction: widget.textInputAction,
            keyboardType: widget.textInputType,
            onSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hint,
              hintStyle: style.hintStyle,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              errorBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
          ),
        ),
      );
    } else {
      if (widget.title != null) {
        input = widget.title!;

        if (isAppBar) {
          input = DefaultTextStyle(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).appBarTheme.toolbarTextStyle ??
                Theme.of(context).textTheme.titleLarge ??
                const TextStyle(),
            child: input,
          );
        }
      } else {
        final ThemeData theme = Theme.of(context);
        final TextTheme textTheme = theme.textTheme;

        final TextStyle? textStyle = hasQuery
            ? style.queryStyle ?? textTheme.titleMedium
            : style.hintStyle ??
                textTheme.titleMedium?.copyWith(color: theme.hintColor);

        input = Text(
          hasQuery ? query : widget.hint ?? '',
          style: textStyle,
          maxLines: 1,
        );
      }
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (_) => true,
      child: SingleChildScrollView(
        padding: insets,
        scrollDirection: Axis.horizontal,
        child: Opacity(
          opacity: opacity,
          child: input,
        ),
      ),
    );
  }

  @override
  void dispose() {
    queryNotifer.dispose();
    controller.dispose();
    scrollController.dispose();
    _handler.cancel();
    super.dispose();
  }

  // * Implicit animation stuff

  @override
  FloatingSearchAppBarStyle get newValue {
    final ThemeData theme = Theme.of(context);
    final AppBarThemeData appBar = theme.appBarTheme;
    final TextDirection direction = Directionality.of(context);

    return FloatingSearchAppBarStyle(
      height: widget.height ?? kToolbarHeight,
      accentColor: widget.accentColor ?? theme.colorScheme.secondary,
      backgroundColor: widget.color ?? theme.cardColor,
      iconColor: widget.iconColor ?? theme.iconTheme.color ?? Colors.grey,
      colorOnScroll: widget.colorOnScroll ?? appBar.backgroundColor,
      shadowColor: widget.shadowColor ?? appBar.shadowColor ?? Colors.black54,
      elevation: widget.elevation ?? appBar.elevation ?? 0.0,
      liftOnScrollElevation: widget.liftOnScrollElevation,
      padding: widget.padding?.resolve(direction) ??
          EdgeInsetsDirectional.only(
            start: hasleadingActions ? 12 : 16,
            end: hasActions ? 12 : 16,
          ).resolve(direction),
      insets: widget.insets?.resolve(direction) ??
          EdgeInsetsDirectional.only(
            start: hasleadingActions ? 16 : 0,
            end: hasActions ? 16 : 0,
          ).resolve(direction),
      hintStyle: widget.hintStyle,
      queryStyle: widget.titleStyle,
    );
  }

  @override
  FloatingSearchAppBarStyle lerp(
    FloatingSearchAppBarStyle a,
    FloatingSearchAppBarStyle b,
    double t,
  ) =>
      a.scaleTo(b, t);
}

class _FloatingSearchProgressBar extends StatefulWidget {
  const _FloatingSearchProgressBar({
    required this.progress,
    required this.color,
  });
  final dynamic progress;
  final Color color;

  @override
  _FloatingSearchProgressBarState createState() =>
      _FloatingSearchProgressBarState();
}

class _FloatingSearchProgressBarState extends State<_FloatingSearchProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  dynamic get progress => widget.progress;
  bool get showProgressBar => _controller.value > 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    )..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(_FloatingSearchProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool show = progress != null &&
        (progress is num || (progress is bool && progress == true));

    show ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    const double height = 2.75;

    final double? progressValue =
        progress is num ? (progress as num).toDouble().clamp(0.0, 1.0) : null;

    if (showProgressBar) {
      return Opacity(
        opacity: _controller.value,
        child: SizedBox(
          height: height,
          child: LinearProgressIndicator(
            value: progressValue,
            semanticsValue: progressValue?.toStringAsFixed(2),
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(widget.color),
          ),
        ),
      );
    } else {
      return const SizedBox(height: height);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
