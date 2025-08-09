import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;

//================================================================================
// STEP 1: Main function now initializes the camera and passes it to the app
//================================================================================
Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()` can be called.
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get the front-facing camera for the mouth detection feature.
  final frontCamera = cameras.firstWhere(
    (camera) => camera.lensDirection == CameraLensDirection.front,
    // Provide a fallback to the first camera if a front camera is not available
    orElse: () => cameras.first,
  );

  runApp(FoodSwipeApp(camera: frontCamera));
}

//================================================================================
// STEP 2: The main App widget receives and holds the camera description
//================================================================================
class FoodSwipeApp extends StatelessWidget {
  final CameraDescription camera;

  const FoodSwipeApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodSwipeAR',
      theme: ThemeData.dark(),
      // Pass the camera down to the main page.
      home: FoodSwipePage(camera: camera),
    );
  }
}

//================================================================================
// STEP 3: The FoodSwipePage (Your Tinder UI)
// No UI changes were made here. Only logic to pass the real camera.
//================================================================================
class FoodSwipePage extends StatefulWidget {
  final CameraDescription camera;

  // It now accepts the camera description from the parent widget.
  const FoodSwipePage({super.key, required this.camera});

  @override
  _FoodSwipePageState createState() => _FoodSwipePageState();
}

class _FoodSwipePageState extends State<FoodSwipePage> {
  List<Map<String, String>> foodImages = [];
  List<String> foodDescriptions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFoodImages();
  }

  Future<void> fetchFoodImages() async {
    final url = Uri.parse(
      'https://api.unsplash.com/search/photos?query=delicious+food&per_page=10&client_id=whoLEbKkiIRQw7WLed4Njy8qGjZO7ygmTFGSkgYzAsM',
    );

    final response = await http.get(url);
    final data = json.decode(response.body);

    final fetchedImages = (data['results'] as List)
        .map(
          (img) => {
            'name':
                (img['description'] ?? img['alt_description'] ?? 'Unknown Food')
                    .toString(),
            'image': img['urls']['regular'].toString(),
          },
        )
        .toList();

    List<String> fetchedDescriptions = [];
    for (var food in fetchedImages) {
      String description = await fetchFoodDescriptionFromGemini(food['name']!);
      fetchedDescriptions.add(description);
    }

    setState(() {
      foodImages = fetchedImages;
      foodDescriptions = fetchedDescriptions;
      isLoading = false;
    });
  }

  Future<String> fetchFoodDescriptionFromGemini(String foodName) async {
    const geminiApiKey = "AIzaSyAKbrzEr7khA-Fo99E96bMEDCXNdQqbhqs";

    final uri = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$geminiApiKey",
    );

    final requestBody = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {
              "text":
                  "Describe the food item '$foodName' in 2 short, fun sentences by giving it a personality like u do for people in a flirty way.reply in first person with as if u r '$foodName' but tone it down a little",
            },
          ],
        },
      ],
    };

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Gemini API response: $data");

      // Adjusted parsing for the Gemini API response structure
      final content = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return content?.toString().trim() ?? "No description available.";
    } else {
      print("Gemini API Error ${response.statusCode}: ${response.body}");
      return "No description available.";
    }
  }

  // THIS IS A KEY CHANGE: This function now navigates to the VirtualEatPage
  // and passes the REAL camera and the specific food image URL.
  void onFoodMatched(String imageUrl, String foodName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VirtualEatPage(
          camera: widget.camera, // Use the real camera passed to this widget
          foodImageUrl: imageUrl, // Pass the URL of the swiped food
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (foodImages.isEmpty) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 202, 23, 23),
        appBar: AppBar(
          title: Text(
            'SNACKER',
            style: GoogleFonts.nunito(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: const Color.fromARGB(255, 229, 83, 43),
              letterSpacing: -0.5,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 202, 23, 23),
        ),
        body: const Center(
          child: Text(
            'No food images found.',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      );
    }

    final cardsCount = foodImages.length;
    final numberOfCardsDisplayed = cardsCount.clamp(1, 3);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 202, 23, 23),
      appBar: AppBar(
        title: Text(
          'SNACKER',
          style: GoogleFonts.nunito(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: const Color.fromARGB(255, 229, 83, 43),
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 202, 23, 23),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color.fromARGB(255, 202, 23, 23),
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.home,
                color: Color.fromARGB(255, 229, 83, 43),
                size: 32,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.search,
                color: Color.fromARGB(255, 229, 83, 43),
                size: 32,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.person,
                color: Color.fromARGB(255, 229, 83, 43),
                size: 32,
              ),
            ),
          ],
        ),
      ),
      body: CardSwiper(
        cardsCount: cardsCount,
        numberOfCardsDisplayed: numberOfCardsDisplayed,
        cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
          return Card(
            elevation: 5,
            color: const Color.fromARGB(255, 255, 254, 253),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: Image.network(
                            foodImages[index]['image']!,
                            height: 450,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            foodImages[index]['name']!,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            (foodDescriptions.length > index)
                                ? foodDescriptions[index]
                                : 'Loading description...',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.red,
                                child: IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.close,
                                    color: Color.fromARGB(255, 241, 126, 94),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              CircleAvatar(
                                backgroundColor: Colors.red,
                                child: IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.check,
                                    color: Color.fromARGB(255, 241, 126, 94),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        onSwipe: (previousIndex, currentIndex, direction) {
          if (direction == CardSwiperDirection.right) {
            onFoodMatched(
              foodImages[previousIndex]['image']!,
              foodImages[previousIndex]['name']!,
            );
          }
          return true;
        },
      ),
    );
  }
}

//================================================================================
// STEP 4: The VirtualEatPage (Your old MouthDetectorApp)
// It is now a regular widget that can be pushed by a Navigator.
//================================================================================
class VirtualEatPage extends StatefulWidget {
  final CameraDescription camera;
  final String foodImageUrl; // It now receives the food image URL

  const VirtualEatPage({
    super.key,
    required this.camera,
    required this.foodImageUrl,
  });

  @override
  State<VirtualEatPage> createState() => _VirtualEatPageState();
}

class _VirtualEatPageState extends State<VirtualEatPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late FaceDetector _faceDetector;
  bool _processing = false;
  int _frameCount = 0;

  bool _mouthOpen = false;
  int _burgerBitesLeft = 3;
  Rect? _faceRect;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initCamera();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableContours: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
  }

  Future<void> _initCamera() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller.initialize();
    await _controller.startImageStream(_processCameraImage);
  }

  void _processCameraImage(CameraImage image) async {
    if (_processing) return;
    _frameCount++;
    if (_frameCount % 3 != 0) {
      return;
    }
    _processing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _processing = false;
        return;
      }
      final faces = await _faceDetector.processImage(inputImage);

      if (mounted && faces.isNotEmpty) {
        final face = faces.first;
        final isOpen = _isMouthOpen(face);

        setState(() {
          _faceRect = face.boundingBox;
        });

        if (isOpen && !_mouthOpen && _burgerBitesLeft > 0) {
          setState(() {
            _mouthOpen = true;
            _burgerBitesLeft -= 1;
          });
        } else if (!isOpen && _mouthOpen) {
          setState(() {
            _mouthOpen = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error processing image: $e");
    } finally {
      if (mounted) {
        _processing = false;
      }
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = widget.camera;
    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (Platform.isAndroid) {
      final allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      return InputImage.fromBytes(
        bytes: bytes,
        inputImageData: InputImageData(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          imageRotation: rotation,
          inputImageFormat: format,
          planeData: image.planes.map((plane) {
            return InputImagePlaneMetadata(
              bytesPerRow: plane.bytesPerRow,
              height: plane.height,
              width: plane.width,
            );
          }).toList(),
        ),
      );
    } else if (Platform.isIOS) {
      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        inputImageData: InputImageData(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          imageRotation: rotation,
          inputImageFormat: format,
          planeData: [
            InputImagePlaneMetadata(
              bytesPerRow: plane.bytesPerRow,
              height: plane.height,
              width: plane.width,
            ),
          ],
        ),
      );
    }
    return null;
  }

  bool _isMouthOpen(Face face) {
    final upperLip = face.contours[FaceContourType.upperLipBottom]?.points;
    final lowerLip = face.contours[FaceContourType.lowerLipTop]?.points;

    if (upperLip == null ||
        lowerLip == null ||
        upperLip.isEmpty ||
        lowerLip.isEmpty) {
      return false;
    }

    final count = min(upperLip.length, lowerLip.length);
    double totalDistance = 0;
    for (int i = 0; i < count; i++) {
      totalDistance += (lowerLip[i].y - upperLip[i].y).abs();
    }
    final averageDistance = totalDistance / count;

    return averageDistance > 10;
  }

  Offset _getFoodPosition(Size screenSize) {
    if (_faceRect == null) {
      return Offset(screenSize.width / 2, screenSize.height / 2);
    }

    final faceCenter = _faceRect!.center;
    // Note: Camera coordinates and UI coordinates can be different.
    // This is a simple mapping. You may need to adjust it for perfect alignment.
    return Offset(
      screenSize.width - faceCenter.dx, // Invert X for front camera
      faceCenter.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    // No longer needs its own MaterialApp, it's part of the main app's navigation.
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'NOM NOM TIMEEE 😋😋',
          style: GoogleFonts.nunito(
            fontSize: 29,
            fontWeight: FontWeight.w900,
            color: const Color.fromARGB(255, 229, 83, 43),
            letterSpacing: -0.5,
          ),
        ),
        // This makes the app bar transparent
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // The back button is automatically added by the Navigator.
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color.fromARGB(255, 229, 83, 43),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final screenSize = MediaQuery.of(context).size;
            final foodPosition = _getFoodPosition(screenSize);

            double scale = (_burgerBitesLeft / 3);

            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller),

                // KEY CHANGE: Uses the food image from the URL passed to this widget
                if (_burgerBitesLeft > 0)
                  Positioned(
                    left: foodPosition.dx - 75, // Centering the image
                    top: foodPosition.dy - 75, // Centering the image
                    child: Transform.scale(
                      scale: scale,
                      // Use Image.network with the provided URL
                      child: Image.network(
                        widget.foodImageUrl,
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                        // Shows a loading indicator while the image downloads
                        loadingBuilder:
                            (
                              BuildContext context,
                              Widget child,
                              ImageChunkEvent? loadingProgress,
                            ) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                      ),
                    ),
                  ),

                // Status Text (Your original UI)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _burgerBitesLeft == 0
                          ? 'All gone! 🍔😋'
                          : _mouthOpen
                          ? '🍔 Nom nom nom!'
                          : '🍔 Ready to eat!',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 229, 83, 43),
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    // It's crucial to dispose of the controller when the widget is removed.
    _controller.stopImageStream();
    _controller.dispose();
    _faceDetector.close();
    super.dispose();
  }
}

