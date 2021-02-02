import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:ui';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';


class Coordinate extends Struct {
  @Double()
  double x;

  @Double()
  double y;

  factory Coordinate.allocate(double x, double y) =>
      allocate<Coordinate>().ref
        ..x = x
        ..y = y;
}

class NativeDetectionResult extends Struct {
  Pointer<Coordinate> topLeft;
  Pointer<Coordinate> topRight;
  Pointer<Coordinate> bottomLeft;
  Pointer<Coordinate> bottomRight;

  factory NativeDetectionResult.allocate(
      Pointer<Coordinate> topLeft,
      Pointer<Coordinate> topRight,
      Pointer<Coordinate> bottomLeft,
      Pointer<Coordinate> bottomRight) =>
      allocate<NativeDetectionResult>().ref
        ..topLeft = topLeft
        ..topRight = topRight
        ..bottomLeft = bottomLeft
        ..bottomRight = bottomRight;
}


typedef DetectEdgesFunction = Pointer<NativeDetectionResult> Function(
  Pointer<Utf8> imagePath
);

typedef DetectWarp_Function = Pointer<Utf8> Function(
  Pointer<Utf8> imagePath,
  Pointer<Utf8> imageOutPath,
  Int32 x1,
  Int32 y1,
  Int32 x2,
  Int32 y2,
  Int32 x4,
  Int32 y4,
  Int32 x3,
  Int32 y3,
);

typedef DetectWarp = Pointer<Utf8> Function(
  Pointer<Utf8> imagePath,
  Pointer<Utf8> imageOutPath,
  int x1,
  int y1,
  int x2,
  int y2,
  int x4,
  int y4,
  int x3,
  int y3,
);

// https://github.com/dart-lang/samples/blob/master/ffi/structs/structs.dart

class WarpImage { 
  static Future<Pointer<Utf8>> warpImage(String path, String out, dynamic x1, dynamic y1, dynamic x2, dynamic y2, dynamic x4, dynamic y4, dynamic x3, dynamic y3) async {
    DynamicLibrary nativeEdgeDetection = _getDynamicLibrary();    
    
    final Pointer<Utf8> Function(Pointer<Utf8> imagePath,Pointer<Utf8> imageOutPath, int px1, int py1, int px2, int py2, int px4, int py4, int px3, int py3) warpImage = nativeEdgeDetection
        .lookup<NativeFunction<DetectWarp_Function>>("image_warp")
        .asFunction<DetectWarp >();    
    
    return warpImage(Utf8.toUtf8(path),Utf8.toUtf8(out),x1,y1,x2,y2,x4,y4,x3,y3);
  }  

  static DynamicLibrary _getDynamicLibrary() {
    final DynamicLibrary nativeEdgeDetection = Platform.isAndroid
        ? DynamicLibrary.open("libnative_edge_detection.so")
        : DynamicLibrary.process();
    return nativeEdgeDetection;
  }
}