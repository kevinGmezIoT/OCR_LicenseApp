import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';

import 'package:simple_edge_detection/edge_detection.dart';
import 'package:simple_edge_detection/warp_image.dart';
import 'package:simple_edge_detection/merge_image.dart';
import 'package:simple_edge_detection/process_image.dart';

class EdgeDetector {
  static Future<void> startEdgeDetectionIsolate(EdgeDetectionInput edgeDetectionInput) async {
    EdgeDetectionResult result = await EdgeDetection.detectEdges(edgeDetectionInput.inputPath);
    edgeDetectionInput.sendPort.send(result);
  }

  static Future<void> startProcessImageIsolate(EdgeDetectionInput edgeDetectionInput) async {
    ImageProcessingResult result = await ProcessImage.processImage(edgeDetectionInput.inputPath, edgeDetectionInput.outPath, edgeDetectionInput.mergeOutPath, 
                                                                        edgeDetectionInput.roi1, edgeDetectionInput.roi2, edgeDetectionInput.roi3, edgeDetectionInput.roi4, edgeDetectionInput.roi5, edgeDetectionInput.roi6, edgeDetectionInput.roi7, edgeDetectionInput.roi8, edgeDetectionInput.roi9, edgeDetectionInput.roi10,
                                                                        edgeDetectionInput.roi11, edgeDetectionInput.roi12, edgeDetectionInput.roi13, edgeDetectionInput.roi14, edgeDetectionInput.roi15, edgeDetectionInput.roi16, edgeDetectionInput.roi17, edgeDetectionInput.roi18, edgeDetectionInput.roi19, edgeDetectionInput.roi20);
    edgeDetectionInput.sendPort.send(result);
  }

  static Future<void> startWarpImageIsolate(EdgeDetectionInput edgeDetectionInput) async {
    Pointer<Utf8> result = await WarpImage.warpImage(edgeDetectionInput.inputPath,edgeDetectionInput.outPath,edgeDetectionInput.px1,edgeDetectionInput.py1,edgeDetectionInput.px2,edgeDetectionInput.py2,edgeDetectionInput.px4,edgeDetectionInput.py4,edgeDetectionInput.px3,edgeDetectionInput.py3); 
    edgeDetectionInput.sendPort.send(result.toString());
  }

  static Future<void> startMergeImageIsolate(EdgeDetectionInput edgeDetectionInput) async {
    Pointer<Utf8> result = await MergeImage.mergeImage(edgeDetectionInput.inputPath1, edgeDetectionInput.inputPath2, edgeDetectionInput.inputPath3, edgeDetectionInput.inputPath4, edgeDetectionInput.inputPath5,edgeDetectionInput.outPath); 
    edgeDetectionInput.sendPort.send(result.toString());
  }

  static Future<void> processImageIsolate(ProcessImageInput processImageInput) async {
    EdgeDetection.processImage(processImageInput.inputPath, processImageInput.edgeDetectionResult);
    processImageInput.sendPort.send(true);
  }

  Future<EdgeDetectionResult> detectEdges(String filePath) async {
    final port = ReceivePort();

    _spawnIsolate<EdgeDetectionInput>(
        startEdgeDetectionIsolate,
        EdgeDetectionInput(
          inputPath: filePath,
          sendPort: port.sendPort
        ),
        port
    );

    return await _subscribeToPort<EdgeDetectionResult>(port);
  }

  Future<ImageProcessingResult> imageProcessing(String filePath, String fileOPath, String mergeFileOPath,
                                              int roi1,int roi2,int roi3,int roi4,int roi5,
                                              int roi6,int roi7,int roi8,int roi9,int roi10,
                                              int roi11,int roi12,int roi13,int roi14,int roi15,
                                              int roi16,int roi17,int roi18,int roi19,int roi20) async {
    final port = ReceivePort();

    _spawnIsolate<EdgeDetectionInput>(
        startProcessImageIsolate,
        EdgeDetectionInput(
          inputPath: filePath,
          outPath: fileOPath,
          mergeOutPath: mergeFileOPath,
          roi1:roi1,
          roi2:roi2,
          roi3:roi3,
          roi4:roi4,
          roi5:roi5,
          roi6:roi6,
          roi7:roi7,
          roi8:roi8,
          roi9:roi9,
          roi10:roi10,
          roi11:roi11,
          roi12:roi12,
          roi13:roi13,
          roi14:roi14,
          roi15:roi15,
          roi16:roi16,
          roi17:roi17,
          roi18:roi18,
          roi19:roi19,
          roi20:roi20,
          sendPort: port.sendPort
        ),
        port
    );

    return await _subscribeToPort<ImageProcessingResult>(port);
  }

  Future<String> warpImage(String filePath, String fileOPath,int x1,int y1,int x2,int y2,int x4,int y4,int x3,int y3) async {
    final port = ReceivePort();

    _spawnIsolate<EdgeDetectionInput>(
        startWarpImageIsolate,
        EdgeDetectionInput(
          inputPath: filePath,
          outPath: fileOPath,
          px1:x1,
          py1:y1,
          px2:x2,
          py2:y2,
          px3:x3,
          py3:y3,
          px4:x4,
          py4:y4,
          sendPort: port.sendPort
        ),
        port
    );

    return await _subscribeToPort<String>(port);
  }

  Future<String> mergeImage(String filePath1, String filePath2, String filePath3, String filePath4, String filePath5, String fileOPath) async {
    final port = ReceivePort();

    _spawnIsolate<EdgeDetectionInput>(
        startMergeImageIsolate,
        EdgeDetectionInput(
          inputPath1: filePath1,
          inputPath2: filePath2,
          inputPath3: filePath3,
          inputPath4: filePath4,
          inputPath5: filePath5,
          outPath: fileOPath,
          sendPort: port.sendPort
        ),
        port
    );

    return await _subscribeToPort<String>(port);
  }

  Future<bool> processImage(String filePath, EdgeDetectionResult edgeDetectionResult) async {
    final port = ReceivePort();

    _spawnIsolate<ProcessImageInput>(
      processImageIsolate,
      ProcessImageInput(
        inputPath: filePath,
        edgeDetectionResult: edgeDetectionResult,
        sendPort: port.sendPort
      ),
      port
    );

    return await _subscribeToPort<bool>(port);
  }

  void _spawnIsolate<T>(Function function, dynamic input, ReceivePort port) {
    Isolate.spawn<T>(
      function,
      input,
      onError: port.sendPort,
      onExit: port.sendPort
    );
  }

  Future<T> _subscribeToPort<T>(ReceivePort port) async {
    StreamSubscription sub;
    
    var completer = new Completer<T>();
    
    sub = port.listen((result) async {
      await sub?.cancel();
      completer.complete(await result);
    });
    
    return completer.future;
  }
}

class EdgeDetectionInput {
  EdgeDetectionInput({
    this.inputPath,
    this.sendPort,
    this.inputPath1,
    this.inputPath2,
    this.inputPath3,
    this.inputPath4,
    this.inputPath5,
    this.px1,
    this.py1,
    this.px2,
    this.py2,
    this.px3,
    this.py3,
    this.px4,
    this.py4,
    this.roi1, this.roi2, this.roi3, this.roi4,
    this.roi5, this.roi6, this.roi7, this.roi8,
    this.roi9, this.roi10, this.roi11, this.roi12,
    this.roi13, this.roi14, this.roi15, this.roi16,
    this.roi17, this.roi18, this.roi19, this.roi20,
    this.outPath,
    this.mergeOutPath
  });

  String inputPath, inputPath1, inputPath2, inputPath3, inputPath4, inputPath5;
  String outPath, mergeOutPath;
  int roi1, roi2, roi3, roi4;
  int roi5, roi6, roi7, roi8;
  int roi9, roi10, roi11, roi12;
  int roi13, roi14, roi15, roi16;
  int roi17, roi18, roi19, roi20;
  int px1, py1, px2, py2, px3, py3, px4, py4;
  SendPort sendPort;
}

class ProcessImageInput {
  ProcessImageInput({
    this.inputPath,
    this.edgeDetectionResult,
    this.sendPort
  });

  String inputPath;
  EdgeDetectionResult edgeDetectionResult;
  SendPort sendPort;
}