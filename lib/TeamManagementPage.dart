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
            child: SingleChildScrollView( //굳이 가로 스크롤?
              scrollDirection: Axis.horizontal, // 가로 스크롤 적용
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTeamSection("남성 복식", maleTeams),
                  // _buildTeamSection("혼성 복식", mixedTeams),
                  _buildTeamSection("여성 복식", femaleTeams),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

    //todo division 입력 받아서 나누기

    List<Player> males = await loadPlayersFromSharedPreferences("남성 참가자");
    List<Player> females = await loadPlayersFromSharedPreferences("여성 참가자");

    // 순위에 따른 정렬
    males.sort((a, b) => a.rank.compareTo(b.rank));
    females.sort((a, b) => a.rank.compareTo(b.rank));

    List<Team> newMaleTeams = [];
    List<Team> newFemaleTeams = [];
    List<Team> newMixedTeams = [];

    // 남성 복식 팀 구성 (2명씩 팀 구성)
    for (int i = 0; i < males.length / 2; i++) {
      newMaleTeams.add(
        Team(
          id: "남 ${i + 1}조",
          players: [males[i], males[males.length - i - 1]],
          division: 1,
        ),
      );
    }

    // 여성 복식 팀 구성 (2명씩 팀 구성)
    for (int i = 0; i < females.length / 2; i++) {
      newFemaleTeams.add(
        Team(
          id: "여 ${i + 1}조",
          players: [females[i], females[females.length - i - 1]],
          division: 1,
        ),
      );
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


    setState(() {
      femaleTeams = newFemaleTeams;
      mixedTeams = newMixedTeams;
      maleTeams = newMaleTeams;
    });
  }


  //sharedPreference로 부터 Player 데이터 불러오기
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
            //     : SizedBox(   // 리스트 있으면
            //     height: 400,
            //     child: DragAndDropLists(
            //       children: makeDragAndDropLists(teams),
            //       onItemReorder: (oldItemIndex, oldListIndex, newItemIndex, newListIndex) {
            //         setState(() {
            //           var movedItem = teams[oldListIndex].players.removeAt(oldItemIndex);
            //           teams[newListIndex].players.insert(newItemIndex, movedItem);
            //           teams = List.from(teams); // UI 갱신
            //         });
            //         for (Team team in teams) {
            //           print("${team.id} | ${team.players.map((p) => p.name).join(', ')}");
            //         }
            //       },
            //       onListReorder: (oldListIndex, newListIndex) {
            //         setState(() {
            //           var movedList = teams.removeAt(oldListIndex);
            //           teams.insert(newListIndex, movedList);
            //         });
            //       },
            //       itemDragOnLongPress: true,
            //       axis: Axis.vertical, // 가로 정렬
            //       listWidth: 300, // 리스트 너비 설정
            //       listPadding: EdgeInsets.all(16), // 리스트 간격 조정
            //
            //     )
            // ),
            : buildDragAndDropGrid(teams)
          ],
        ),
      ),
    );
  }

  Widget buildDragAndDropGrid(List<Team> teams) {
    return GridView.builder(

      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2열 배치
        crossAxisSpacing: 10, // 열 간격
        mainAxisSpacing: 10, // 행 간격
        childAspectRatio: 2, // 가로/세로 비율 조정
      ),

      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // 부모 스크롤뷰와 충돌 방지
      itemCount: teams.length,

      itemBuilder: (context, index) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: Color(0xff1cb3a8),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.all(8),
          child: DragAndDropLists(// ✅ 반드시 DragAndDropLists로 감싸야 함
            itemDragOnLongPress: true,
            disableScrolling: true,
            children: [
              DragAndDropList(
                header: Center(
                  child: Text(
                    teams[index].id, // 팀 이름
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                children: teams[index].players.map((player) {
                  return DragAndDropItem(child: Text(player.name));
                }).toList(),
              ),
            ],
            onItemReorder: (oldItemIndex, oldListIndex, newItemIndex, newListIndex) {
              setState(() {
                var movedItem = teams[oldListIndex].players.removeAt(oldItemIndex);
                teams[newListIndex].players.insert(newItemIndex, movedItem);
                teams = List.from(teams); // UI 갱신
              });

              print("$oldItemIndex $oldListIndex $newItemIndex $newListIndex");
              for (Team team in teams) {
                print("${team.id} | ${team.players.map((p) => p.name).join(', ')}");
              }
              print(" ");

            },
            onListReorder: (oldListIndex, newListIndex) {
              setState(() {
                var movedList = teams.removeAt(oldListIndex);
                teams.insert(newListIndex, movedList);
              });
            },
          ),
        );
      },
    );
  }




}
