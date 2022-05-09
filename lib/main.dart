import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:tcp_socket_connection/tcp_socket_connection.dart';

void main() {
  runApp(VideoApp());
}

class VideoApp extends StatefulWidget {
  @override
  _VideoAppState createState() => _VideoAppState();
}

class _VideoAppState extends State<VideoApp> {
  VideoPlayerController _controller = VideoPlayerController.network('http://primo.zapto.org');

  @override
  void initState() {
    super.initState();
    _controller
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Video Demo',
      home: Scaffold(
        body: Column(children: <Widget>[
          _controller.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                )
              : Container(),
          Expanded(child: Center(child: GamePad()))
        ]),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _controller.value.isPlaying ? _controller.pause() : _controller.play();
            });
          },
          child: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}

class GamePad extends StatefulWidget {
  @override
  _GamePad createState() => _GamePad();
}

class _GamePad extends State<GamePad> {
  var x = 0.0;
  var y = 0.0;
  var message = "";
  TcpSocketConnection socketConnection = TcpSocketConnection('192.168.0.115', 57405);
  void initState() {
    super.initState();
    startConnection();
  }

  //starting the connection and listening to the socket asynchronously
  void startConnection() async {
    socketConnection.enableConsolePrint(true); //use this to see in the console what's happening
    if (await socketConnection.canConnect(5000, attempts: 3)) {
      //check if it's possible to connect to the endpoint
      await socketConnection.connect(5000, "EOS", messageReceived, attempts: 3);
    }
  }

  void messageReceived(String msg) {
    setState(() {
      message = msg;
    });
    socketConnection.sendMessage("MessageIsReceived :D ");
  }

  _onTapDown(TapDownDetails details) {
    setState(() {
      x = details.localPosition.dx;
      y = details.localPosition.dy;
    });
    // or user the local position method to get the offset
    print("Tap down" + details.localPosition.toString());
  }

  _onTapUp(TapUpDetails details) {
    print("Tap up" + details.localPosition.toString());

    setState(() {
      x = 0.0;
      y = 0.0;
    });
  }

  Widget draw() {
    if (y > 50 && y < 100) {
      if (x > 90) {
        socketConnection.sendMessage('{"x":1,"y":0}');
        return Image(image: AssetImage('images/game-controller-r.png'));
      } else if (x < 40) {
        socketConnection.sendMessage('{"x":-1,"y":0}');

        return Image(image: AssetImage('images/game-controller-l.png'));
      } else {
        socketConnection.sendMessage('{"x":0,"y":0}');
        return Image(image: AssetImage('images/game-controller-idle.png'));
      }
    } else {
      if (y > 10 && y < 50) {
        socketConnection.sendMessage('{"x":0,"y":-1}');
        return Image(image: AssetImage('images/game-controller-up.png'));
      } else if (y > 100) {
        socketConnection.sendMessage('{"x":0,"y":1}');

        return Image(image: AssetImage('images/game-controller-down.png'));
      } else {
        socketConnection.sendMessage('{"x":0,"y":0}');

        return Image(image: AssetImage('images/game-controller-idle.png'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      onTapDown: (TapDownDetails details) => _onTapDown(details),
      onTapUp: (TapUpDetails details) => _onTapUp(details),
      child: Container(
        padding: const EdgeInsets.all(8),
        // Change button text when light changes state.
        child: draw(),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    socketConnection.disconnect();
  }
}
