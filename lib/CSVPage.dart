import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';

class CSVPage extends StatefulWidget {
  @override
  _CSVPageState createState() => _CSVPageState();
}

class _CSVPageState extends State<CSVPage> {
  List<List<dynamic>> _csvData = [];  //csv데이터

  bool _isSortedAscending = true; // ture : 오름차순, flase : 내림차순
  String _sortColumn = "이름";  //기본 정렬 컬럼

  // CSV 파일 업로드 함수
  void _pickCSVFile() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = ".csv";  // csv파일만 선택 가능하도록 설정
    uploadInput.click();  // 파일 선택 창 열기

    uploadInput.onChange.listen((event) async {
      final files = uploadInput.files;
      if (files!.isEmpty) return;
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsText(file);  // 파일을 텍스트 형식으로 읽기
      reader.onLoadEnd.listen((event) {
        final csvString = reader.result as String; //읽은 파일 데이터를 문자열로 변환
        List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString); // csv 파싱
        setState(() => _csvData = csvTable.sublist(1)); //첫 번째 행 제거
      });
    });
  }

  // 테이블 정렬 함수
  void _sortTable(String column) {
    setState(() {
      _isSortedAscending = (_sortColumn == column) ? !_isSortedAscending : true;  //선택 된 컬럼을 재 클릭 시 내림|오름 차순 변경
      _sortColumn = column; // 선택 컬럼 설정
      _csvData.sort((a, b) {
        int index = _getColumnIndex(column);
        return _isSortedAscending
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

  // 수정 다이얼로그 설명 부분
  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(controller: controller, decoration: InputDecoration(labelText: label));
  }

  // 수정 다이얼로그 액션 버튼
  List<Widget> _buildDialogActions(int index, TextEditingController name, TextEditingController gender, TextEditingController rank) {
    return [
      TextButton(onPressed: () => Navigator.pop(context), child: Text("취소")),
      TextButton(
        onPressed: () {
          setState(() {
            _csvData[index][0] = name.text;
            _csvData[index][1] = gender.text;
            _csvData[index][2] = rank.text;
          });
          Navigator.pop(context);
        },
        child: Text("저장"),
      ),
    ];
  }

  //게터 이용해서 성별테이블 갱신
  List<List<dynamic>> get _malePlayers => _csvData.where((row) => row[1] == "남").toList();
  List<List<dynamic>> get _femalePlayers => _csvData.where((row) => row[1] == "여").toList();

  //테이블 생성(자료 시각화)
  Widget _buildDataTable(List<List<dynamic>> data, String title) {
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
              sortColumnIndex: _getColumnIndex(_sortColumn),
              sortAscending: _isSortedAscending,
              columns: _buildTableColumns(),
              rows: _buildTableRows(data),
            ),
          ),
        ],
      ),
    );
  }

  // 첫 번째 행 설정(속성)
  List<DataColumn> _buildTableColumns() {
    return [
      DataColumn(label: Text("이름"), onSort: (_, __) => _sortTable("이름")),
      DataColumn(label: Text("성별"), onSort: (_, __) => _sortTable("성별")),
      DataColumn(label: Text("순위"), onSort: (_, __) => _sortTable("순위")),
    ];
  }

  // 데이터 채우기
  List<DataRow> _buildTableRows(List<List<dynamic>> data) {
    return data.asMap() //리스트를 Map으로 변환(index가 키, 행 데이터가 값)
        .entries.map((entry) {  //각 항목을 반복하며 가공
      int index = entry.key;  //선택된 행의 인덱스
      List<dynamic> row = entry.value;  //선택된 행의 값
      return DataRow(
        cells: [
          // DataCell(Text(row[0].toString()), onTap: () => _editParticipant(index)),
          // DataCell(Text(row[1].toString()), onTap: () => _editParticipant(index)),
          // DataCell(Text(row[2].toString()), onTap: () => _editParticipant(index)),
          DataCell(Text(row[0].toString())),
          DataCell(Text(row[1].toString())),
          DataCell(Text(row[2].toString())),
        ],
        onLongPress: () => _editParticipant(index)
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
              _buildDataTable(_malePlayers, "남자 참가자"),
              _buildDataTable(_femalePlayers, "여자 참가자"),
            ],
          )
        ],
      ),
    );
  }
}
