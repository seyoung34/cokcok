import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firestore_service.dart';
import '../../model/Player.dart';
import '/model/Team.dart';

class TeamManagementPage extends StatefulWidget {
  @override
  _TeamManagementPageState createState() => _TeamManagementPageState();
}

class _TeamManagementPageState extends State<TeamManagementPage> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Team> maleTeams = [];
  List<Team> femaleTeams = [];
  List<Team> mixedTeams = [];
  String? selectedCategory; // 🔹 선택된 팀 유형 (남성, 여성, 혼성)
  Map<String, int> divisionCounts = {}; // 🔹 각 팀 유형의 division 개수 저장

  @override
  void initState() {
    super.initState();
    _loadTeams();
    _loadDivision();
    // _loadState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("팀 구성")),
      body: Column(
        children: [
          _buildCategorySelector(), // 🔹 카테고리 선택 버튼 추가

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _generateTeams,
              child: Text("팀 자동 구성"),
            ),
          ),

          Expanded(child: _buildSelectedCategoryView()), // 🔹 선택된 카테고리만 표시
        ],
      ),
    );
  }



  // firestore에서 팀 데이터 받아오기
  Future<void> _loadTeams() async {
    maleTeams = await _firestoreService.loadTeams("남성 복식 팀");
    femaleTeams = await _firestoreService.loadTeams("여성 복식 팀");
    mixedTeams = await _firestoreService.loadTeams("혼성 복식 팀");
    setState(() {});
  }

  /// 📌 Firestore에 팀 데이터를 저장하는 함수
  Future<void> _saveTeams() async {
    await _firestoreService.saveTeams(maleTeams, "남성 복식 팀");
    await _firestoreService.saveTeams(femaleTeams, "여성 복식 팀");
    await _firestoreService.saveTeams(mixedTeams, "혼성 복식 팀");
    print("팀 정보 저장");
  }

  /// 📌 SharedPreferences에 현재 상태 저장
  // Future<void> _saveState() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //
  //   // ✅ 현재 division 설정 저장
  //   await prefs.setInt("남성_division", divisionCounts["남성"] ?? 1);
  //   await prefs.setInt("여성_division", divisionCounts["여성"] ?? 1);
  //   await prefs.setInt("혼성_division", divisionCounts["혼성"] ?? 1);
  //
  //   // ✅ 현재 선택된 카테고리 저장
  //   await prefs.setString("selectedCategory", selectedCategory ?? "");
  // }

  /// 📌 SharedPreferences에서 저장된 상태 불러오기
  // Future<void> _loadState() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //
  //   setState(() {
  //     divisionCounts["남성"] = prefs.getInt("남성_division") ?? 1;
  //     divisionCounts["여성"] = prefs.getInt("여성_division") ?? 1;
  //     divisionCounts["혼성"] = prefs.getInt("혼성_division") ?? 1;
  //     selectedCategory = prefs.getString("selectedCategory")?.isNotEmpty ?? false
  //         ? prefs.getString("selectedCategory")
  //         : null;
  //   });
  // }

  //부 정보 불러오기
  Future<void> _loadDivision() async{
    divisionCounts = await _firestoreService.loadDivision("부");
  }

  // 부 정보 저장하기
  void _saveDivision() async{
    _firestoreService.saveDivision(divisionCounts, "부");
  }


  // 📌 다이얼로그를 띄워 division을 입력받음
  Future<void> _showDivisionDialog(String title, int playerCount, Function(int) onConfirmed) async {
    TextEditingController divisionController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("$title 참가자 수: $playerCount명"),
          content: TextField(
            controller: divisionController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "몇 부로 나누시겠습니까?"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("취소"),
            ),
            TextButton(
              onPressed: () {
                int divisionCount = int.tryParse(divisionController.text) ?? 1;
                Navigator.pop(context);
                onConfirmed(divisionCount);
              },
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }

  // 📌 실력 균형 기반 팀 자동 구성
  Future<void> _generateTeams() async {
    //note 우선 균등 배분하고 선택에 따라 1부에 몇 명, 2부에 몇 명 넣을지 고려


    List<Player> males = await _firestoreService.loadPlayers("참가자","남성",sortByRank: true);
    List<Player> females = await _firestoreService.loadPlayers("참가자","여성",sortByRank: true);

    print("_generateTeams ${males.map((e) => {e.name, e.rank})}");


    // ✅ 사용자 입력을 받아 몇 부로 나눌지 결정
    await _showDivisionDialog("남성 복식", males.length, (int maleDivisions) async {
      await _showDivisionDialog("여성 복식", females.length, (int femaleDivisions) async {

        // ✅ 각 Player 객체의 division 설정
        _assignDivisions(males, maleDivisions);
        _assignDivisions(females, femaleDivisions);

        //부 정보 저장
        divisionCounts["남성"] = maleDivisions;
        divisionCounts["여성"] = femaleDivisions;
        divisionCounts["혼성"] = 1;
        _saveDivision();



        // ✅ 팀 생성
        List<Team> newMaleTeams = _createTeams(males);
        List<Team> newFemaleTeams = _createTeams(females);
        List<Team> newMixedTeams = _createMixedTeams(males, females);

        print("newMaleTeams : ${newMaleTeams.map.toString()}");

        setState(() {
          maleTeams = newMaleTeams;
          femaleTeams = newFemaleTeams;
          mixedTeams = newMixedTeams;
          divisionCounts = {
            "남성": maleDivisions,
            "여성": femaleDivisions,
            "혼성": 1 // 혼성은 따로 division을 받지 않음
          };
        });

        await _saveTeams(); // ✅ 자동 저장
        // await _saveState();
      });
    });
  }

  // 📌 Player 객체에 division을 설정하는 함수
  void _assignDivisions(List<Player> players, int divisionCount) {
    int playersPerDivision = (players.length / divisionCount).ceil(); //올림처리


    for (int i = 0; i < players.length; i++) {
      players[i].division = (i ~/ playersPerDivision) + 1;  // note 정수 나눗셈 연산자
    }

    // todo save Player divison
    _firestoreService.savePlayers(players, "참가자");
  }


  // 📌 상단 카테고리 선택 라디오 버튼
  Widget _buildCategorySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ["남성", "여성", "혼성"].map((category) {
        return Row(
          children: [
            Radio<String?>(
              value: category,
              groupValue: selectedCategory,
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                  // _saveState();
                });
              },
              toggleable: true,
            ),
            Text(category),
          ],
        );
      }).toList(),
    );
  }

  // 📌 선택된 카테고리에 따라 팀 배치
  //메인 ui에 들어갈 위젯
  Widget _buildSelectedCategoryView() {
    if (selectedCategory == null) return Container(); // 아무것도 선택되지 않으면 빈 화면

    List<Team> selectedTeams = selectedCategory == "남성"
        ? maleTeams
        : selectedCategory == "여성"
        ? femaleTeams
        : mixedTeams;

    int divisionCount = divisionCounts[selectedCategory] ?? 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 20,  //그리드뷰간 거리
      //note 잘 모르겠당
      children: List.generate(divisionCount, (index) {
        List<Team> divisionTeams = selectedTeams.where((team) => team.division == index + 1).toList();
        return Expanded(
          child: SingleChildScrollView(
            child: Container(
                padding: EdgeInsets.all(8),
                color: Colors.grey.shade200,
                child: _buildTeamSection("${selectedCategory!} ${index + 1}부",divisionTeams,
                    selectedTeams == mixedTeams ? Colors.green.shade100 : selectedTeams == maleTeams ? Colors.blue.shade200 : Colors.pink.shade200)
            )
          )
        );
      }),
    );
  }

  // 📌 Player의 division 속성을 기반으로 부별로 팀 생성
  List<Team> _createTeams(List<Player> players) {
    List<Team> teams = [];

    // ✅ division 기준으로 그룹화
    Map<int, List<Player>> groupedPlayers = {};
    for (var player in players) {
      groupedPlayers.putIfAbsent(player.division, () => []).add(player);
    }

    // ✅ 각 division 내에서 2명씩 팀 구성
    groupedPlayers.forEach((division, playerList) {
      for (int i = 0; i < playerList.length ~/ 2; i++) {
        teams.add(Team(
          id: "${i + 1}_${playerList[i].name}-${playerList[playerList.length-i-1].name} ",
          players: [playerList[i], playerList[playerList.length - i - 1]],
          division: division,
        ));
      }
    });

    return teams;
  }

  // 📌 혼성 복식 팀 구성 (division 기준으로 남녀 매칭)
  // note 랜덤으로 만들자.
  List<Team> _createMixedTeams(List<Player> males, List<Player> females) {
    List<Team> mixedTeams = [];

    // ✅ division 기준으로 그룹화
    Map<int, List<Player>> maleDivisions = {};
    Map<int, List<Player>> femaleDivisions = {};

    for (var male in males) {
      maleDivisions.putIfAbsent(male.division, () => []).add(male);
    }
    for (var female in females) {
      femaleDivisions.putIfAbsent(female.division, () => []).add(female);
    }

    // ✅ 같은 division끼리 혼성 팀 매칭
    maleDivisions.forEach((division, maleList) {
      if (femaleDivisions.containsKey(division)) {
        List<Player> femaleList = femaleDivisions[division]!;
        int minLength = maleList.length < femaleList.length ? maleList.length : femaleList.length;

        for (int i = 0; i < minLength; i++) {
          mixedTeams.add(Team(
            id: "혼성$division-${i + 1}",
            players: [femaleList[i], maleList[i]],
            division: division,
          ));
        }
      }
    });

    return mixedTeams;
  }

  // 📌 GridView 형태의 팀 섹션을 생성
  // 부 단위
  Widget _buildTeamSection(String title, List<Team> teams, Color color) {
    return
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          teams.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("팀이 없습니다."),
          )
              : _buildDraggableGridView(teams, color),  //데이터 있을 시 진짜로 그리드뷰 그리는 함수
        ],
      );
  }

  // 📌 Drag & Drop이 가능한 팀 목록 (GridView 형식)
  // note 그리드 뷰 그리는 부분
  Widget _buildDraggableGridView(List<Team> teams, Color color) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250, // 한 열의 최대 크기 지정 (250px 이상이면 다음 행으로)
        crossAxisSpacing: 16, // 열 간 간격
        mainAxisSpacing: 16, // 행 간 간격
        childAspectRatio: 1.5, // 너비와 높이 비율
      ),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        return DragTarget<Player>(
          onWillAccept: (data) => true,
          onAccept: (player) {
            setState(() {
              _removePlayerFromTeams(player);
              teams[index].players.add(player);
              _saveTeams();
            });
          },
          builder: (context, candidateData, rejectedData) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: constraints.maxHeight, // ✅ 부모 컨테이너의 높이를 고정
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.all(5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // ✅ 전체적으로 중앙 정렬
                    children: [
                      Text(
                        teams[index].id.split("_")[0]+"팀",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        height: constraints.maxHeight * 0.5, // ✅ Wrap이 차지할 공간 확보
                        child: Center(
                          child: Wrap(
                            alignment: WrapAlignment.center, // ✅ Wrap 내부 아이템 중앙 정렬
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 10,
                            spacing: 10,
                            children: teams[index].players.map((player) {
                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  double itemWidth = constraints.maxWidth * 0.4;
                                  itemWidth = itemWidth < 40 ? 40 : itemWidth; // ✅ 최소 너비 제한

                                  return Draggable<Player>(
                                    data: player,
                                    feedback: Material(
                                      child: Container(
                                        padding: EdgeInsets.all(8),
                                        color: Colors.teal,
                                        child: Text(player.name, style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                    onDragStarted: () => setState(() => _removePlayerFromTeams(player)),
                                    onDraggableCanceled: (_, __) => setState(() => teams[index].players.add(player)),

                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 40,
                                      width: itemWidth,
                                      padding: EdgeInsets.all(8),
                                      color: player.gender=="남성" ? Colors.blue.shade100 : Colors.pink.shade100,
                                      child: Center(
                                        child: Text(
                                          player.name,
                                          style: TextStyle(fontSize: itemWidth * 0.2),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }


  void _removePlayerFromTeams(Player player) {
    setState(() {
      for (var team in [...maleTeams, ...femaleTeams, ...mixedTeams]) {
        team.players.removeWhere((p) => p.name == player.name);
      }
    });
  }

}
