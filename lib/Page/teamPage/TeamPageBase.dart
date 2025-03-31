import 'package:flutter/material.dart';
import '../../model/Team.dart';
import '../../model/Player.dart';
import '../../services/firestore_service.dart';

enum TeamCategory { male, female, mixed }

abstract class TeamPageBase extends StatefulWidget {
  final bool isAdmin;

  const TeamPageBase({super.key, required this.isAdmin});
}

abstract class TeamPageBaseState<T extends TeamPageBase> extends State<T> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Team> maleTeams = [];
  List<Team> femaleTeams = [];
  List<Team> mixedTeams = [];

  String? selectedCategory = "남성";
  Map<String, int> divisionCounts = {};

  @override
  void initState() {
    super.initState();
    _loadTeams();
    _loadDivisionCounts();
  }

  /// 팀 데이터 불러오기
  Future<void> _loadTeams() async {
    maleTeams = await _firestoreService.loadTeams("남성 복식 팀");
    femaleTeams = await _firestoreService.loadTeams("여성 복식 팀");
    mixedTeams = await _firestoreService.loadTeams("혼성 복식 팀");
    setState(() {});
  }

  /// 부 정보 불러오기
  Future<void> _loadDivisionCounts() async {
    divisionCounts = await _firestoreService.loadDivision("부");
    setState(() {});
  }

  /// 라디오 버튼 생성
  Widget buildCategorySelector() {
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

  Widget buildSelectedCategoryView() {
    if (selectedCategory == null) return const SizedBox();

    List<Team> selectedTeams = selectedCategory == "남성"
        ? maleTeams
        : selectedCategory == "여성"
        ? femaleTeams
        : mixedTeams;

    int divisionCount = divisionCounts[selectedCategory] ?? 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(divisionCount, (index) {
        List<Team> divisionTeams =
        selectedTeams.where((t) => t.division == index + 1).toList();

        return Expanded(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: EdgeInsets.all(8),
              color: Colors.grey.shade100,
              child: buildTeamSection(
                "${selectedCategory!} ${index + 1}부",
                divisionTeams,
                selectedTeams == mixedTeams
                    ? Colors.green.shade100
                    : selectedTeams == maleTeams
                    ? Colors.blue.shade200
                    : Colors.pink.shade200,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget buildTeamSection(String title, List<Team> teams, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        teams.isEmpty
            ? const Text("팀이 없습니다.")
            : buildTeamGridView(teams, color),
      ],
    );
  }

  ///팀 그리드 뷰 그리는 부분
  Widget buildTeamGridView(List<Team> teams, Color color) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: teams.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        Widget teamCard = Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${teams[index].id.split('_')[0]}팀",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: teams[index].players.map((player) {
                  return widget.isAdmin
                      ? buildDraggablePlayer(player, teams[index])
                      : buildReadOnlyPlayer(player);
                }).toList(),
              ),
            ],
          ),
        );

        // ✅ 운영자일 때만 DragTarget으로 감싸기
        if (widget.isAdmin) {
          return DragTarget<Player>(
            onWillAccept: (data) => true,
            onAccept: (player) {
              setState(() {
                _removePlayerFromAllTeams(player);
                teams[index].players.add(player);
              });
            },
            builder: (context, candidateData, rejectedData) {
              return teamCard;
            },
          );
        }

        return teamCard; // 사용자용은 그대로 반환
      },
    );
  }


  Widget buildReadOnlyPlayer(Player player) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: player.gender == "남성" ? Colors.blue.shade100 : Colors.pink.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(player.name, style: TextStyle(fontSize: 16),),
    );
  }

  Widget buildDraggablePlayer(Player player, Team team) {
    return Draggable<Player>(
      data: player,
      feedback: Material(
        child: Container(
          padding: const EdgeInsets.all(6),
          color: Colors.teal,
          child: Text(player.name, style: const TextStyle(color: Colors.white)),
        ),
      ),
      onDragStarted: () => setState(() => _removePlayerFromAllTeams(player)),
      onDraggableCanceled: (_, __) => setState(() => team.players.add(player)),
      child: buildReadOnlyPlayer(player),
    );
  }

  void _removePlayerFromAllTeams(Player player) {
    for (var team in [...maleTeams, ...femaleTeams, ...mixedTeams]) {
      team.players.removeWhere((p) => p.name == player.name);
    }
  }

  @override
  Widget build(BuildContext context); // 자식 클래스에서 구현
}
