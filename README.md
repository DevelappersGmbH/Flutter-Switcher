# Communication between flutter and native

Communication between a Flutter app and native code can be useful in a variety of situations, such as when you want to access platform-specific features or integrate with existing native libraries. There are several ways to achieve this communication, but one of the most popular is through the use of a package called [Pigeon](https://pub.dev/packages/pigeon).

[Pigeon](https://pub.dev/packages/pigeon) is a code generator package for Flutter that makes the communication between Flutter and the host platform type-safe, easier and faster. By generating the communication interface and the objects in dart and native code you just need to implement the interfaces and let pigeon connect them.

In this article we will build an App in native code that have only one switcher and then we will add a flutter screen to this app. The switcher state could be changed from flutter screen or native screen and will be synced with the other. and there is a list showing the state history.

At first we will need to make our projects. The folder structure will be like [this](https://www.google.com)

- Switcher
    - android: folder that contains the android project in native code.
    - flutter: folder that contains the flutter screen
    - Ios: folder that contains the Ios project in native

## Flutter

As here the project will be in native and the Flutter screen will be shown within the app, we need to create a [flutter module](https://docs.flutter.dev/development/add-to-app/android/project-setup#create-a-flutter-module)

```bash
flutter create -t module --org de.develappers.switcher switcher
```

### Create the communication interface

Then add the pigeon package as dev_dependencies and create a new folder called pigeon in the flutter directory. This will contains the communication interface. Our interface will look like this

```dart
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
```

Now we should run the pigeon generator by running the following command in the flutter directory

```bash
flutter pub run pigeon --input pigeons/bridge.dart  --dart_out lib/bridge.dart
```
Now you should see the generated files in the android, ios and flutter directories. 

### Implement the communication interface in dart

Let's implement the dart side of the communication by implementing the FApi interface. The implementation will be like this

```dart
class ApiHandler implements FApi {
  final Function(bool) callBack;

  ApiHandler(this.callBack);

  @override
  void currentState(bool state) {
    // call the callback function to update the state of the switcher in the widget
    callBack(state);
  }
}

// Setup the FApi before using it
@override
void initState() {
  super.initState();
  FApi.setup(ApiHandler(currentState));
}

```

This will be used to update the state of the switcher after receiving the current state from the native code.
and to send the history entry to the native code we will use the HApi. This will be done by creating a new instance of the HApi and calling the updateState method. The implementation will be like this

```dart
// create a new instance of the HApi
final _api = HApi();

// call the updateState method
void _updateState(bool value) {
    final now = DateTime.now().toString().split(' ')[1].split('.')[0];
    final entry = HistoryEntry(state: value, at: now, source: 'Flutter');
    _api.updateState(entry);
}
```

## Native Android

![Android](assets/Dec-21-2022%2013-46-53.gif)

### Add the Flutter module

To show the Flutter screen in the native app we need to add the flutter module as a dependency in the native project. To do this we need to add the following lines to the settings.gradle file in the android directory

```groovy
include ':app'

setBinding(new Binding([gradle: this]))
evaluate(new File(settingsDir.parentFile,'flutter/.android/include_flutter.groovy'))
```

Then implement it in the build.gradle file in the android directory

```groovy
dependencies {
    implementation project(path: ':flutter')
}
```

### Add the FlutterEngine

FlutterEngine should be created in the onCreate method of the MyApplication class and cache it to FlutterEngineCache

```kotlin
flutterEngine = FlutterEngine(this)
// Start executing Dart code to pre-warm the FlutterEngine.
flutterEngine.dartExecutor.executeDartEntrypoint(
    DartExecutor.DartEntrypoint.createDefault()
)
// Cache the FlutterEngine to be used by FlutterActivity.
FlutterEngineCache
    .getInstance()
    .put(ENGINE_ID, flutterEngine)
```

### Add the Flutter screen and implement interface

Now create a new activity that will show the Flutter screen. This activity will be called FlutterSwitcherActivity. The implementation will be like this

```kotlin
class FlutterSwitcherActivity : FlutterActivity() {

    companion object {
        private const val STATE_VALUE = "state_value"
        lateinit var callBack : (result: HistoryEntry)-> Unit // callback function to add the history entry to the list

        fun withState(context: Context, state: Boolean, stateCallBack: (result: HistoryEntry)-> Unit) : Intent{
            this.callBack = stateCallBack;
            // create a new instance of the CachedEngineSwitcherIntent and pass the state to it
            return CachedEngineSwitcherIntentBuilder(ENGINE_ID).build(context).putExtra(STATE_VALUE, state)
        }
    }

    class CachedEngineSwitcherIntentBuilder(engineId: String) :
        CachedEngineIntentBuilder(FlutterSwitcherActivity::class.java, engineId) {}

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // get the state from the intent
        var state = intent.getBooleanExtra(STATE_VALUE, true)
        // create a new instance of the ApiHandler and pass the state to it to update the state of the switcher in flutter
        bridge.FApi(flutterEngine.dartExecutor).currentState(state){}
        // create a new instance of the ApiHandler
        bridge.HApi.setup(flutterEngine.dartExecutor, ApiHandler())
    }

    // The HApi implementation to receive the history entry from flutter and add it to the list
    inner class ApiHandler : bridge.HApi{
        override fun updateState(entry: bridge.HistoryEntry) {
            callBack.invoke(entry)
        }
    }
}
```

Don't forget to add the new activity to the manifest file

```xml
<activity
    android:name=".FlutterSwitcherActivity"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize" />
```

### Start the Flutter screen

Now we can show the Flutter screen in the native app by calling the FlutterSwitcherActivity with the state of the switcher and the callback function to add the history entry to the list

```kotlin
startActivity(FlutterSwitcherActivity.withState(this,switch.isChecked){state->
  addNewState(state)
  switch.isChecked = state.state
})
```

## iOS Native

![iOS](assets/Dec-22-2022%2011-03-01.gif)

Now let's implement the iOS native side. The implementation will be similar to the Android side. first we need to add the Flutter module as a dependency in the native project. To do this we need to add the following lines to the Podfile file in the ios directory

```ruby
flutter_application_path = '../../flutter/'
load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')

target 'Switcher' do
  use_frameworks!
  install_all_flutter_pods(flutter_application_path)
end

post_install do |installer|
  flutter_post_install(installer) if defined?(flutter_post_install)
end
```
And then run `pod install` in the ios directory to install the Flutter module.

### Add the FlutterEngine

To use the FlutterEngine, we need to create it in the AppDelegate class 

```swift
lazy var engine: FlutterEngine = {
  let result = FlutterEngine.init(name: "Switcher")
  result.run()
  return result
}()
```

### Add the Flutter screen and implement interface and show the Flutter screen

We can implement the BHApi to the ViewController class to receive the history entry from flutter and add it to the list, and in it we will create the FApi to send the current state to flutter

```swift
class ViewController: UIViewController, UITableViewDataSource, BHApi { // implement BHApi
    private var history: [BHistoryEntry] = []
    // setup api for sending the status
    private var api: BFApi! 
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var switcher : UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        // Setup api for incoming message
        BHApiSetup(appDelegate.engine.binaryMessenger, self)
        // setup api for outgoing message
        api = BFApi.init(binaryMessenger: appDelegate.engine.binaryMessenger)
    }
    
    // The function to be called when the button 'Go to Flutter' is pressed
    @IBAction func goToFlutter(_ sender: UIButton){
        // send the status to Flutter
        api.currentStateState(switcher.isOn as NSNumber){ (error) in
            if let error = error {
                print(error)
            }
        }
        // Get the Flutter engine from the AppDelegate
        let flutterEngine = (UIApplication.shared.delegate as! AppDelegate).engine
        // Create a FlutterViewController with the Flutter engine
        let flutterViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
        // Present the FlutterViewController
        present(flutterViewController, animated: true, completion: nil)
    }
    
    // implement the function of BHApi to receive the status from Flutter and update the UI
    func updateStateEntry(_ entry: BHistoryEntry, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        addEntry(entry)
        switcher.isOn = entry.state as! Bool
    }
}
```

In conclusion, we have implemented the Flutter module in the native app and showed the Flutter screen in it and send and receive data from the native app to the Flutter module. Which shows the power of Flutter and how easy it is to integrate it with native apps. or just for using a platform-specific feature in Flutter.

The full code is available on [GitHub](). If you have any questions or suggestions, please leave a comment below. Thanks for reading.