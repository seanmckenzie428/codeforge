import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

void main() {
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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        ),
        home: RandomCodeGenerator(),
      );
  }
}


class RandomCodeGenerator extends StatefulWidget {
  @override
  _RandomCodeGeneratorState createState() => _RandomCodeGeneratorState();
}

class _RandomCodeGeneratorState extends State<RandomCodeGenerator> {
  final _formKey = GlobalKey<FormState>();

  int _numCodes = 0;
  int _codeLength = 0;
  int _numCharsBetweenDashes = 0;
  int _codesPerFile = 0;
  String _outputDirectory = "";

  String _outputText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Random Code Generator"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "Number of Codes"),
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
                  decoration: InputDecoration(labelText: "Code Length"),
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
                  decoration: InputDecoration(
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
                  decoration: InputDecoration(labelText: "Codes Per File"),
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
                  decoration: InputDecoration(labelText: "Output Directory"),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return "Please enter a directory";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _outputDirectory = value ?? "";
                  },
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  child: Text("Generate Codes"),
                  onPressed: () async {
                    if (_formKey.currentState?.validate() != null) {
                      _formKey.currentState?.save();
                      setState(() {
                        _outputText = "";
                      });

                      final codes = _generateCodes(
                          _numCodes, _codeLength, _numCharsBetweenDashes);

                      if (_codesPerFile > 0) {
                        final files = _splitIntoFiles(codes, _codesPerFile);
                        for (int i = 0; i < files.length; i++) {
                          final filename = "$_outputDirectory/file_$i.csv";
                          await _writeFile(filename, files[i]);
                        }
                      } else {
                        final filename = "$_outputDirectory/codes.csv";
                        await _writeFile(filename, codes);
                      }

                      setState(() {});
                    }
                  },
                ),
                SizedBox(height: 16.0),
                Text(_outputText),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _generateCodes(
      int numCodes, int codeLength, int numCharsBetweenDashes) {
    final codes = List.generate(numCodes, (_) {
      final random = Random.secure();
      final code = List.generate(codeLength, (i) {
        if ((i + 1) % (numCharsBetweenDashes + 1) == 0) {
          return "-";
        } else {
          return String.fromCharCode(random.nextInt(26) + 65);
        }
      }).join("");
      return code.substring(0, code.length - 1);
    });
    return codes;
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
    final directory = await getApplicationDocumentsDirectory();
    final file = File("${directory.path}/$filename");
    final rows = codes.map((code) => [code]).toList();
    String csv = const ListToCsvConverter().convert(rows);
    await file.writeAsString(csv);

    await Process.run('explorer', [directory.path]);
  }


}
