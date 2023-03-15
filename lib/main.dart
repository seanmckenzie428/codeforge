import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(400, 600),
    center: true,
    title: "Codeforge",
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodeForge',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const RandomCodeGenerator(),
    );
  }
}

class RandomCodeGenerator extends StatefulWidget {
  const RandomCodeGenerator({super.key});

  @override
  _RandomCodeGeneratorState createState() => _RandomCodeGeneratorState();
}

class _RandomCodeGeneratorState extends State<RandomCodeGenerator> {
  final _formKey = GlobalKey<FormState>();

  int _numCodes = 0;
  int _codeLength = 0;
  int _numCharsBetweenDashes = 0;
  int _codesPerFile = 0;
  String _outputFile = "";
  TextEditingController outputTextController = TextEditingController();
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Random Code Generator"),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: "Number of Codes"),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return "Please enter a number";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _numCodes = int.parse(value ?? "0");
                  },
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Code Length"),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return "Please enter a number";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _codeLength = int.parse(value ?? "0");
                  },
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Number of Characters Between Dashes"),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return "Please enter a number";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _numCharsBetweenDashes = int.parse(value ?? "0");
                  },
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: "Codes Per File"),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return "Please enter a number";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _codesPerFile = int.parse(value ?? "0");
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Output File"),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return "Please enter a valid file name";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _outputFile = value ?? _outputFile;
                  },
                  controller: outputTextController,
                ),
                const SizedBox(
                  height: 4.0,
                ),
                TextButton(
                  onPressed: () async {
                    _outputFile = await _getOutputLocation() ?? _outputFile;
                    outputTextController.text = _outputFile;
                  },
                  child: const Text("Browse"),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _isGenerating
                      ? null
                      : () async {
                          setState(() {
                            _isGenerating = true;
                          });
                          await handleGenerateButtonPress();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Generated $_numCodes codes'),
                              action: SnackBarAction(
                                label: 'View Files',
                                onPressed: () async {
                                  // Open file explorer to show csv files
                                  var f = File(_outputFile);
                                  // Windows
                                  try {
                                    await Process.run("explorer",  [f.parent.path]);
                                  } on Exception catch (e) {
                                    if (kDebugMode) {
                                      print(e);
                                    }
                                  }
                                  // Linux
                                  try {
                                    await Process.run("xdg-open",  [f.parent.path]);
                                  } on Exception catch (e) {
                                    if (kDebugMode) {
                                      print(e);
                                    }
                                  }
                                  // Mac
                                  try {
                                    await Process.run("open",  [f.parent.path]);
                                  } on Exception catch (e) {
                                    if (kDebugMode) {
                                      print(e);
                                    }
                                  }
                                },
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          setState(() {
                            _isGenerating = false;
                          });

                        },
                  child: _isGenerating ? const Text("Generating...") : const Text("Generate Codes"),
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> handleGenerateButtonPress() async {
    // if an input field is blank, the function won't return without this try catch, keeping the generate button disabled.
    try {
      if (_formKey.currentState?.validate() != null) {
        _formKey.currentState?.save();
        // var num = int.parse(_numCodes);
        int? num = _numCodes;
        int? len = _codeLength;
        int? dash = _numCharsBetweenDashes;

        final codes = await Isolate.run(() async {
          return _generateCodes(
              numCodes: num, codeLength: len, numCharsBetweenDashes: dash);
        });

        // final codes = _generateCodes(_numCodes, _codeLength, _numCharsBetweenDashes);

        if (_codesPerFile > 0 && _codesPerFile < _numCodes) {
          final files = _splitIntoFiles(codes, _codesPerFile);
          for (int i = 0; i < files.length; i++) {
            var stripExtension =
                _outputFile.substring(0, _outputFile.length - 4);
            final filename = "${stripExtension}_$i.csv";
            try {
              await _writeFile(filename, files[i]);
            } on Exception catch (e) {
              if (kDebugMode) {
                print(e);
              }
            }
          }
        } else {
          final filename = _outputFile;
          // await Isolate.run(() async {
          //   return _writeFile(filename, codes);
          // });
          try {
            await _writeFile(filename, codes);
          } on Exception catch (e) {
            if (kDebugMode) {
              print(e);
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return;
  }

  List<List<String>> _splitIntoFiles(List<String> codes, int codesPerFile) {
    final files = <List<String>>[];
    for (int i = 0; i < codes.length; i += codesPerFile) {
      final file = codes.sublist(i, i + codesPerFile);
      files.add(file);
    }
    return files;
  }

  Future<void> _writeFile(String filename, List<String> codes) async {
    final file = File(filename);
    final rows = codes.map((code) => [code]).toList();
    String csv = const ListToCsvConverter().convert(rows);
    await file.writeAsString(csv);

    // await Process.run('explorer', [directory.path]);
  }

  Future<String?> _getOutputLocation() async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: 'codes.csv',
      lockParentWindow: true,
      allowedExtensions: ["csv", "txt"],
    );

    // print(outputFile);

    if (outputFile == null) {
      // User canceled the picker
      return null;
    } else {
      return outputFile;
    }
  }
}

List<String> _generateCodes(
    {int? numCodes,
    int? codeLength,
    int? numCharsBetweenDashes,
    String? characterSet}) {


  characterSet ??= "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  numCodes ??= 1;
  codeLength ??= 15;
  numCharsBetweenDashes ??= 5;

  assert (numCodes < pow(characterSet.length, codeLength),
        "This combination of code length and number of codes will create duplicates.");

  Set<String> newCodes = {};
  final random = Random.secure();

  while (newCodes.length < numCodes) {
    final code = StringBuffer();
    int dashIncrementer = 0;

    for (var i = 0; i < codeLength; i++) {
      if (dashIncrementer >= numCharsBetweenDashes) {
        code.write("-");
        dashIncrementer = 0;
      }
      dashIncrementer++;

      code.write(characterSet[random.nextInt(characterSet.length)]);
    }

    newCodes.add(code.toString());
    code.clear();
  }

  return newCodes.toList();
}
