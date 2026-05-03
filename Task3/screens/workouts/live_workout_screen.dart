// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:image/image.dart' as img;

// class LiveWorkoutPage extends StatefulWidget {
//   @override
//   _LiveWorkoutPageState createState() => _LiveWorkoutPageState();
// }

// class _LiveWorkoutPageState extends State<LiveWorkoutPage> {
//   CameraController? _controller;
//   WebSocketChannel? _channel;
//   int _reps = 0;
//   List<String> _feedback = ["Aligning with AI..."];
//   bool _isProcessing = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//     _connectToWebSocket();
//   }

//   // 1. الربط مع سيرفر بايثون
//   void _connectToWebSocket() {
//     // ملحوظة: لو شغال على موبايل حقيقي، حطي IP اللابتوب بدل 10.0.2.2
//     _channel = WebSocketChannel.connect(
//       Uri.parse('ws://10.0.2.2:8000/ws/live-workout'),
//     );

//     _channel!.stream.listen((message) {
//       final data = jsonDecode(message);
//       setState(() {
//         _reps = data['reps'];
//         _feedback = List<String>.from(data['feedback']);
//       });
//     });
//   }

//   // 2. تشغيل الكاميرا
//   void _initializeCamera() async {
//     final cameras = await availableCameras();
//     _controller = CameraController(
//       cameras[1],
//       ResolutionPreset.medium,
//       enableAudio: false,
//     );

//     await _controller!.initialize();
//     if (!mounted) return;

//     setState(() {});

//     // 3. سحب الفريمات وإرسالها للسيرفر
//     _controller!.startImageStream((CameraImage image) {
//       if (_isProcessing) return; // حماية عشان الموبايل مهنجش
//       _isProcessing = true;

//       _sendFrameToServer(image);

//       // بنبعت فريم كل 200 مللي ثانية تقريباً (5 فريمات في الثانية)
//       Future.delayed(Duration(milliseconds: 200), () => _isProcessing = false);
//     });
//   }

//   void _sendFrameToServer(CameraImage image) async {
//     try {
//       // تحويل الفريم من YUV لـ JPG (دي الخطوة اللي بايثون مستنيها)
//       final bytes = _convertYUV420ToNV21(image);
//       final base64Image = base64Encode(bytes);
//       _channel?.sink.add(base64Image);
//     } catch (e) {
//       print("Error sending frame: $e");
//     }
//   }

//   // دالة مساعدة لتحويل صيغة فريم الكاميرا لـ Bytes يفهمها بايثون
//   Uint8List _convertYUV420ToNV21(CameraImage image) {
//     final width = image.width;
//     final height = image.height;
//     final yPlane = image.planes[0].bytes;
//     final uPlane = image.planes[1].bytes;
//     final vPlane = image.planes[2].bytes;

//     final yuvBytes = Uint8List(
//       width * height + 2 * (width ~/ 2) * (height ~/ 2),
//     );
//     yuvBytes.setRange(0, width * height, yPlane);
//     // كود بسيط للتحويل السريع
//     return yuvBytes;
//     // ملاحظة: يفضل استخدام مكتبة تحويل JPG كاملة لو الصورة طلعت مشوشة
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     _channel?.sink.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_controller == null || !_controller!.value.isInitialized) {
//       return Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // عرض الكاميرا
//           CameraPreview(_controller!),

//           // واجهة البيانات (العداد والملاحظات)
//           Positioned(
//             bottom: 50,
//             left: 20,
//             right: 20,
//             child: Container(
//               padding: EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.black54,
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(color: Colors.cyan, width: 2),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     "Reps: $_reps",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 40,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                   Text(
//                     _feedback.join("\n"),
//                     textAlign: TextAlign.center,
//                     style: TextStyle(color: Colors.cyanAccent, fontSize: 18),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ده عشان اشغله على الموبايل
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:image/image.dart' as img;

class LiveWorkoutPage extends StatefulWidget {
  @override
  _LiveWorkoutPageState createState() => _LiveWorkoutPageState();
}

class _LiveWorkoutPageState extends State<LiveWorkoutPage> {
  CameraController? _controller;
  WebSocketChannel? _channel;
  int _reps = 0;
  List<String> _feedback = ["Aligning with AI..."];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _connectToWebSocket();
  }

  // 1. الربط مع سيرفر بايثون
  void _connectToWebSocket() {
    // 💡 التعديل الأول: الـ IP الحقيقي بتاع اللابتوب
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.1.6:8000/ws/live-workout'),
    );

    _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      setState(() {
        _reps = data['reps'] ?? 0;
        // 💡 التعديل التاني: استقبال الفيدباك كنص مش قائمة
        _feedback = [data['feedback'].toString()];
      });
    });
  }

  // 2. تشغيل الكاميرا
  void _initializeCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(
      // رقم 1 يعني الكاميرا الأمامية، لو ضرب معاكي خليه 0 للكاميرا الخلفية
      cameras[1],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (!mounted) return;

    setState(() {});

    // 3. سحب الفريمات وإرسالها للسيرفر
    _controller!.startImageStream((CameraImage image) {
      if (_isProcessing) return; // حماية عشان الموبايل مهنجش
      _isProcessing = true;

      _sendFrameToServer(image);

      // بنبعت فريم كل 200 مللي ثانية
      Future.delayed(Duration(milliseconds: 200), () => _isProcessing = false);
    });
  }

  void _sendFrameToServer(CameraImage image) async {
    try {
      final bytes = _convertYUV420ToNV21(image);
      final base64Image = base64Encode(bytes);

      // 💡 التعديل التالت: تغليف الصورة في JSON عشان بايثون يفهمها
      final jsonMessage = jsonEncode({"image": base64Image});
      _channel?.sink.add(jsonMessage);
    } catch (e) {
      print("Error sending frame: $e");
    }
  }

  // دالة تحويل الفريم
  Uint8List _convertYUV420ToNV21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0].bytes;

    final yuvBytes = Uint8List(
      width * height + 2 * (width ~/ 2) * (height ~/ 2),
    );
    yuvBytes.setRange(0, width * height, yPlane);
    return yuvBytes;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // عرض الكاميرا
          CameraPreview(_controller!),

          // واجهة البيانات (العداد والملاحظات)
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyan, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Reps: $_reps",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _feedback.join("\n"),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.cyanAccent, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
