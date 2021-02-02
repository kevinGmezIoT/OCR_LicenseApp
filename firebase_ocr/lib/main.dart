import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as Img;
import 'package:simple_edge_detection/edge_detection.dart';
import 'package:simple_edge_detection/process_image.dart';
import 'edge_detector.dart';
import 'package:image_size_getter/image_size_getter.dart' as isize;
import 'package:image_size_getter/file_input.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

import 'ImagePreview.dart';

typedef convert_func = Pointer<Uint32> Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, Int32, Int32, Int32, Int32);
typedef Convert = Pointer<Uint32> Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, int, int, int, int);

const String ssd = "SSD MobileNet";
const String yolo = "Tiny YOLOv2";
String time;
bool _pressed = false;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Camera App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController _camera;
  bool _cameraInitialized = false;
  CameraImage _savedImage;

  final _model = ssd;
  File _image;
  File _imageOut;

  double _imageWidth;
  double _imageHeight;

  List _recognitions;
  double _screenWidth;

  String _showText1,_showText2,_showText3,_showText4,_showText5;
  static const double Wi = 626;
  static const double Hi = 396;

  List <List<double>> denseRoi = [
    [7/Wi,19/Hi,230/Wi,52/Hi],
    [8/Wi,56/Hi,122/Wi,41/Hi],
    [7/Wi,87/Hi,120/Wi,27/Hi],
    [451/Wi,35/Hi,166/Wi,36/Hi],
    [207/Wi,113/Hi,129/Wi,37/Hi],
    ];

  Img.Image imageLicense, croppedImage, feature1, feature2, feature3, feature4, feature5;


  final DynamicLibrary convertImageLib = Platform.isAndroid
      ? DynamicLibrary.open("libconvertImage.so")
      : DynamicLibrary.process();
  Convert conv;


  @override
  void initState() {
    super.initState();
    _initializeCamera(); 
    loadModel().then((val) {      
    });
    // Load the convertImage() function from the library
    conv = convertImageLib.lookup<NativeFunction<convert_func>>('convertImage').asFunction<Convert>();
  }

  faceDetect(File file, File file2) async{
    Rect boundingBox;
    FirebaseVisionImage ourImage = FirebaseVisionImage.fromFile(file);
    final FaceDetector faceDetector = FirebaseVision.instance.faceDetector();
    final List<Face> faces = await faceDetector.processImage(ourImage);

    for (Face face in faces) {
    boundingBox = face.boundingBox;

    final double rotY = face.headEulerAngleY; // Head is rotated to the right rotY degrees
    final double rotZ = face.headEulerAngleZ; // Head is tilted sideways rotZ degrees

    // If landmark detection was enabled with FaceDetectorOptions (mouth, ears,
    // eyes, cheeks, and nose available):
    final FaceLandmark leftEar = face.getLandmark(FaceLandmarkType.leftEar);
    if (leftEar != null) {
      final leftEarPos = leftEar.position;
    }

    // If classification was enabled with FaceDetectorOptions:
    if (face.smilingProbability != null) {
      final double smileProb = face.smilingProbability;
    }

    // If face tracking was enabled with FaceDetectorOptions:
    if (face.trackingId != null) {
      final int id = face.trackingId;
    }
  }

  print(boundingBox.topLeft);
  print(boundingBox.width);
  print(boundingBox.height);

  final faceImage = copyCrop(Img.decodeImage(await file.readAsBytes()),(boundingBox.topLeft.dx-0.15*boundingBox.width).toInt(),(boundingBox.topLeft.dy-0.2*boundingBox.height).toInt(),(1.3*boundingBox.width).toInt(),(1.4*boundingBox.height).toInt());

  file2.writeAsBytesSync(Img.encodePng(faceImage));
  croppedImage = Img.decodeImage(await file2.readAsBytes());

  setState(() {
    croppedImage = Img.copyResize(croppedImage, width: (_screenWidth*0.6).toInt());  
  });
  
    
  }

  loadModel() async {
    Tflite.close();
    try {
      String res;
      if (_model == yolo) {
        res = await Tflite.loadModel(
          model: "assets/detect.tflite",
          labels: "assets/labelmap.txt",
        );
      } else {
        res = await Tflite.loadModel(
          model: "assets/detect.tflite",
          labels: "assets/labelmap.txt",
        );
      }
      print(res);
    } on PlatformException {
      print("Failed to load the model");
    }
  }

  predictImage(File image) async {
    try{    
    if (image == null){return;}

    if (_model == yolo) {
      await yolov2Tiny(image);
    } else {
      await ssdMobileNet(image);
    }    
    
    _imageWidth = isize.ImageSizeGetter.getSize(FileInput(File(image.path))).width.toDouble();
    _imageHeight = isize.ImageSizeGetter.getSize(FileInput(File(image.path))).height.toDouble();
    _image = image;
    await _setImageCV(_image, _imageWidth, _imageHeight);
    if(croppedImage != null){
             Navigator.push(context, MaterialPageRoute(builder: 
            (context) => new ImagePreview(img: croppedImage, text1: _showText1, text2: _showText2, text3: _showText3, text4: _showText4, text5: _showText5, text6: time)));
          }
    }
    catch(e){
      print(e);
    }

  }

  Img.Image copyCrop(Img.Image src, int x, int y, int w, int h) {
  // Make sure crop rectangle is within the range of the src image.
  x = x.clamp(0, src.width - 1.0).toInt();
  y = y.clamp(0, src.height - 1.0).toInt();
  if (x + w > src.width) {
    w = src.width - x;
  }
  if (y + h > src.height) {
    h = src.height - y;
  }
  
  var dst = Img.Image(w, h, channels: src.channels, exif: src.exif, iccp: src.iccProfile);

  for (var yi = 0, sy = y; yi < h; ++yi, ++sy) {
    for (var xi = 0, sx = x; xi < w; ++xi, ++sx) {
      dst.setPixel(xi, yi, src.getPixel(sx, sy));
    }
  }

  return dst;
}

  _setImageCV(File _image, double _imageWidth, double _imageHeight) async {    
    File file = File(_image.path);     
    
    Directory dirPath =  await getTemporaryDirectory();
    final outImagePath = dirPath.path+"/outImage.jpg";
    final mergeImagePath = dirPath.path+"/mergeImage.jpg";
    final cutPath = dirPath.path+"/cutImage.jpg";
    final facePath = dirPath.path+"/faceImage.jpg";
    File faceFile = File(facePath);
    File cutFile = File(cutPath);
    faceDetect(file,faceFile);

    final int x = (_recognitions[0]['rect']['x']*_imageWidth).toInt();
    final int y = (_recognitions[0]['rect']['y']*_imageHeight).toInt();
    final int w = (_recognitions[0]['rect']['w']*_imageWidth).toInt();
    final int h = (_recognitions[0]['rect']['h']*_imageHeight).toInt();
    
    final licenseImage = copyCrop(Img.decodeImage(await file.readAsBytes()),x,y,w,h);
    imageLicense = licenseImage;
    cutFile.writeAsBytesSync(Img.encodePng(imageLicense));
    File _imagecut = File(cutFile.path);   
    _imageWidth = isize.ImageSizeGetter.getSize(FileInput(File(_imagecut.path))).width.toDouble();
    _imageHeight = isize.ImageSizeGetter.getSize(FileInput(File(_imagecut.path))).height.toDouble();    
    print(_imageWidth);
    print(_imageHeight);

    ImageProcessingResult edgeResult = await EdgeDetector().imageProcessing(_imagecut.path, outImagePath, mergeImagePath, 
                                                                          (denseRoi[0][0]*600).toInt(), (denseRoi[0][1]*380).toInt(), (denseRoi[0][2]*600).toInt(), (denseRoi[0][3]*380).toInt(), 
                                                                          (denseRoi[1][0]*600).toInt(), (denseRoi[1][1]*380).toInt(), (denseRoi[1][2]*600).toInt(), (denseRoi[1][3]*380).toInt(), 
                                                                          (denseRoi[2][0]*600).toInt(), (denseRoi[2][1]*380).toInt(), (denseRoi[2][2]*600).toInt(), (denseRoi[2][3]*380).toInt(), 
                                                                          (denseRoi[3][0]*600).toInt(), (denseRoi[3][1]*380).toInt(), (denseRoi[3][2]*600).toInt(), (denseRoi[3][3]*380).toInt(),                                                                            
                                                                          (denseRoi[4][0]*600).toInt(), (denseRoi[4][1]*380).toInt(), (denseRoi[4][2]*600).toInt(), (denseRoi[4][3]*380).toInt());

    double _x1 = edgeResult.topLeft.dx*_imageWidth;
    double _y1 = edgeResult.topLeft.dy*(_imageHeight);
    double _x2 = edgeResult.topRight.dx*_imageWidth;
    double _y2 = edgeResult.topRight.dy*(_imageHeight);
    double _x3 = edgeResult.bottomLeft.dx*_imageWidth;
    double _y3 = edgeResult.bottomLeft.dy*(_imageHeight);
    double _x4 = edgeResult.bottomRight.dx*_imageWidth;
    double _y4 = edgeResult.bottomRight.dy*(_imageHeight);
 
    print("el valor de x1: $_x1");
    print("el valor de y1: $_y1");
    print("el valor de x1: $_x2");
    print("el valor de y1: $_y2");
    print("el valor de x1: $_x3");
    print("el valor de y1: $_y3");
    print("el valor de w1: $_x4");
    print("el valor de h1: $_y4");
    
    _imageOut = File(outImagePath);    
    _imageOut = File(mergeImagePath);

    FirebaseVisionImage ourImage = FirebaseVisionImage.fromFile(_imageOut);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(ourImage);

    String textOCR1, textOCR2, textOCR3, textOCR4, textOCR5;
    int count = 0;

    for (TextBlock block in readText.blocks) {
      for (TextLine line in block.lines) {
        print(line.text);
        switch(count) { 
          case 0: { 
              textOCR1 = line.text; 
          } 
          break; 
          
          case 1: { 
              textOCR2 = line.text;  
          } 
          break; 

          case 2: { 
              textOCR3 = line.text;  
          } 
          break;

          case 3: { 
              textOCR4 = line.text; 
          } 
          break;

          case 4: { 
              textOCR5 = line.text; 
          } 
          break;
              
          default: { 
              //statements;  
          }
          break; 
        } 
        count++;
      }
    } 
    

    setState(() {
      _showText1 = textOCR1;
      _showText2 = textOCR2;
      _showText3 = textOCR3; 
      _showText4 = textOCR4;
      _showText5 = textOCR5;
      _pressed = false;
    });
    
  }
  yolov2Tiny(File image) async {
    final recognitions = await Tflite.detectObjectOnImage(
        path: image.path,
        model: "YOLO",
        threshold: 0.3,
        imageMean: 0.0,
        imageStd: 255.0,
        numResultsPerClass: 1);

    setState(() {
      _recognitions = recognitions;
    });
  }

  ssdMobileNet(File image) async {
    final recognitions = await Tflite.detectObjectOnImage( //final
        path: image.path, numResultsPerClass: 1);
    setState(() {
      _recognitions = recognitions;
    });
  }
  
  void _initializeCamera() async {
    // Get list of cameras of the device
    List<CameraDescription> cameras = await availableCameras(); 

    // Create the CameraController
    _camera = new CameraController(cameras[0], ResolutionPreset.veryHigh);
    _camera.initialize().then((_) async{
      // Start ImageStream
      await _camera.startImageStream((CameraImage image) => _processCameraImage(image)); 
      setState(() {
        _cameraInitialized = true;
      });
    });
  }

  void _processCameraImage(CameraImage image) async {
    setState(() {
      _savedImage = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    _screenWidth = size.width;    

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: 
          (_cameraInitialized && !_pressed)
          ? AspectRatio(aspectRatio: _camera.value.aspectRatio,
            child: CameraPreview(_camera),)
          : CircularProgressIndicator()
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Img.Image img;
          Directory _directory = await getTemporaryDirectory();
          String _imagePath = _directory.path + "/temp.jpg";
          File _imageFile = File(_imagePath);            

          _pressed=true;

          if(Platform.isAndroid){
            // Allocate memory for the 3 planes of the image
            Pointer<Uint8> p = allocate(count: _savedImage.planes[0].bytes.length);
            Pointer<Uint8> p1 = allocate(count: _savedImage.planes[1].bytes.length);
            Pointer<Uint8> p2 = allocate(count: _savedImage.planes[2].bytes.length);

            // Assign the planes data to the pointers of the image
            Uint8List pointerList = p.asTypedList(_savedImage.planes[0].bytes.length);
            Uint8List pointerList1 = p1.asTypedList(_savedImage.planes[1].bytes.length);
            Uint8List pointerList2 = p2.asTypedList(_savedImage.planes[2].bytes.length);
            pointerList.setRange(0, _savedImage.planes[0].bytes.length, _savedImage.planes[0].bytes);
            pointerList1.setRange(0, _savedImage.planes[1].bytes.length, _savedImage.planes[1].bytes);
            pointerList2.setRange(0, _savedImage.planes[2].bytes.length, _savedImage.planes[2].bytes);
            
            // Call the convertImage function and convert the YUV to RGB
            Pointer<Uint32> imgP = conv(p, p1, p2, _savedImage.planes[1].bytesPerRow,
              _savedImage.planes[1].bytesPerPixel, _savedImage.planes[0].bytesPerRow, _savedImage.height);
              
            // Get the pointer of the data returned from the function to a List
            List imgData = imgP.asTypedList((_savedImage.planes[0].bytesPerRow * _savedImage.height));
            // Generate image from the converted data  
            img = Img.Image.fromBytes(_savedImage.height, _savedImage.planes[0].bytesPerRow, imgData);
            
            // Free the memory space allocated
            // from the planes and the converted data
            free(p);
            free(p1);
            free(p2);
            free(imgP);
          }else if(Platform.isIOS){
            img = Img.Image.fromBytes(
              _savedImage.planes[0].bytesPerRow,
              _savedImage.height,
              _savedImage.planes[0].bytes,
              format: Img.Format.bgra,
            );
          }

          _imageFile.writeAsBytesSync(Img.encodePng(img));
          print("Write Image");
          int startTime = new DateTime.now().millisecondsSinceEpoch;
          await predictImage(File(_imageFile.path));
          int endTime = new DateTime.now().millisecondsSinceEpoch;
          print("Detection took ${endTime - startTime}");

          time = (endTime-startTime).toString();

          print("Image_Written");                   

        },
        tooltip: 'Increment',
        child: Icon(Icons.camera_alt),
      ), // This trailing comma makes auto-formatting nicer for build methods.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );    
  }  
}
