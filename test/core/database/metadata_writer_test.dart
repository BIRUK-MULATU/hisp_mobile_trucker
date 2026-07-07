//This is a JSON based test of metadata writer.
//Run: flutter test test/core/database/metadata_writer_test.dart
//Flow: Read JSON file -> decode -> write to database -> read back from database -> encode -> compare with original JSON  

import 'dart:convert'; //JSON Decode
import 'dart:io'; //File

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/database/app_database.dart';
import 'package:hisp_mobile_trucker/core/database/metadata_writer.dart';



