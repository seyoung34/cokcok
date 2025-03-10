import 'package:flutter/material.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import '../model/team.dart';

class TeamManagementPage extends StatefulWidget {
  @override
  _TeamManagementPageState createState() => _TeamManagementPageState();
}

class _TeamManagementPageState extends State<TeamManagementPage> {
  List<Player> participants = [
    Player(id: "P001", name: "김재민", gender: "남", rank: "A"),
    Player(id: "P002", name: "이세영", gender: "남", rank: "C"),
    Player(id: "P003", name: "정영훈", gender: "남", rank: "B"),
    Player(id: "P004", name: "박민규", gender: "남", rank: "C"),
    Player(id: "P005", name: "정이지", gender: "여", rank: "C"),
    Player(id: "P006", name: "김하은", gender: "여", rank: "B"),
    Player(id: "P007", name: "이혜인", gender: "여", rank: "B"),
    Player(id: "P008", name: "김지우", gender: "여", rank: "C"),
    Player(id: "P009", name: "김재진", gender: "남", rank: "B"),
    Player(id: "P010", name: "홍윤기", gender: "남", rank: "A"),
  ]; // 참가자 데이터

  List<Team> maleTeams = []; // 남성 복식 팀
  List<Team> femaleTeams = []; // 여성 복식 팀
  List<Team> mixedTeams = []; // 혼성 복식 팀

  // 📌 실력 균형 기반 팀 구성
  void _generateTeams() {
    List<Player> males = participants.where((p) => p.gender == "남").toList();
    List<Player> females = participants.where((p) => p.gender == "여").toList();

    // 랭크를 숫자로 변환 후 정렬
    males.sort((a, b) => _convertRank(a.rank).compareTo(_convertRank(b.rank)));
    females.sort((a, b) => _convertRank(a.rank).compareTo(_convertRank(b.rank)));

    List<Team> newMaleTeams = [];
    List<Team> newFemaleTeams = [];
    List<Team> newMixedTeams = [];

    // 📌 1️⃣ 여성 복식 팀 구성 (실력 균형)
    for (int i = 0; i < females.length/2; i++) {
      newFemaleTeams.add(Team(id: "여${i}", members: [females[i], females[females.length -1 -i]]));
    }

    // 📌 2️⃣ 혼성 복식 팀 구성 (여성 먼저 배치 후 실력 균형 고려)
    //todo 수정필요
    int maleIndex = 0;
    for (var female in females) {
      if (maleIndex < males.length) {
        newMixedTeams.add(Team(id: "혼성${maleIndex}", members: [female, males[maleIndex]]));
        maleIndex++;
      }
    }

    // 📌 3️⃣ 남성 복식 팀 구성 (남은 남성 참가자끼리 실력 균형 맞춤)
    for (int i = 0; i < males.length / 2; i++) {
      newMaleTeams.add(Team(id: "남${i}", members: [males[i], males[males.length - i - 1]]));
    }

    setState(() {
      femaleTeams = newFemaleTeams;
      mixedTeams = newMixedTeams;
      maleTeams = newMaleTeams;
    });
  }

  // 📌 랭크(A~E)를 숫자로 변환하는 함수
  int _convertRank(String rank) {
    switch (rank) {
      case "A":
        return 1;
      case "B":
        return 2;
      case "C":
        return 3;
      case "D":
        return 4;
      case "E":
        return 5;
      default:
        return 999; // 잘못된 값 방지
    }
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
                  // _buildTeamSection("여성 복식", femaleTeams),
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
                      var movedItem = teams[oldListIndex].members.removeAt(oldItemIndex);
                      teams[newListIndex].members.insert(newItemIndex, movedItem);
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
        team.members.map((members){
          return DragAndDropItem(child: Text(members.name));
        }).toList()
      );
    }).toList();
  }

}
