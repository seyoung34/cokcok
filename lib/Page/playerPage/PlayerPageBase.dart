import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/Player.dart';

enum TableType { male, female, mixed }

abstract class PlayerPageBase extends StatefulWidget {
  const PlayerPageBase({super.key});

  @override
  PlayerPageBaseState createState();
}

abstract class PlayerPageBaseState<T extends PlayerPageBase> extends State<T> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Player> malePlayers = [];
  List<Player> femalePlayers = [];
  List<Player> mixedPlayers = [];

  String maleSortColumn = "이름";
  bool maleAscending = true;
  String femaleSortColumn = "이름";
  bool femaleAscending = true;
  String mixedSortColumn = "이름";
  bool mixedAscending = true;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPlayers();
    print("initStat");
  }

  Future<void> loadPlayers() async {
    QuerySnapshot snapshot = await _firestore.collection("참가자").get();

    List<Player> males = [];
    List<Player> females = [];
    List<Player> mixeds = [];

    for (var doc in snapshot.docs) {
      Player player = Player.fromJson(doc.data() as Map<String, dynamic>);
      if (player.gender == "남성") males.add(player);
      if (player.gender == "여성") females.add(player);
      if (player.isMixed) mixeds.add(player);
    }

    setState(() {
      malePlayers = males;
      femalePlayers = females;
      mixedPlayers = mixeds;
      isLoading = false;
    });
  }

  // 공통 테이블 위젯
  Widget buildDataTable({
    required List<Player> players,
    required String title,
    required String sortColumn,
    required bool ascending,
    required void Function(String) onSort,
    required TableType type,
    required Color backgroundColor,
  }) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;
    double tableWidth = screenWidth < 600 ? screenWidth * 0.9 : screenWidth / 3 - 24;
    double maxTableHeight = screenWidth < 600 ? 400 : screenHeight-210; // 👉 반응형 높이 제한

    return Container(
      color: Colors.grey.shade100,
      width: tableWidth,
      // margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(8),
      margin: EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          players.isEmpty
              ? const Text("데이터 없음")
              : SizedBox(
            width: tableWidth,
            height: maxTableHeight,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border.all(color: Colors.black),
                ),
                columnSpacing: 50,
                headingRowColor: WidgetStateProperty.all(Colors.grey[300]),
                sortColumnIndex: getSortColumnIndex(sortColumn),
                sortAscending: ascending,
                columns: buildTableColumns(onSort),
                rows: buildTableRows(players),
              ),
            ),
          ),
        ],
      ),
    );
  }



  List<DataColumn> buildTableColumns(void Function(String) onSort) {
    return [
      DataColumn(label: Text("번호")),
      DataColumn(label: Text("이름"), onSort: (_, __) => onSort("이름")),
      DataColumn(label: Text("성별"), onSort: (_, __) => onSort("성별")),
      DataColumn(label: Text("순위"), onSort: (_, __) => onSort("순위")),
    ];
  }

  List<DataRow> buildTableRows(List<Player> players) {
    int count = 0;

    return players.map((player) {
      count++;
      return DataRow(
        cells: [
          DataCell(Text("$count")),
          DataCell(Text(player.name)),
          DataCell(Text(player.gender)),
          DataCell(Text(player.rank.toString())),
        ],
        onLongPress: () => _showEditDialog(player),
      );

    }).toList();
  }

  void _showEditDialog(Player player) {
    final nameController = TextEditingController(text: player.name);
    final genderController = TextEditingController(text: player.gender);
    final rankController = TextEditingController(text: player.rank.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("참가자 수정"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "이름"),
            ),
            TextField(
              controller: genderController,
              decoration: const InputDecoration(labelText: "성별"),
            ),
            TextField(
              controller: rankController,
              decoration: const InputDecoration(labelText: "순위"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          ElevatedButton(
            onPressed: () async {
              print("저장 눌렀음");
              final newName = nameController.text.trim();
              final newGender = genderController.text.trim();
              final newRank = int.tryParse(rankController.text.trim()) ?? 0;

              print("${newName}, ${newGender}, ${newRank}");

              if (newName.isNotEmpty && (newGender == "남성" || newGender == "여성")) {
                final doc = await _firestore
                    .collection("참가자")
                    .where(player.name, isEqualTo: player.name)
                    .get();

                print("${doc.docs.toString()}");

                if (doc.docs.isNotEmpty) {
                  await doc.docs.first.reference.update({
                    "name": newName,
                    "gender": newGender,
                    "rank": newRank,
                  });

                  Navigator.pop(context);
                  loadPlayers();
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("이름과 성별을 올바르게 입력하세요.")),
                );
              }
            },
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }


  int getSortColumnIndex(String column) {
    switch (column) {
      case "이름":
        return 1;
      case "성별":
        return 2;
      case "순위":
        return 3;
      default:
        return 3;
    }
  }

  void sortPlayers(String column, TableType type) {
    setState(() {
      List<Player> target;
      String currentSort;
      bool ascending;

      switch (type) {
        case TableType.male:
          target = malePlayers;
          currentSort = maleSortColumn;
          maleAscending = (maleSortColumn == column) ? !maleAscending : true;
          maleSortColumn = column;
          ascending = maleAscending;
          break;
        case TableType.female:
          target = femalePlayers;
          currentSort = femaleSortColumn;
          femaleAscending = (femaleSortColumn == column) ? !femaleAscending : true;
          femaleSortColumn = column;
          ascending = femaleAscending;
          break;
        case TableType.mixed:
          target = mixedPlayers;
          currentSort = mixedSortColumn;
          mixedAscending = (mixedSortColumn == column) ? !mixedAscending : true;
          mixedSortColumn = column;
          ascending = mixedAscending;
          break;
      }

      target.sort((a, b) {
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
            return 0;
        }
        return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      });
    });
  }

  @override
  Widget build(BuildContext context); // 자식 클래스에서 구현
}
