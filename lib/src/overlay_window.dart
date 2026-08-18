import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/src/models/overlay_position.dart';
import 'package:flutter_overlay_window/src/overlay_config.dart';

class FlutterOverlayWindow {
  FlutterOverlayWindow._();

  static final StreamController _controller = StreamController();
  static final StreamController<dynamic> _messagesFromMainController =
      StreamController<dynamic>.broadcast();
  static final StreamController<dynamic> _messagesFromOverlayController =
      StreamController<dynamic>.broadcast();
  static const MethodChannel _channel =
      MethodChannel("x-slayer/overlay_channel");
  static const MethodChannel _overlayChannel =
      MethodChannel("x-slayer/overlay");
  static const BasicMessageChannel _overlayMessageChannel =
      BasicMessageChannel("x-slayer/overlay_messenger", JSONMessageCodec());
  static const BasicMessageChannel<dynamic> _mainToOverlayMessageChannel =
      BasicMessageChannel<dynamic>(
    "x-slayer/overlay_messenger/main_to_overlay",
    JSONMessageCodec(),
  );
  static const BasicMessageChannel<dynamic> _overlayToMainMessageChannel =
      BasicMessageChannel<dynamic>(
    "x-slayer/overlay_messenger/overlay_to_main",
    JSONMessageCodec(),
  );

  /// Open overLay content
  ///
  /// - Optional arguments:
  ///
  /// `height` the overlay height and default is [WindowSize.fullCover]
  ///
  /// `width` the overlay width and default is [WindowSize.matchParent]
  ///
  /// `alignment` the alignment postion on screen and default is [OverlayAlignment.center]
  ///
  /// `visibilitySecret` the detail displayed in notifications on the lock screen and default is [NotificationVisibility.visibilitySecret]
  ///
  /// `OverlayFlag` the overlay flag and default is [OverlayFlag.defaultFlag]
  ///
  /// `overlayTitle` the notification message and default is "overlay activated"
  ///
  /// `overlayContent` the notification message
  ///
  /// `enableDrag` to enable/disable dragging the overlay over the screen and default is "false"
  ///
  /// `positionGravity` the overlay postion after drag and default is [PositionGravity.none]
  ///
  /// `startPosition` the overlay start position and default is null
  static Future<void> showOverlay({
    int height = WindowSize.fullCover,
    int width = WindowSize.matchParent,
    OverlayAlignment alignment = OverlayAlignment.center,
    NotificationVisibility visibility = NotificationVisibility.visibilitySecret,
    OverlayFlag flag = OverlayFlag.defaultFlag,
    String overlayTitle = "overlay activated",
    String? overlayContent,
    bool enableDrag = false,
    PositionGravity positionGravity = PositionGravity.none,
    OverlayPosition? startPosition,
  }) async {
    await _channel.invokeMethod(
      'showOverlay',
      {
        "height": height,
        "width": width,
        "alignment": alignment.name,
        "flag": flag.name,
        "overlayTitle": overlayTitle,
        "overlayContent": overlayContent,
        "enableDrag": enableDrag,
        "notificationVisibility": visibility.name,
        "positionGravity": positionGravity.name,
        "startPosition": startPosition?.toMap(),
      },
    );
  }

  /// Check if overlay permission is granted
  static Future<bool> isPermissionGranted() async {
    try {
      return await _channel.invokeMethod<bool>('checkPermission') ?? false;
    } on PlatformException catch (error) {
      log("$error");
      return Future.value(false);
    }
  }

  /// Request overlay permission
  /// it will open the overlay settings page and return `true` once the permission granted.
  static Future<bool?> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool?>('requestPermission');
    } on PlatformException catch (error) {
      log("Error requestPermession: $error");
      rethrow;
    }
  }

  /// Closes overlay if open
  static Future<bool?> closeOverlay() async {
    final bool? _res = await _channel.invokeMethod('closeOverlay');
    return _res;
  }

  /// Sends data from the main app to the overlay app.
  static Future<dynamic> sendToOverlay(dynamic data) {
    return _mainToOverlayMessageChannel.send(data);
  }

  /// Messages sent by the main app and received by the overlay app.
  static Stream<dynamic> get messagesFromMain {
    _mainToOverlayMessageChannel.setMessageHandler((message) async {
      _messagesFromMainController.add(message);
      return message;
    });
    return _messagesFromMainController.stream;
  }

  /// Sends data from the overlay app to the main app.
  static Future<dynamic> sendToMain(dynamic data) {
    return _overlayToMainMessageChannel.send(data);
  }

  /// Messages sent by the overlay app and received by the main app.
  static Stream<dynamic> get messagesFromOverlay {
    _overlayToMainMessageChannel.setMessageHandler((message) async {
      _messagesFromOverlayController.add(message);
      return message;
    });
    return _messagesFromOverlayController.stream;
  }

  /// Broadcast data to and from overlay app.
  @Deprecated(
    'Use sendToOverlay from the main app or sendToMain from the overlay app.',
  )
  static Future shareData(dynamic data) async {
    return await _overlayMessageChannel.send(data);
  }

  /// Streams messages shared between overlay and main app.
  @Deprecated(
    'Use messagesFromMain in the overlay app or messagesFromOverlay in the main app.',
  )
  static Stream<dynamic> get overlayListener {
    _overlayMessageChannel.setMessageHandler((message) async {
      _controller.add(message);
      return message;
    });
    return _controller.stream;
  }

  /// Update the overlay flag while the overlay in action
  static Future<bool?> updateFlag(OverlayFlag flag) async {
    final bool? _res = await _overlayChannel
        .invokeMethod<bool?>('updateFlag', {'flag': flag.name});
    return _res;
  }

  /// Update the overlay size in the screen
  static Future<bool?> resizeOverlay(
    int width,
    int height,
    bool enableDrag, {
    bool keepTop = false,
  }) async {
    final bool? _res = await _overlayChannel.invokeMethod<bool?>(
      'resizeOverlay',
      {
        'width': width,
        'height': height,
        'enableDrag': enableDrag,
        'keepTop': keepTop,
      },
    );
    return _res;
  }

  /// Update the overlay position in the screen
  ///
  /// `position` the new position of the overlay
  ///
  /// `return` true if the position updated successfully
  static Future<bool?> moveOverlay(OverlayPosition position) async {
    final bool? _res = await _channel.invokeMethod<bool?>(
      'moveOverlay',
      position.toMap(),
    );
    return _res;
  }

  /// Get the current overlay position
  ///
  /// `return` the current overlay position
  static Future<OverlayPosition> getOverlayPosition() async {
    final Map<Object?, Object?>? _res = await _channel.invokeMethod(
      'getOverlayPosition',
    );
    return OverlayPosition.fromMap(_res);
  }

  /// Check if the current overlay is active
  static Future<bool> isActive() async {
    final bool? _res = await _channel.invokeMethod<bool?>('isOverlayActive');
    return _res ?? false;
  }

  /// Dispose overlay stream
  static void disposeOverlayListener() {
    _controller.close();
  }
}
