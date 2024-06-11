import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'dart:io';
import 'package:gallery_saver/gallery_saver.dart';
import 'dart:async';

class CameraStreamPage extends StatefulWidget {
  @override
  _CameraStreamPageState createState() => _CameraStreamPageState();
}

class _CameraStreamPageState extends State<CameraStreamPage> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool isRecording = false;
  Timer? _timer;
  int _recordDuration = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      _controller = CameraController(
        cameras![0], // 选择第一个相机
        ResolutionPreset.medium,
      );
      await _controller?.initialize();
      _controller?.startImageStream((CameraImage image) {
        // 在这里处理图像流
        // print('Processing image stream...');
      });
      setState(() {});
    }
  }

  Future<void> _startRecording() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        isRecording) {
      return;
    }
    // final directory = await getTemporaryDirectory();
    // final filePath = join(directory.path, '${DateTime.now()}.mp4');
    try {
      await _controller!.startVideoRecording();
      setState(() {
        isRecording = true;
        _startTimer();
      });
    } catch (e) {
      print('Error starting video recording:$e');
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        !isRecording) {
      return;
    }
    try {
      final file = await _controller!.stopVideoRecording();
      setState(() {
        isRecording = false;
        _stopTimer();
      });
      final directory = await getExternalStorageDirectory();
      final filePath =
          join(directory!.path, '${DateTime.now().millisecondsSinceEpoch}.mp4');
      await file.saveTo(filePath);
      print('Video recorded to: $filePath');

      await GallerySaver.saveVideo(filePath);

      print('Viedo recorded to : $filePath');
    } catch (e) {
      print('Error stopping video recording : $e');
    }
  }

  void _startTimer() {
    _recordDuration = 0;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _recordDuration++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(title: Text('Camera Stream')),
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Positioned(
            bottom: 20,
            left: MediaQuery.of(context).size.width / 2 - 30,
            child: ElevatedButton(
              onPressed: isRecording ? _stopRecording : _startRecording,
              child: Text(isRecording ? 'Stop' : 'Record'),
            ),
          ),
          if (isRecording)
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: EdgeInsets.all(8),
                color: Colors.black54,
                child: Text(_formatDuration(_recordDuration),
                    style: TextStyle(color: Colors.white, fontSize: 20)),
              ),
            )
        ],
      ),

      //CameraPreview(_controller!),
    );
  }
}

void main() {
  runApp(MaterialApp(home: CameraStreamPage()));
}
