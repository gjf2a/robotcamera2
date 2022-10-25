import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:camera/camera.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CameraController controller;
  DateTime _start = DateTime.now();
  double _fps = 0.0;
  bool _started = false;
  int _counter = 0, _width = 0, _height = 0;
  final CameraImagePainter _livePicture = CameraImagePainter();

  @override
  void initState() {
    super.initState();
    controller = CameraController(_cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.startImageStream((image) {
        setState(() {
          if (_started) {
            Duration elapsed = DateTime.now().difference(_start);
            _fps = _counter / elapsed.inSeconds;
          } else {
            _start = DateTime.now();
            _started = true;
          }
          _counter++;
          _width = image.width;
          _height = image.height;
          _livePicture.setImage(image).whenComplete(() {});
        });
      });
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print('User denied camera access.');
            break;
          default:
            print('Handle other errors.');
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String shiftStr() {
    CorrelationFlow? shift = _livePicture.getShift();
    if (shift == null) {
      return "No shift";
    } else {
      return "Shift: (${shift.dx}, ${shift.dy})";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
                title: const Text("This is a title")),
            body: Center(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CustomPaint(painter: _livePicture),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text("Grabbed: $_counter ($_width x $_height) FPS: ${_fps.toStringAsFixed(2)}"),
                          Text(shiftStr()),
                        ],
                      ),
                    ]
                )
            )
        )
    );
  }
}
