import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';

class CSVPage extends StatefulWidget {
  @override
  _CSVPageState createState() => _CSVPageState();
}

class _CSVPageState extends State<CSVPage> {
  List<List<dynamic>> _csvData = []; // CSV 데이터

  // 남성 참가자 테이블 데이터
  List<List<dynamic>> _malePlayers = [];
  String _maleSortColumn = "이름";
  bool _maleIsSortedAscending = true;

  // 여성 참가자 테이블 데이터
  List<List<dynamic>> _femalePlayers = [];
  String _femaleSortColumn = "이름";
  bool _femaleIsSortedAscending = true;

  // CSV 파일 업로드 함수
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
          _csvData = csvTable.sublist(1);
          _updatePlayerTables(); // 데이터 업데이트
        });
      });
    });
  }

  // 남성, 여성 테이블을 갱신하는 함수
  void _updatePlayerTables() {
    _malePlayers = _csvData.where((row) => row[1] == "남").toList();
    _femalePlayers = _csvData.where((row) => row[1] == "여").toList();
  }

  // 남자 테이블 정렬
  void _sortMaleTable(String column) {
    setState(() {
      _maleIsSortedAscending = (_maleSortColumn == column) ? !_maleIsSortedAscending : true;
      _maleSortColumn = column;
      _malePlayers.sort((a, b) {
        int index = _getColumnIndex(column);
        return _maleIsSortedAscending
            ? a[index].toString().compareTo(b[index].toString())
            : b[index].toString().compareTo(a[index].toString());
      });
    });
  }

  // 여자 테이블 정렬
  void _sortFemaleTable(String column) {
    setState(() {
      _femaleIsSortedAscending = (_femaleSortColumn == column) ? !_femaleIsSortedAscending : true;
      _femaleSortColumn = column;
      _femalePlayers.sort((a, b) {
        int index = _getColumnIndex(column);
        return _femaleIsSortedAscending
            ? a[index].toString().compareTo(b[index].toString())
            : b[index].toString().compareTo(a[index].toString());
      });
    });
  }

  // 선택 컬럼 인덱스 반환
  int _getColumnIndex(String column) {
    switch (column) {
      case "이름": return 0;
      case "성별": return 1;
      case "순위": return 2;
      default: return 0;
    }
  }

  // 참가자 정보 수정 다이얼로그
  void _editParticipant(int index) {
    TextEditingController nameController = TextEditingController(text: _csvData[index][0]);
    TextEditingController genderController = TextEditingController(text: _csvData[index][1]);
    TextEditingController rankController = TextEditingController(text: _csvData[index][2]);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("참가자 정보 수정"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField("이름", nameController),
              _buildTextField("성별 (남/여)", genderController),
              _buildTextField("순위", rankController),
            ],
          ),
          actions: _buildDialogActions(index, nameController, genderController, rankController),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(controller: controller, decoration: InputDecoration(labelText: label));
  }

  List<Widget> _buildDialogActions(int index, TextEditingController name, TextEditingController gender, TextEditingController rank) {
    return [
      TextButton(onPressed: () => Navigator.pop(context), child: Text("취소")),
      TextButton(
        onPressed: () {
          setState(() {
            _csvData[index][0] = name.text;
            _csvData[index][1] = gender.text;
            _csvData[index][2] = rank.text;
            _updatePlayerTables();
          });
          Navigator.pop(context);
        },
        child: Text("저장"),
      ),
    ];
  }

  Widget _buildDataTable(List<List<dynamic>> data, String title, Function(String) sortFunction) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          data.isEmpty
              ? Center(child: Text("데이터 없음"))
              : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey[300]),
              columns: _buildTableColumns(sortFunction),
              rows: _buildTableRows(data),
            ),
          ),
        ],
      ),
    );
  }

  List<DataColumn> _buildTableColumns(Function(String) sortFunction) {
    return [
      DataColumn(label: Text("이름"), onSort: (_, __) => sortFunction("이름")),
      DataColumn(label: Text("성별"), onSort: (_, __) => sortFunction("성별")),
      DataColumn(label: Text("순위"), onSort: (_, __) => sortFunction("순위")),
    ];
  }

  List<DataRow> _buildTableRows(List<List<dynamic>> data) {
    return data.asMap().entries.map((entry) {
      int index = entry.key;
      List<dynamic> row = entry.value;
      return DataRow(
        cells: [
          DataCell(Text(row[0].toString())),
          DataCell(Text(row[1].toString())),
          DataCell(Text(row[2].toString())),
        ],
        onLongPress: () => _editParticipant(index),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("CSV 참가자 명단")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(onPressed: _pickCSVFile, child: Text("CSV 파일 업로드")),
          ),
          Row(
            children: [
              _buildDataTable(_malePlayers, "남자 참가자", _sortMaleTable),
              _buildDataTable(_femalePlayers, "여자 참가자", _sortFemaleTable),
            ],
          )
        ],
      ),
    );
  }
}
