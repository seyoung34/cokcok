import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/Player.dart';
import 'model/Team.dart';

class TeamManagementPage extends StatefulWidget {
  @override
  _TeamManagementPageState createState() => _TeamManagementPageState();
}

class _TeamManagementPageState extends State<TeamManagementPage> {
  List<Player> maleParticipants = [];
  List<Player> femaleParticipants = [];

  List<Team> maleTeams = []; // 남성 복식 팀
  List<Team> femaleTeams = []; // 여성 복식 팀
  List<Team> mixedTeams = []; // 혼성 복식 팀

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    maleParticipants = await loadPlayersFromSharedPreferences("남성 참가자");
    femaleParticipants = await loadPlayersFromSharedPreferences("여성 참가자");

    print("📌 남성 참가자 불러오기: $maleParticipants");
    print("📌 여성 참가자 불러오기: $femaleParticipants");

    setState(() {}); // UI 갱신
  }

  // 📌 실력 균형 기반 팀 구성
  void _generateTeams() async{
    // List<Player> males = participants.where((p) => p.gender == "남").toList();
    // List<Player> females = participants.where((p) => p.gender == "여").toList();
    List<Player> males = await loadPlayersFromSharedPreferences("남성 참가자");
    List<Player> females = await loadPlayersFromSharedPreferences("여성 참가자");
    print(males);

    // 랭크를 숫자로 변환 후 정렬
    males.sort((a, b) => a.rank.compareTo(b.rank));
    females.sort((a, b) => a.rank.compareTo(b.rank));

    List<Team> newMaleTeams = [];
    List<Team> newFemaleTeams = [];
    List<Team> newMixedTeams = [];

    // 📌 1️⃣ 여성 복식 팀 구성 (실력 균형)
    for (int i = 0; i < females.length/2; i++) {
      newFemaleTeams.add(Team(id: "여${i}", player1: females[i], player2: females[females.length - i -1],division: 1));
    }

    // 📌 2️⃣ 혼성 복식 팀 구성 (여성 먼저 배치 후 실력 균형 고려)
    //todo 수정필요
    // int maleIndex = 0;
    // for (var female in females) {
    //   if (maleIndex < males.length) {
    //     newMixedTeams.add(Team(id: "혼성${maleIndex}", members: [female, males[maleIndex]]));
    //     maleIndex++;
    //   }
    // }

    // 📌 3️⃣ 남성 복식 팀 구성 (남은 남성 참가자끼리 실력 균형 맞춤)
    for (int i = 0; i < males.length / 2; i++) {
      newMaleTeams.add(Team(id: "남${i}", player1: males[i], player2: males[males.length - i -1],division: 1));
    }

    setState(() {
      femaleTeams = newFemaleTeams;
      mixedTeams = newMixedTeams;
      maleTeams = newMaleTeams;
    });
  }


  Future<List<Player>> loadPlayersFromSharedPreferences(String key) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? playersJson = prefs.getStringList(key);

    if (playersJson == null) {
      print("📌 [$key] 저장된 데이터 없음.");
      return [];
    }

    List<Player> players = playersJson.map((json) => Player.fromJson(jsonDecode(json))).toList();
    print("📌 [$key] 불러오기 완료: $players");
    return players;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("팀 구성")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _generateTeams,
              child: Text("팀 자동 구성"),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // 가로 스크롤 적용
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTeamSection("여성 복식", femaleTeams),
                  // _buildTeamSection("혼성 복식", mixedTeams),
                  _buildTeamSection("남성 복식", maleTeams),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📌 드래그 앤 드롭 가능한 팀 목록 위젯
  Widget _buildTeamSection(String title, List<Team> teams) {
    return Container(
      width: 500, // 각 섹션의 너비
      margin: EdgeInsets.all(8.0),
      child: Card(
        color: Colors.grey[300], // 섹션 배경색
        child: Column(
          children: [
            ListTile(
              title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            teams.isEmpty
                ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("팀이 구성되지 않았습니다."),
            )
                : SizedBox(
                  height: 400,
                  child: DragAndDropLists(
                    children: makeDragAndDropList(teams),
                    onItemReorder: (oldItemIndex, oldListIndex, newItemIndex, newListIndex) {
                      setState(() {
                      var movedItem = teams[oldListIndex].toListPlayer().removeAt(oldItemIndex);
                      teams[newListIndex].toListPlayer().insert(newItemIndex, movedItem);
                      });
                    },
                    onListReorder: (oldListIndex, newListIndex) {
                      setState(() {
                        var movedList = teams.removeAt(oldListIndex);
                        teams.insert(newListIndex, movedList);
                      });
                    },
                    axis: Axis.horizontal, // 가로 정렬
                    listWidth: 300, // 리스트 너비 설정
                    listPadding: EdgeInsets.all(16), // 리스트 간격 조정
                  )
                ),
          ],
        ),
      ),
    );
  }

  //note DragAndDropList 만들기
  List<DragAndDropList> makeDragAndDropList(List<Team> teams) {
    return teams.map((team) {
      return DragAndDropList(
        header: Center(
          child: Text(
            "${team.id}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        children:
        // [
        //   DragAndDropItem(child: Text(team.members[0].name)), // 팀원 1
        //   DragAndDropItem(child: Text(team.members[1].name)), // 팀원 2
        // ],
        team.toListPlayer().map((members){
          return DragAndDropItem(child: Text(members.name));
        }).toList()
      );
    }).toList();
  }

}
