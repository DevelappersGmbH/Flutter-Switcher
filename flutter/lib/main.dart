import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:switcher/bridge.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SwitcherWidget(),
    );
  }
}

class SwitcherWidget extends StatefulWidget {
  const SwitcherWidget({super.key});

  @override
  State<SwitcherWidget> createState() => _SwitcherWidgetState();
}

class ApiHandler implements FApi {
  final Function(bool) callBack;

  ApiHandler(this.callBack);

  @override
  void currentState(bool state) {
    callBack(state);
  }
}

class _SwitcherWidgetState extends State<SwitcherWidget> {
  var state = true;
  final history = <HistoryEntry>[];
  final _api = HApi();

  @override
  void initState() {
    super.initState();
    FApi.setup(ApiHandler(currentState));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter App')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedToggleSwitch.dual(
                current: state,
                first: false,
                second: true,
                onChanged: _updateState,
                textBuilder: (value) => Text(value ? 'ON' : 'OFF'),
                colorBuilder: (value) => value ? Colors.green : Colors.red,
                borderWidth: 0,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    spreadRadius: 8,
                  )
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: SystemNavigator.pop,
              child: Text('Back to Native'),
            ),
          ),
          ...history
              .map((e) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(e.state.toString().toUpperCase().padRight(5)),
                      Text(e.at),
                      Text(e.source),
                    ],
                  ))
              .toList()
        ],
      ),
    );
  }

  void currentState(bool state) {
    setState(() {
      this.state = state;
    });
  }

  void _updateState(bool value) {
    final now = DateTime.now().toString().split(' ')[1].split('.')[0];
    final entry = HistoryEntry(state: value, at: now, source: 'Flutter');
    _api.updateState(entry);
    history.add(entry);
    setState(() {
      state = value;
    });
  }
}
