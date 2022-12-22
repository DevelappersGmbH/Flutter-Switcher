import 'package:pigeon/pigeon.dart';

@PigeonOptions(
  // path where the header file should be generated
  objcHeaderOut: '../ios/Switcher/Switcher/bridge.h',
  // path where the source file should be generated
  objcSourceOut: '../ios/Switcher/Switcher/bridge.m',
  // prefix for the generated objc code
  objcOptions: ObjcOptions(prefix: 'B'),
  // path where the java file should be generated
  javaOut: '../android/app/src/main/java/de/develappers/switcher/bridge.java',
  // package for the generated java code
  javaOptions: JavaOptions(
    package: 'de.develappers.switcher',
  ),
)

/// The communication object, this object will be used in dart and in native code
/// encoding and decoding the data will be done automatically
class HistoryEntry {
  final bool state;
  final String at;
  final String source;
  HistoryEntry({
    required this.state,
    required this.at,
    required this.source,
  });
}

/// This interface will be used to send data from native to dart, in this case
/// the native code will send the current state of the switcher
@FlutterApi()
abstract class FApi {
  void currentState(bool state);
}

/// This interface will be used to send data from dart to native, in this case
/// the dart code will send a history entry to the native code to be added to
/// the history list
@HostApi()
abstract class HApi {
  void updateState(HistoryEntry entry);
}
