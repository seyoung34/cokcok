import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'model/Player.dart';


class CSVPage extends StatefulWidget {
  @override
  _CSVPageState createState() => _CSVPageState();
}

enum TableType { male, female, mixed }

class _CSVPageState extends State<CSVPage> {
  List<List<dynamic>> _csvData = []; // CSV 데이터
  String? selectedFile;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<List<Player>> playerList = []; //male,femal,mixed

  // 남성 참가자 테이블 데이터
  List<Player> _malePlayers = [];
  String _maleSortColumn = "이름";
  bool _maleIsSortedAscending = true;

  // 여성 참가자 테이블 데이터
  List<Player> _femalePlayers = [];
  String _femaleSortColumn = "이름";
  bool _femaleIsSortedAscending = true;

  //혼성 참가자 테이블 데이터
  List<Player> _mixedPlayers = [];
  String _mixedSortColumn = "이름";
  bool _mixedIsSortedAscending = true;

  @override
  void initState() {
    super.initState();
    // loadTableData();
    _loadPlayersFromFirestore();
  }

  // 📌 Firestore에서 참가자 데이터 불러오기
  Future<void> _loadPlayersFromFirestore() async {
    List<Player> maleList = [];
    List<Player> femaleList = [];
    List<Player> mixedList = [];

    QuerySnapshot snapshot = await _firestore.collection("참가자").get();

    for (var doc in snapshot.docs) {
      Player player = Player.fromJson(doc.data() as Map<String, dynamic>);
      if (player.gender == "남") {
        maleList.add(player);
      } else if (player.gender == "여") {
        femaleList.add(player);
      }
      if (player.isMixed) {
        mixedList.add(player);
      }

    }

    setState(() {
      _malePlayers = maleList;
      _femalePlayers = femaleList;
      _mixedPlayers = mixedList;
    });

    print("📌 Firestore에서 참가자 데이터 로드 완료...CSVPage");
  }


  // CSV 파일 업로드 함수
  void _pickCSVFile() async {
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
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
        _csvData = const CsvToListConverter().convert(csvString);

      });

      setState(() {
        selectedFile = file.name;
      });
    });
  }

  // 📌 Firestore에 참가자 저장
  Future<void> _savePlayersToFirestore(List<Player> players) async {
    WriteBatch batch = _firestore.batch();
    CollectionReference collectionRef = _firestore.collection("참가자");

    for (var player in players) {
      DocumentReference docRef = collectionRef.doc(player.name);
      batch.set(docRef, player.toJson());
    }

    await batch.commit();
    print("📌 Firestore에 참가자 저장 완료");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("저장 완료!")),
    );

    _loadPlayersFromFirestore(); // 저장 후 데이터 새로 불러오기
  }


  // 📌 CSV 데이터를 변환하여 Firestore에 저장
  void _convertCSVToPlayers() {
    List<Player> playerList = [];
    _csvData = _csvData.sublist(1); //컬럼 정보 빼기

    for (var row in _csvData) {
      try {
        Player player = Player(
          name: row[0].toString(),
          gender: row[1].toString(),
          rank: int.tryParse(row[2].toString()) ?? 0,
          isMixed: row.length > 3 && row[3].toString().trim() == "참",
        );

        playerList.add(player);
      } catch (e) {
        print("⚠️ 데이터 변환 오류: $row → $e");
      }
    }

    _savePlayersToFirestore(playerList);
  }


  // 남자 테이블 정렬
  void _sortMaleTable(String column) {
    setState(() {
      _maleIsSortedAscending =
          (_maleSortColumn == column) ? !_maleIsSortedAscending : true;
      _maleSortColumn = column;

      _malePlayers.sort((a, b) {
        // 정렬할 속성 결정
        Comparable aValue, bValue;

        switch (column) {
          case "이름":
            aValue = a.name;
            bValue = b.name;
            break;
          case "성별":
            aValue = a.gender;
            bValue = b.gender;
            break;
          case "순위":
            aValue = a.rank;
            bValue = b.rank;
            break;
          default:
            return 0; // 정렬 불가
        }

        return _maleIsSortedAscending
            ? aValue.compareTo(bValue)
            : bValue.compareTo(aValue);
      });
    });
  }

  // 여자 테이블 정렬
  void _sortFemaleTable(String column) {
    setState(() {
      _femaleIsSortedAscending =
          (_femaleSortColumn == column) ? !_femaleIsSortedAscending : true;
      _femaleSortColumn = column;

      _femalePlayers.sort((a, b) {
        // 정렬할 속성 결정
        Comparable aValue, bValue;

        switch (column) {
          case "이름":
            aValue = a.name;
            bValue = b.name;
            break;
          case "성별":
            aValue = a.gender;
            bValue = b.gender;
            break;
          case "순위":
            aValue = a.rank;
            bValue = b.rank;
            break;
          default:
            return 0; // 정렬 불가
        }

        return _femaleIsSortedAscending
            ? aValue.compareTo(bValue)
            : bValue.compareTo(aValue);
      });
    });
  }

  // 혼복 테이블 정렬
  void _sortMixedTable(String column) {
    setState(() {
      _mixedIsSortedAscending =
          (_mixedSortColumn == column) ? !_mixedIsSortedAscending : true;
      _mixedSortColumn = column;

      _mixedPlayers.sort((a, b) {
        // 정렬할 속성 결정
        Comparable aValue, bValue;

        switch (column) {
          case "이름":
            aValue = a.name;
            bValue = b.name;
            break;
          case "성별":
            aValue = a.gender;
            bValue = b.gender;
            break;
          case "순위":
            aValue = a.rank;
            bValue = b.rank;
            break;
          default:
            return 0; // 정렬 불가
        }

        return _mixedIsSortedAscending
            ? aValue.compareTo(bValue)
            : bValue.compareTo(aValue);
      });
    });
  }

  // 선택 컬럼 인덱스 반환
  int _getColumnIndex(String column) {
    switch (column) {
      case "이름":
        return 0;
      case "성별":
        return 1;
      case "순위":
        return 2;
      default:
        return 0;
    }
  }

  // 📌 참가자 정보 수정 다이얼로그
  void _editParticipant(Player player) {
    TextEditingController nameController = TextEditingController(text: player.name);
    TextEditingController genderController = TextEditingController(text: player.gender);
    TextEditingController rankController = TextEditingController(text: player.rank.toString());

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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("취소"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  player.name = nameController.text;
                  player.gender = genderController.text;
                  player.rank = int.tryParse(rankController.text) ?? player.rank;
                });

                _firestore.collection("참가자").doc(player.name).set(player.toJson());
                print("📌 참가자 정보 Firestore에 저장됨");
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("참가자 정보 firestore에 저장됨")));
                Navigator.pop(context);
              },
              child: Text("저장"),
            ),
          ],
        );
      },
    );

  }

  // 다이얼로그의 텍스트입력필드
  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
        controller: controller, decoration: InputDecoration(labelText: label));
  }

  // 📌 참가자 삭제
  void _deleteParticipants() async {
    QuerySnapshot snapshot = await _firestore.collection("참가자").get();
    WriteBatch batch = _firestore.batch();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    print("📌 Firestore 참가자 데이터 삭제 완료");
    _loadPlayersFromFirestore();
  }

  Future<void> deleteAllData() async {
    await _deleteCollection("참가자");
    await _deleteCollection("남성 복식 팀");
    await _deleteCollection("여성 복식 팀");
    await _deleteCollection("혼성 복식 팀");

    print("📌 모든 컬렉션 데이터 삭제 완료");
  }

// 특정 컬렉션의 모든 문서 삭제
  Future<void> _deleteCollection(String collectionName) async {
    final snapshot = await FirebaseFirestore.instance.collection(collectionName).get();
    final batch = FirebaseFirestore.instance.batch();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    print("✅ $collectionName 컬렉션 삭제 완료");
  }




  //테이블 만들기
  Widget _buildDataTable(
      List<Player> data,
      String title,
      int columnIndex,
      bool sortedAscend,
      Function(String) sortFunction,
      TableType tableType,
      Color backgroundColor) {

    return SizedBox( // 🔹 Expanded 대신 SizedBox 사용
      width: 450, // 🔹 테이블 너비 조정 (적절한 크기로 변경 가능)
      height: 600,
      child: Container(
        // color: backgroundColor,
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            data.isEmpty
                ? Center(child: Text("데이터 없음"))
                : Expanded(
                  child: SingleChildScrollView(
                  scrollDirection: Axis.vertical, // 🔹 세로 스크롤 추가
                  child: SizedBox(
                    width: 400,
                    child: DataTable(
                    decoration: BoxDecoration(
                      color: backgroundColor, // 테이블 배경색
                      border: Border.all(color: Colors.black, width: 1), // 파란색 테두리
                      borderRadius: BorderRadius.circular(1), // 테이블 모서리를 둥글게
                    ),
                    showBottomBorder: true,
                    columnSpacing: 80, // 🔹 컬럼 간 간격 증가
                    headingRowColor: WidgetStateProperty.all(Colors.grey[300]),
                    sortColumnIndex: columnIndex,
                    sortAscending: sortedAscend,
                    columns: _buildTableColumns(sortFunction),
                    rows: _buildTableRows(data, tableType),
                                  ),
                  ),
                              ),
                ),
          ],
        ),
      ),
    );
  }

  // 컬럼 정의
  List<DataColumn> _buildTableColumns(Function(String) sortFunction) {
    return [
      DataColumn(label: Text("이름"), onSort: (_, __) => sortFunction("이름")),
      DataColumn(label: Text("성별"), onSort: (_, __) => sortFunction("성별")),
      DataColumn(label: Text("순위"), onSort: (_, __) => sortFunction("순위")),
    ];
  }

  // 테이블 행 데이터 반환
  List<DataRow> _buildTableRows(List<Player> data, TableType tableType) {
    return data.asMap().entries.map((entry) {
      // 키 : 인덱스, 값 : 속성
      int index = entry.key;
      Player player = entry.value; // 각 행은 Player 객체가 됨

      return DataRow(
        cells: [
          DataCell(Text(player.name)), // 이름
          DataCell(Text(player.gender)), // 성별
          DataCell(Text(player.rank.toString())), // 순위 (int → String 변환)
        ],
        onLongPress: () => _editParticipant(player),
      );
    }).toList();
  }


  //Player 데이터 sharedPreference에 저장하기
  Future<void> savePlayersToSharedPreferences(List<Player> players, String key) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> playersJson =
        players.map((player) => jsonEncode(player.toJson())).toList();
    await prefs.setStringList(key, playersJson);
  }

  //sharedPreference에서 List<Player>를 불러오기
  Future<List<Player>> loadPlayersFromSharedPreferences(String key) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? playersJson = prefs.getStringList(key);

    if (playersJson == null) return []; // 저장된 데이터가 없을 경우 빈 리스트 반환

    List<Player> players =
        playersJson.map((json) => Player.fromJson(jsonDecode(json))).toList();
    print("📌 [$key] 불러오기 완료: $players");
    return players;
  }

  // sharedPreference 저장하는 함수 종류별 호출
  // void callSavePlayersToSharedPreferences() {
  //   savePlayersToSharedPreferences(_malePlayers, "남성 참가자");
  //   savePlayersToSharedPreferences(_femalePlayers, "여성 참가자");
  //   savePlayersToSharedPreferences(_mixedPlayers, "혼복 참가자");
  //   loadTableData();
  // }

  //sharedPreference에서 불러와서 데이터 셋팅, 자동 ui변경
  // void loadTableData() async {
  //   setState(() {
  //     _malePlayers = [];
  //     _femalePlayers = [];
  //     _mixedPlayers = [];
  //   });
  //
  //   List<Player> maleData = await loadPlayersFromSharedPreferences("남성 참가자");
  //   List<Player> femaleData = await loadPlayersFromSharedPreferences("여성 참가자");
  //   List<Player> mixedData = await loadPlayersFromSharedPreferences("혼복 참가자");
  //
  //   setState(() {
  //     _malePlayers = maleData;
  //     _femalePlayers = femaleData;
  //     _mixedPlayers = mixedData;
  //   });
  //
  //   print("📌 SharedPreferences 데이터 로드 완료.");
  // }

  //sharedPreference의 데이터 삭제(남성,여성,혼복 참가자)
  // void deleteData() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove("남성 참가자");
  //   await prefs.remove("여성 참가자");
  //   await prefs.remove("혼복 참가자");
  //
  //   print("📌 SharedPreferences 데이터 삭제 완료.");
  //
  //   // 삭제 후 UI 업데이트
  //   loadTableData();
  // }


  // 확인 버튼 ( 파일을 업로드 후 1행 제거, 성별과 혼복여부에 따라 데이터 분류
  // void convertFileButton(){
  //   if(selectedFile != null) { //업로드 되어 있으면
  //     // _convertCSVToPlayers(_csvData.sublist(1));  //sharedPrefenece에 변환해서 저장됨
  //
  //     // SharedPreferences에서 데이터를 다시 불러와 테이블 업데이트
  //     loadTableData();
  //
  //     setState(() {
  //       selectedFile = null;
  //     });
  //   }
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("CSV 참가자 명단")),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: _pickCSVFile, child: Text("CSV 파일 업로드")),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(selectedFile ?? " "),
              ),
              ElevatedButton(onPressed: _convertCSVToPlayers, child: Text("변환 후 저장")),
              ElevatedButton(onPressed: deleteAllData, child: Text("모든 데이터 삭제")),
              ElevatedButton(onPressed: _loadPlayersFromFirestore, child: Text("테스트")),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDataTable(_malePlayers, "남성 참가자",
                  _getColumnIndex(_maleSortColumn), _maleIsSortedAscending, _sortMaleTable,
                  TableType.male, Colors.blue.shade100),

              _buildDataTable(_mixedPlayers, "혼복 참가자",
                  _getColumnIndex(_mixedSortColumn), _mixedIsSortedAscending, _sortMixedTable,
                  TableType.mixed, Colors.green.shade100),

              _buildDataTable(_femalePlayers, "여성 참가자",
                  _getColumnIndex(_femaleSortColumn), _femaleIsSortedAscending, _sortFemaleTable,
                  TableType.female, Colors.pink.shade100),
            ],
          ),
        ],
      ),
    );
  }


  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.black87),),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.teal.shade100,
      ),
    );
  }

  void showToast(){
    showSnackBar(context, "테스트");
  }

}
