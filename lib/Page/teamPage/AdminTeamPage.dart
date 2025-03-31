import 'package:flutter/material.dart';
import '../../model/Player.dart';
import '../../model/Team.dart';
import 'TeamPageBase.dart';
import '../../services/firestore_service.dart';

class AdminTeamPage extends TeamPageBase {
  const AdminTeamPage({super.key}) : super(isAdmin: true);

  @override
  _AdminTeamPageState createState() => _AdminTeamPageState();
}

class _AdminTeamPageState extends TeamPageBaseState<AdminTeamPage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("운영자 - 팀 관리")),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildCategorySelector(),
              const SizedBox(height: 8, width: 12,),
              ElevatedButton(
                onPressed: _generateTeams,
                child: const Text("팀 자동 구성"),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _saveSelectedCategoryTeams,
                child: const Text("팀 구성 저장"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: buildSelectedCategoryView()),
        ],
      ),
    );
  }

  Future<void> _saveSelectedCategoryTeams() async {
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("카테고리를 선택해주세요"),duration: Duration(seconds: 1),),
      );
      return;
    }

    String collectionName;
    List<Team> targetTeams;

    switch (selectedCategory) {
      case "남성":
        collectionName = "남성 복식 팀";
        targetTeams = maleTeams;
        break;
      case "여성":
        collectionName = "여성 복식 팀";
        targetTeams = femaleTeams;
        break;
      case "혼성":
        collectionName = "혼성 복식 팀";
        targetTeams = mixedTeams;
        break;
      default:
        return;
    }

    await _firestoreService.saveTeams(targetTeams, collectionName);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("[$collectionName] 저장 완료"),duration: Duration(seconds: 1),),
    );
  }


  // 팀 자동 구성
  Future<void> _generateTeams() async {
    List<Player> males = await _firestoreService.loadPlayers("참가자", "남성", sortByRank: true);
    List<Player> females = await _firestoreService.loadPlayers("참가자", "여성", sortByRank: true);

    // 부 나누기 (기본 1부)
    int maleDivisions = 1;
    int femaleDivisions = 1;

    await _showDivisionDialog("남성 복식", males.length, (divCount) {
      maleDivisions = divCount;
    });

    await _showDivisionDialog("여성 복식", females.length, (divCount) {
      femaleDivisions = divCount;
    });

    _assignDivisions(males, maleDivisions);
    _assignDivisions(females, femaleDivisions);

    // 저장
    await _firestoreService.savePlayers(males, "참가자");
    await _firestoreService.savePlayers(females, "참가자");

    divisionCounts = {
      "남성": maleDivisions,
      "여성": femaleDivisions,
      "혼성": 1,
    };

    List<Team> newMaleTeams = _createTeams(males);
    List<Team> newFemaleTeams = _createTeams(females);
    List<Team> newMixedTeams = _createMixedTeams(males, females);

    setState(() {
      maleTeams = newMaleTeams;
      femaleTeams = newFemaleTeams;
      mixedTeams = newMixedTeams;
    });

    await _firestoreService.saveTeams(maleTeams, "남성 복식 팀");
    await _firestoreService.saveTeams(femaleTeams, "여성 복식 팀");
    await _firestoreService.saveTeams(mixedTeams, "혼성 복식 팀");
    await _firestoreService.saveDivision(divisionCounts, "부");
  }

  Future<void> _showDivisionDialog(String title, int playerCount, Function(int) onConfirmed) async {
    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$title (${playerCount}명)"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "몇 부로 나눌까요?"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {
              int div = int.tryParse(controller.text) ?? 1;
              Navigator.pop(context);
              onConfirmed(div);
            },
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  void _assignDivisions(List<Player> players, int divisionCount) {
    int perDivision = (players.length / divisionCount).ceil();

    for (int i = 0; i < players.length; i++) {
      players[i].division = (i ~/ perDivision) + 1;
    }
  }

  List<Team> _createTeams(List<Player> players) {
    Map<int, List<Player>> grouped = {};

    for (var p in players) {
      grouped.putIfAbsent(p.division, () => []).add(p);
    }

    List<Team> result = [];
    grouped.forEach((division, list) {
      for (int i = 0; i < list.length ~/ 2; i++) {
        result.add(Team(
          id: "$division-${i + 1}_${list[i].name}-${list[list.length - i - 1].name}",
          players: [list[i], list[list.length - i - 1]],
          division: division,
        ));
      }
    });

    return result;
  }

  List<Team> _createMixedTeams(List<Player> males, List<Player> females) {
    Map<int, List<Player>> maleGroups = {};
    Map<int, List<Player>> femaleGroups = {};

    for (var m in males) {
      maleGroups.putIfAbsent(m.division, () => []).add(m);
    }
    for (var f in females) {
      femaleGroups.putIfAbsent(f.division, () => []).add(f);
    }

    List<Team> result = [];

    maleGroups.forEach((division, maleList) {
      if (femaleGroups.containsKey(division)) {
        final femaleList = femaleGroups[division]!;
        final minLength = maleList.length < femaleList.length
            ? maleList.length
            : femaleList.length;

        for (int i = 0; i < minLength; i++) {
          result.add(Team(
            id: "혼성$division-${i + 1}",
            players: [femaleList[i], maleList[i]],
            division: division,
          ));
        }
      }
    });

    return result;
  }
}
