import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progress_indicators/progress_indicators.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        primaryColor: Colors.deepPurple,
        accentColor: Colors.blue,
        fontFamily: 'M-plus',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        pageTransitionsTheme: PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        primaryColor: Colors.deepPurple,
        accentColor: Colors.blue,
        fontFamily: 'M-plus',
        pageTransitionsTheme: PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

String _content = "";
int _counter = 0;
String _strcounter = "";
String _current = "OFF";
double opacityLevel = 1.0;
String _circle = ">>";
String _status = "starting...";
String _error = "This is a DEMO app; cannot submit FTP";
bool _ftp = false;
var url = 'http://watapondata.starfree.jp/ac/status.txt';

class _MyHomePageState extends State<MyHomePage> {
  void _request() async {
    final response = await http.post(Uri.parse(url));
    if (response.statusCode != 200) {
      setState(() {
        int statusCode = response.statusCode;
        _content = " -- ";
        _status = "";
        if (response.statusCode == 404) {
          setState(() {
            _error = "404 Not Found";
          });
        }
      });

      return;
    }
    setState(() {
      _content = response.body;
    });
    //core code
    if (_current != _content) {
      if (_content == "ON") {
        _poweron();
        _current = "ON";
      } else {
        if (_content == "OFF") {
          _poweroff();
          _current = "OFF";
        }
      }
    }
  }

  void initState() {
    Timer.periodic(Duration(seconds: 3), // 1秒毎にループ
        (timer) {
      _counter++;
      _strcounter = _counter.toString();
      _status = "HTTP GET requesting...";
      _request();
      _circle = "●";
      _status = 'HTTP GET requested $_strcounter times';
    });
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("エアコンスイッチ起爆剤（親機）",
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            )),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        brightness: Brightness.dark,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 300,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(3.14),
                    child: Image.asset('me.webp'),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GlowingProgressIndicator(
                      duration: Duration(milliseconds: 800),
                      child: Text(
                        _circle,
                        style: TextStyle(fontSize: 25, color: Colors.green),
                      ),
                    ),
                    (_status == "starting...")
                        ? Text("starting...",
                            style:
                                TextStyle(fontSize: 25, color: Colors.blueGrey))
                        : Text(" server connected !",
                            style:
                                TextStyle(fontSize: 25, color: Colors.green)),
                  ],
                ),
                Text("ac_status :", style: TextStyle(fontSize: 20)),
                Text(_content,
                    style:
                        TextStyle(fontSize: 50, fontWeight: FontWeight.bold)),
                Text("source: $url"),
                Text('app_status: $_status',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    (_ftp)
                        ? GlowingProgressIndicator(
                            duration: Duration(milliseconds: 800),
                            child: Text('●',
                                style: TextStyle(
                                  color: Colors.amber.shade800,
                                  fontSize: 15,
                                )))
                        : Text('●',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 15,
                            )),
                    (_ftp)
                        ? Text(' FTP is working...  File buffaling...',
                            style: TextStyle(
                              color: Colors.amber.shade800,
                              fontSize: 15,
                            ))
                        : Text(' FTP is not working...  File listening...',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 15,
                            )),
                  ],
                ),
                (_error != "")
                    ? Text('Error: $_error',
                        style: TextStyle(color: Colors.red))
                    : Text("No error found",
                        style: TextStyle(color: Colors.red)),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Flutter1.22以降のみ
                    ElevatedButton.icon(
                      icon: Icon(Icons.stop),
                      label: const Text('OFF',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blueAccent,
                        onPrimary: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        _poweroff();
                      },
                    ),
                    SizedBox(
                      width: 40,
                    ),

                    ElevatedButton.icon(
                      icon: Icon(Icons.play_arrow),
                      label: const Text('ON ',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blueAccent,
                        onPrimary: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        _poweron();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text("programmed & designed by wappon_28_dev")
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _poweron() async {
  _status = "due to demo, FTP doesn't worked!";
  // _ftp = true;
  // FTPConnect ftpConnect = FTPConnect('watapondata.starfree.jp',
  //     user: 'hoge', pass: 'foo');
  // try {
  //   _status = 'Connecting to FTP ...';
  //   await ftpConnect.connect();
  //   await ftpConnect.changeDirectory('ac');
  //   File fileToUpload = await _fileMock(fileName: 'status.txt', content: 'ON');
  //   _status = 'Uploading ...';
  //   await ftpConnect.uploadFile(fileToUpload);
  //   await ftpConnect.disconnect();
  //   _status = 'file uploaded sucessfully !';
  //   _ftp = false;
  // } catch (e) {
  //   _error = 'Error: ${e.toString()}';
  // }
}

Future<void> _poweroff() async {
  _status = "due to demo, FTP doesn't worked!";
  // _ftp = true;
  // FTPConnect ftpConnect =
  //     FTPConnect('watapondata.starfree.jp', user: 'hoge', pass: 'foo');
  // try {
  //   _status = 'Connecting to FTP ...';

  //   await ftpConnect.connect();
  //   await ftpConnect.changeDirectory('ac');
  //   File fileToUpload = await _fileMock(fileName: 'status.txt', content: 'OFF');
  //   _status = 'Uploading ...';
  //   await ftpConnect.uploadFile(fileToUpload);
  //   await ftpConnect.disconnect();
  //   _status = 'file uploaded sucessfully';
  //   _ftp = false;
  // } catch (e) {
  //   _error = 'Error: ${e.toString()}';
  // }
}


///mock a file for the demonstration example


// _makePostRequest() async {
// // set up POST request arguments
//   String url = "https://jsonplaceholder.typicode.com/posts";
//   Map<String, String> headers = {"Content-type": "application/json"};
//   String json = '{"title": "Hello", "body": "body text", "userId": 1}';
// // make POST request
//   Response response = await post(Uri.parse(url), headers: headers, body: json);
// // check the status code for the result
//   int statusCode = response.statusCode;
// // this API passes back the id of the new item added to the body
//   String body = response.body;
//   print(statusCode);
// }
  // void _request() async {
  //   final uri = Uri.https('192.168.11.9', '');

  //   // GETを投げる
  //   http.Response resp = await http.get(uri);
  //   if (resp.statusCode != 200) {
  //     setState(() {
  //       int statusCode = resp.statusCode;
  //       _content = "Failed to get $statusCode";
  //     });
  //     return;
  //   }
  //   setState(() {
  //     _content = resp.body;
  //   });
  // }
  // static const platform =
  //     const MethodChannel('jp.wappon_28_dev.ac_remote/test');
  // late StreamSubscription _intentDataStreamSubscription;

  // //ここがjava呼び出し関数
  // Future<void> _calljava() async {
  //   try {
  //     print("java呼び出し");
  //     await platform.invokeMethod("test_ch", 0);
  //   } on PlatformException catch (e) {
  //     print("error");
  //   }
  // }
