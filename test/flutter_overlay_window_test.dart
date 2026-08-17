import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const controlChannel = MethodChannel('x-slayer/overlay_channel');
  const messageChannel = BasicMessageChannel<dynamic>(
    'x-slayer/overlay_messenger',
    JSONMessageCodec(),
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(controlChannel, (call) async {
      switch (call.method) {
        case 'closeOverlay':
        case 'checkPermission':
        case 'requestPermission':
          return true;
        case 'isOverlayActive':
          return false;
      }
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(controlChannel, null);
    messenger.setMockDecodedMessageHandler<dynamic>(messageChannel, null);
  });

  group('FlutterOverlayWindow', () {
    test('closeOverlay should close the overlay', () async {
      expect(await FlutterOverlayWindow.closeOverlay(), isTrue);
      expect(await FlutterOverlayWindow.isActive(), isFalse);
    });

    test('isPermissionGranted should return a boolean', () async {
      expect(await FlutterOverlayWindow.isPermissionGranted(), isTrue);
    });

    test('requestPermission should return a boolean', () async {
      expect(await FlutterOverlayWindow.requestPermission(), isTrue);
    });

    test('shareData sends a JSON message through the platform channel',
        () async {
      final message = <String, dynamic>{
        'action': 'play',
        'payload': <String, dynamic>{'position': 42},
      };
      Object? receivedByPlatform;
      messenger.setMockDecodedMessageHandler<dynamic>(messageChannel, (
        incoming,
      ) async {
        receivedByPlatform = incoming;
        return incoming;
      });

      final reply = await FlutterOverlayWindow.shareData(message);

      expect(receivedByPlatform, message);
      expect(reply, message);
    });

    test('overlayListener emits JSON messages received from the platform',
        () async {
      final message = <String, dynamic>{
        'action': 'syncBusinessState',
        'payload': <String, dynamic>{'isPlaying': true},
      };
      final received = FlutterOverlayWindow.overlayListener.first;

      final encodedReply = await messenger.handlePlatformMessage(
        messageChannel.name,
        messageChannel.codec.encodeMessage(message),
        null,
      );

      expect(await received, message);
      expect(messageChannel.codec.decodeMessage(encodedReply), message);
    });
  });
}
