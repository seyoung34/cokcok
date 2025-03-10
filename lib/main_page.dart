import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<List<dynamic>> _csvData = []; // CSV 데이터를 저장하는 리스트
  bool _isSortedAscending = true; // true: 오름차순, false: 내림차순
  String _sortColumn = "이름"; // 기본 정렬 컬럼

  // 📌 CSV 파일 업로드 함수
  void _pickCSVFile() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = ".csv"; // CSV 파일만 선택 가능하도록 설정
    uploadInput.click(); // 파일 선택 창 열기

    // 파일이 선택되었을 때 실행
    uploadInput.onChange.listen((event) async {
      final files = uploadInput.files;
      if (files!.isEmpty) return; // 파일이 선택되지 않았으면 리턴

      final file = files[0]; // 첫 번째 파일 가져오기
      final reader = html.FileReader(); // 파일을 읽기 위한 객체 생성

      reader.readAsText(file); // 파일을 텍스트 형식으로 읽기
      reader.onLoadEnd.listen((event) {
        final csvString = reader.result as String; // 읽은 파일 데이터를 문자열로 변환
        List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString); // CSV 파싱

        setState(() {
          _csvData = csvTable.sublist(1); // 첫 번째 행(헤더) 제외하고 데이터 저장
        });
      });
    });
  }

  // 📌 테이블 정렬 함수
  void _sortTable(String column) {
    setState(() {
      _isSortedAscending = (_sortColumn == column) ? !_isSortedAscending : true; // 같은 컬럼 클릭 시 정렬 방향 변경
      _sortColumn = column; // 정렬된 컬럼 업데이트

      _csvData.sort((a, b) {
        int index = _getColumnIndex(column); // 컬럼 이름을 인덱스로 변환
        var valueA = a[index].toString(); // 첫 번째 값
        var valueB = b[index].toString(); // 두 번째 값
        return _isSortedAscending ? valueA.compareTo(valueB) : valueB.compareTo(valueA); // 오름차순/내림차순 정렬
      });
    });
  }

  // 📌 컬럼 이름을 인덱스로 변환하는 함수
  int _getColumnIndex(String column) {
    switch (column) {
      case "이름":
        return 0;
      case "성별":
        return 1;
      case "랭크(A~E)":
        return 2;
      default:
        return 0;
    }
  }

  // 📌 참가자 정보 수정 다이얼로그
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
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "이름"),
              ),
              TextField(
                controller: genderController,
                decoration: InputDecoration(labelText: "성별 (남/여)"),
              ),
              TextField(
                controller: rankController,
                decoration: InputDecoration(labelText: "랭크 (A~E)"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // 취소 버튼
              child: Text("취소"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _csvData[index][0] = nameController.text;
                  _csvData[index][1] = genderController.text;
                  _csvData[index][2] = rankController.text;
                });
                Navigator.pop(context); // 변경 후 다이얼로그 닫기
              },
              child: Text("저장"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("CSV 참가자 명단")), // 상단 앱바 제목

      body: Column(
        children: [
          // 📌 CSV 파일 업로드 버튼
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _pickCSVFile, // 파일 선택 기능 실행
              child: Text("CSV 파일 업로드"),
            ),
          ),

          // 📌 CSV 데이터 테이블 표시
          Expanded(
            child: _csvData.isEmpty
                ? Center(child: Text("파일을 업로드하세요.")) // 데이터가 없을 경우 메시지 표시
                : SingleChildScrollView(
              scrollDirection: Axis.horizontal, // 가로 스크롤 가능하도록 설정
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey[300]), // 헤더 배경색 설정
                sortColumnIndex: _getColumnIndex(_sortColumn), // 현재 정렬된 컬럼 지정
                sortAscending: _isSortedAscending, // 오름차순/내림차순 설정
                showCheckboxColumn: true,

                columns: [
                  // 📌 "이름" 컬럼 (정렬 가능)
                  DataColumn(
                    label: Text("이름", style: TextStyle(fontWeight: FontWeight.bold)),
                    onSort: (_, __) => _sortTable("이름"), // 클릭 시 정렬 실행
                  ),
                  // 📌 "성별" 컬럼 (정렬 가능)
                  DataColumn(
                    label: Text("성별", style: TextStyle(fontWeight: FontWeight.bold)),
                    onSort: (_, __) => _sortTable("성별"),
                  ),
                  // 📌 "랭크(A~E)" 컬럼 (정렬 가능)
                  DataColumn(
                    label: Text("랭크(A~E)", style: TextStyle(fontWeight: FontWeight.bold)),
                    onSort: (_, __) => _sortTable("랭크(A~E)"),
                  ),
                ],

                // 📌 CSV 데이터 행 생성 (클릭 시 수정 가능)
                rows: _csvData.asMap().entries.map((entry) {
                  int index = entry.key;
                  List<dynamic> row = entry.value;

                  return DataRow(
                    cells: [
                      DataCell(Text(row[0].toString()), onTap: () => _editParticipant(index)),
                      DataCell(Text(row[1].toString()), onTap: () => _editParticipant(index)),
                      DataCell(Text(row[2].toString()), onTap: () => _editParticipant(index)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
