import 'package:cokcok/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'package:csv/csv.dart';
import '../../model/Player.dart';
import 'PlayerPageBase.dart';

class AdminPlayerPage extends PlayerPageBase {
  const AdminPlayerPage({super.key});

  @override
  _AdminPlayerPageState createState() => _AdminPlayerPageState();
}

class _AdminPlayerPageState extends PlayerPageBaseState<AdminPlayerPage> {
  List<List<dynamic>> _csvData = [];
  String? selectedFile;
  FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text("운영자 - 참가자 관리")),
      body: Column(
        children: [
          // 🔹 버튼 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: _uploadCSV, child: const Text("CSV 업로드")),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(selectedFile ?? " "),
              ),
              ElevatedButton(onPressed: _convertAndSave, child: const Text("변환 후 저장")),
              ElevatedButton(onPressed: _deleteAll, child: const Text("전체 삭제")),
            ],
          ),

          // 🔹 테이블 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildDataTable(
                players: malePlayers,
                title: "남성 참가자",
                sortColumn: maleSortColumn,
                ascending: maleAscending,
                onSort: (col) => sortPlayers(col, TableType.male),
                type: TableType.male,
                backgroundColor: Colors.blue.shade100,
              ),
              buildDataTable(
                players: mixedPlayers,
                title: "혼성 참가자",
                sortColumn: mixedSortColumn,
                ascending: mixedAscending,
                onSort: (col) => sortPlayers(col, TableType.mixed),
                type: TableType.mixed,
                backgroundColor: Colors.green.shade100,
              ),
              buildDataTable(
                players: femalePlayers,
                title: "여성 참가자",
                sortColumn: femaleSortColumn,
                ascending: femaleAscending,
                onSort: (col) => sortPlayers(col, TableType.female),
                type: TableType.female,
                backgroundColor: Colors.pink.shade100,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 CSV 파일 업로드
  void _uploadCSV() {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.csv';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final file = uploadInput.files?.first;
      if (file == null) return;

      final reader = html.FileReader();
      reader.readAsText(file);

      reader.onLoadEnd.listen((event) {
        final csvString = reader.result as String;
        _csvData = const CsvToListConverter().convert(csvString);
        setState(() {
          selectedFile = file.name;
        });
      });
    });

  }

  // 🔹 CSV 데이터를 Firestore에 저장
  void _convertAndSave() async {
    if (_csvData.isEmpty) return;

    _csvData = _csvData.sublist(1); // 첫 행 제거 (헤더)

    List<Player> players = [];
    for (var row in _csvData) {
      try {
        Player p = Player(
          name: row[0].toString(),
          gender: row[1].toString(),
          rank: int.tryParse(row[2].toString()) ?? 0,
          isMixed: row.length > 3 && row[3].toString().trim() == "참",
        );
        players.add(p);
      } catch (e) {
        print("⚠️ 변환 오류: $row → $e");
      }
    }

    await _saveToFirestore(players);
  }

  // 🔹 Firestore 저장
  Future<void> _saveToFirestore(List<Player> players) async {
    _firestoreService.savePlayers(players, "참가자");

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("저장 완료!"),duration: Duration(seconds: 1),));
    await loadPlayers(); // 새로고침
  }

  // 🔹 전체 삭제
  Future<void> _deleteCollection(String category) async {
    final snapshot = await FirebaseFirestore.instance.collection(category).get();
    final batch = FirebaseFirestore.instance.batch();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

  }

  Future<void> _deleteAll() async {
    await _deleteCollection("참가자");
    await _deleteCollection("남성 복식 팀");
    await _deleteCollection("여성 복식 팀");
    await _deleteCollection("혼성 복식 팀");
    await _deleteCollection("경기 기록");
    await _deleteCollection("부");

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("전체 삭제 완료")));
    await loadPlayers(); // 새로고침
  }

}
