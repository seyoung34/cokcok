import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'dart:html' as html;



class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<List<dynamic>> _csvData = [];

  //note 파일 업로드 처리
  void _pickCSVFile() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = ".csv";
    uploadInput.click();

    uploadInput.onChange.listen((event) async {
      final files = uploadInput.files;
      if (files!.isEmpty) return;

      final file = files[0];
      final reader = html.FileReader();

      reader.readAsText(file);
      reader.onLoadEnd.listen((event) {
        final csvString = reader.result as String;
        List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);

        setState(() {
          _csvData = csvTable.sublist(1); // 첫 번째 행(헤더) 제거
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("CSV 참가자 명단")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _pickCSVFile,
            child: Text("CSV 파일 업로드"),
          ),
          Expanded(
            child: _csvData.isEmpty
                ? Center(child: Text("파일을 업로드하세요."))
                : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("이름")),
                  DataColumn(label: Text("성별")),
                  DataColumn(label: Text("랭크(A~E)")),
                ],
                rows: _csvData.map((row) {
                  return DataRow(cells: [
                    DataCell(Text(row[0].toString())),
                    DataCell(Text(row[1].toString())),
                    DataCell(Text(row[2].toString())),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


