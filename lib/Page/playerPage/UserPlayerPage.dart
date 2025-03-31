import 'package:flutter/material.dart';
import 'PlayerPageBase.dart';

class UserPlayerPage extends PlayerPageBase {
  final VoidCallback onAdminRequest;
  const UserPlayerPage({super.key, required this.onAdminRequest});

  @override
  _UserPlayerPageState createState() => _UserPlayerPageState();
}

class _UserPlayerPageState extends PlayerPageBaseState<UserPlayerPage> {
  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("참가자 보기"),
        actions: [
          IconButton(
            onPressed: widget.onAdminRequest,
            icon: Icon(Icons.lock),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        child: isMobile
            ? Column(
          children: _buildPlayerTables(),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _buildPlayerTables(),
        ),
      ),
    );
  }

  // 공통 테이블 빌더
  List<Widget> _buildPlayerTables() {
    return [
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
    ];
  }
}
