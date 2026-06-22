// Web-only implementation; imported via conditional import on web.
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final _registeredViewTypes = <String>{};
final _imageErrorCallbacks = <int, VoidCallback>{};

String _objectFitCss(BoxFit fit) {
  return switch (fit) {
    BoxFit.cover => 'cover',
    BoxFit.contain => 'contain',
    BoxFit.fill => 'fill',
    BoxFit.fitWidth => 'scale-down',
    BoxFit.fitHeight => 'scale-down',
    BoxFit.none => 'none',
    BoxFit.scaleDown => 'scale-down',
  };
}

String _viewTypeFor(String url, BoxFit fit) {
  final key = '${url.hashCode}-${fit.name}';
  final viewType = 'iq-car-img-$key';
  if (_registeredViewTypes.contains(viewType)) {
    return viewType;
  }

  _registeredViewTypes.add(viewType);
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final img = web.HTMLImageElement()
      ..src = url
      ..style.setProperty('width', '100%')
      ..style.setProperty('height', '100%')
      ..style.setProperty('object-fit', _objectFitCss(fit))
      ..style.setProperty('object-position', 'center')
      ..style.setProperty('display', 'block');
    img.onerror = ((web.Event _) {
      void notify() => _imageErrorCallbacks[viewId]?.call();
      if (_imageErrorCallbacks.containsKey(viewId)) {
        notify();
      } else {
        Future<void>.delayed(Duration.zero, notify);
      }
    }).toJS;
    return img;
  });
  return viewType;
}

class _WebCarNetworkImage extends StatefulWidget {
  const _WebCarNetworkImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  State<_WebCarNetworkImage> createState() => _WebCarNetworkImageState();
}

class _WebCarNetworkImageState extends State<_WebCarNetworkImage> {
  bool _hasError = false;
  late final String _viewType;
  int? _viewId;

  @override
  void initState() {
    super.initState();
    _viewType = _viewTypeFor(widget.imageUrl, widget.fit);
  }

  @override
  void didUpdateWidget(covariant _WebCarNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl || oldWidget.fit != widget.fit) {
      if (_viewId != null) {
        _imageErrorCallbacks.remove(_viewId);
        _viewId = null;
      }
      _viewType = _viewTypeFor(widget.imageUrl, widget.fit);
      _hasError = false;
    }
  }

  @override
  void dispose() {
    if (_viewId != null) {
      _imageErrorCallbacks.remove(_viewId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorBuilder?.call(context, Object(), StackTrace.current) ??
          const SizedBox.shrink();
    }

    Widget child = HtmlElementView(
      viewType: _viewType,
      onPlatformViewCreated: (int viewId) {
        _viewId = viewId;
        _imageErrorCallbacks[viewId] = () {
          if (mounted) setState(() => _hasError = true);
        };
      },
    );

    if (widget.width != null || widget.height != null) {
      child = SizedBox(
        width: widget.width,
        height: widget.height,
        child: child,
      );
    }

    return child;
  }
}

/// Network car photo on web using an HTML `<img>` with explicit `object-fit`.
Widget buildWebCarNetworkImage({
  required String imageUrl,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  return _WebCarNetworkImage(
    imageUrl: imageUrl,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
