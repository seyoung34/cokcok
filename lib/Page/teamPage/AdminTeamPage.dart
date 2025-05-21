import 'dart:math';

import 'package:flutter/material.dart';
import '../../model/Player.dart';
import '../../model/Team.dart';
import 'TeamPageBase.dart';
import '../../services/firestore_service.dart';

class AdminTeamPage extends TeamPageBase {
  final VoidCallback onUserRequest;
  const AdminTeamPage({super.key,required this.onUserRequest}) : super(isAdmin: true);

  @override
  _AdminTeamPageState createState() => _AdminTeamPageState();
}

class _AdminTeamPageState extends TeamPageBaseState<AdminTeamPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController verticalController = ScrollController();

  //note build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Stack(
            children: [
              // ⬅ 버전 정보 (좌측 하단)
              Positioned(
                left: 12,
                bottom: 8,
                child: Text(
                  VERSION,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              // 🏷 중앙 타이틀
              Center(
                child: Text(
                  "사용자 - 팀 확인",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              // 🔐 우측 아이콘
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  icon: const Icon(Icons.lock),
                  onPressed: widget.onUserRequest,
                ),
              ),
            ],
          ),
        ),
      ),
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
        for (int i = 0; i < maleTeams.length; i++) {
          String idfirst = maleTeams[i].id.split("_").first;
          String idLast = maleTeams[i].players[0].name + "-" + maleTeams[i].players[1].name;
          maleTeams[i].id = idfirst + "_" + idLast;
        }
        targetTeams = maleTeams;
        break;
      case "여성":
        collectionName = "여성 복식 팀";
        for (int i = 0; i < femaleTeams.length; i++) {
          String idfirst = femaleTeams[i].id.split("_").first;
          String idLast = femaleTeams[i].players[0].name + "-" + femaleTeams[i].players[1].name;
          femaleTeams[i].id = idfirst + "_" + idLast;
        }
        targetTeams = femaleTeams;
        break;
      case "혼성":
        collectionName = "혼성 복식 팀";
        for (int i = 0; i < mixedTeams.length; i++) {
          String idfirst = mixedTeams[i].id.split("_").first;
          String idLast = mixedTeams[i].players[0].name + "-" + mixedTeams[i].players[1].name;
          mixedTeams[i].id = idfirst + "_" + idLast;
        }
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


  /// 팀 자동 구성
  Future<void> _generateTeams() async {
    List<Player> males = await _firestoreService.loadPlayers("참가자", "남성", sortByRank: true);
    List<Player> females = await _firestoreService.loadPlayers("참가자", "여성", sortByRank: true);
    List<Player> onlyMixed = await _firestoreService.loadPlayers("참가자", "혼성", sortByRank: true);

    // 부 나누기 (기본 1부)
    int maleDivisions = 1;
    int femaleDivisions = 1;

    // await _showDivisionDialog("남성 복식", males.length, (divCount) {
    //   maleDivisions = divCount;
    // });
    //
    // await _showDivisionDialog("여성 복식", females.length, (divCount) {
    //   femaleDivisions = divCount;
    // });

    List<int>? maleResult = await showDivisionInputDialog(context: context, title: "남성 복식", totalPlayers: males.length);
    List<int>? femaleResult = await showDivisionInputDialog(context: context, title: "여성 복식", totalPlayers: females.length);

    if(maleResult != null  && femaleResult != null){
      _assignDivisions(males, maleResult);
      _assignDivisions(females, femaleResult);
    }


    // 저장
    await _firestoreService.savePlayers(males, "참가자");
    await _firestoreService.savePlayers(females, "참가자");

    divisionCounts = {
      "남성": maleResult?.length ?? 1,
      "여성": femaleResult?.length ?? 1,
      "혼성": 1,
    };

    List<Team> newMaleTeams = _createTeams(males);
    List<Team> newFemaleTeams = _createTeams(females);
    List<Team> newMixedTeams = _createMixedTeams(males, females, onlyMixed);

    setState(() {
      maleTeams = newMaleTeams;
      femaleTeams = newFemaleTeams;
      mixedTeams = newMixedTeams;
    });

    await _firestoreService.saveTeams(maleTeams, "남성 복식 팀");
    await _firestoreService.saveTeams(femaleTeams, "여성 복식 팀");
    await _firestoreService.saveTeams(mixedTeams, "혼성 복식 팀"); ///혼성 복식 팀
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

  void _assignDivisions(List<Player> players, List<int> divisionSizes) {
    int index = 0;
    for (int div = 0; div < divisionSizes.length; div++) {
      for (int i = 0; i < divisionSizes[div]; i++) {
        if (index < players.length) {
          players[index++].division = div + 1;
        }
      }
    }
  }


  //note 추가
  Future<List<int>?> showDivisionInputDialog({
    required BuildContext context,
    required String title,
    required int totalPlayers,
  }) {
    int selectedDivision = 2; // 기본값 2부
    List<TextEditingController> controllers = [];

    void updateControllers(int count) {
      controllers = List.generate(count, (_) => TextEditingController(),);
    }

    updateControllers(selectedDivision);

    return showDialog<List<int>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text("$title ($totalPlayers명)"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    int division = index + 1;
                    bool isSelected = selectedDivision == division;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          isSelected ? Colors.blue : Colors.grey[300],
                          foregroundColor:
                          isSelected ? Colors.white : Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            selectedDivision = division;
                            updateControllers(division);
                          });
                        },
                        child: Text("$division부"),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                ...List.generate(selectedDivision, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextField(
                      controller: controllers[index],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "${index + 1}부 인원 수",
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("취소"),
              ),
              TextButton(
                onPressed: () {
                  List<int> sizes = controllers
                      .map((c) => int.tryParse(c.text) ?? 0)
                      .toList();
                  int sum = sizes.fold(0, (a, b) => a + b);
                  if (sum != totalPlayers) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                        Text("입력한 인원 수의 총합이 $totalPlayers명과 일치하지 않습니다."),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, sizes);
                },
                child: const Text("확인"),
              ),
            ],
          );
        });
      },
    );
  }




  ///
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

  /*List<Team> _createMixedTeams(List<Player> males, List<Player> females) {
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
            id: "$division-${i + 1}_${femaleList[i].name}-${maleList[maleList.length - i - 1].name}",
            players: [femaleList[i], maleList[i]],
            division: division,
          ));
        }
      }
    });

    return result;
  }*/


  List<Team> _createMixedTeams(List<Player> males, List<Player> females, List<Player> onlyMixed) {
    final mixedMales = males.where((p) => p.isMixed).toList();
    final mixedFemales = females.where((p) => p.isMixed).toList();
    final addMixed = onlyMixed.where((p) => p.isMixed).toList();

    List<Team> result = [];

    // ⛳ 남녀 짝지어 팀 구성
    final pairCount = min(mixedMales.length, mixedFemales.length);
    for (int i = 0; i < pairCount; i++) {
      result.add(
        Team(
          id: "혼성-${i + 1}_${mixedMales[i].name}-${mixedFemales[i].name}",
          players: [mixedMales[i],mixedFemales[i]],
          division: 1,
        ),
      );
    }

    // ⛳ 혼성만 참가하는 사람들 2명씩 팀 구성
    final mixedTeamStartIndex = result.length + 1;
    for (int i = 0; i + 1 < addMixed.length; i += 2) {
      result.add(
        Team(
          id: "혼성-${mixedTeamStartIndex + (i ~/ 2)}_${addMixed[i].name}-${addMixed[i + 1].name}",
          players: [addMixed[i], addMixed[i + 1]],
          division: 1,
        ),
      );
    }

    print("혼성 팀 수: ${result.length}");
    return result;
  }



}
