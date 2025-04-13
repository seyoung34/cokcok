import 'package:flutter/material.dart';
import '../../model/Match.dart';
import '../../model/Team.dart';
import '../../services/firestore_service.dart';

abstract class MatchTournamentBase extends StatefulWidget {
  final String tournamentId;
  final bool isAdmin;

  const MatchTournamentBase({
    super.key,
    required this.tournamentId,
    required this.isAdmin,
  });
}

abstract class MatchTournamentBaseState<T extends MatchTournamentBase> extends State<T> {
  final FirestoreService firestoreService = FirestoreService();

  List<String> divisions = [];           // ex: ["남성_1", "여성_1", "혼성_1"]
  String? selectedDivision;              // 현재 선택된 부

  @override
  void initState() {
    super.initState();
    _loadDivisions();
  }

  /// 🔽 Firestore에서 division 목록을 불러와 설정
  Future<void> _loadDivisions() async {
    final divisionMap = await firestoreService.loadDivision("부");

    final allDivs = <String>{};
    for (var gender in ['남성', '여성', '혼성']) {
      final count = divisionMap[gender] ?? 0;
      for (int i = 1; i <= count; i++) {
        allDivs.add("${gender}_$i");
      }
    }

    setState(() {
      divisions = allDivs.toList()..sort();
      selectedDivision = divisions.isNotEmpty ? divisions.first : null;
    });
  }

  /// 🔽 결승 및 3·4위 경기 자동 생성 (준결승이 끝났을 때만 실행 가능)
  Future<void> generateFinalAndThirdMatches(String gender, int division, List<Match> allMatches) async {
    final alreadyExists = await firestoreService.hasFinalMatches(widget.tournamentId, gender, division);
    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("결승/3·4위 경기가 이미 생성되어 있습니다.")),
      );
      return;
    }

    final semiFinals = allMatches.where((m) => m.group == "본선_준결승").toList();
    if (semiFinals.length != 2 || !semiFinals.every((m) => m.isCompleted)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("준결승이 모두 완료되어야 결승/3·4위 경기를 생성할 수 있습니다.")),
      );
      return;
    }

    final m1 = semiFinals[0];
    final m2 = semiFinals[1];

    final winner1 = m1.team1Score > m1.team2Score ? m1.team1 : m1.team2;
    final loser1 = m1.team1Score < m1.team2Score ? m1.team1 : m1.team2;
    final winner2 = m2.team1Score > m2.team2Score ? m2.team1 : m2.team2;
    final loser2 = m2.team1Score < m2.team2Score ? m2.team1 : m2.team2;

    final finalMatch = Match(
      id: "결승",
      team1: winner1,
      team2: winner2,
      division: division,
      group: "본선_결승",
    );

    final thirdMatch = Match(
      id: "3·4위전",
      team1: loser1,
      team2: loser2,
      division: division,
      group: "본선_3·4위",
    );

    await firestoreService.saveTournamentMatches(
      tournamentId: widget.tournamentId,
      gender: gender,
      division: division,
      matches: [finalMatch, thirdMatch],
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("결승 및 3·4위 경기가 생성되었습니다.")),
    );
  }

  /// 🔽 개별 경기 박스 UI (준결승/결승/3·4위)
  Widget buildMatchBox(Match? match, {Color? highlightColor}) {
    final team1 = match?.team1.id ?? "-";
    final team2 = match?.team2.id ?? "-";
    final score1 = match?.team1Score?.toString() ?? "";
    final score2 = match?.team2Score?.toString() ?? "";

    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlightColor ?? Colors.grey[200],
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text("$team1 ${score1.isNotEmpty ? "($score1)" : ""}"),
          const SizedBox(height: 8),
          Text("$team2 ${score2.isNotEmpty ? "($score2)" : ""}"),
        ],
      ),
    );
  }

  /// 🔽 본선 토너먼트 UI를 구성하는 함수 → 자식 클래스에서 구현
  Widget buildTournamentLayout(List<Match> matches);

  /// 🔽 전체 위젯 구성
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("본선 토너먼트")),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // 🔸 division 선택 (라디오 or ChoiceChip)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: divisions.map((div) {
              return ChoiceChip(
                label: Text(div),
                selected: selectedDivision == div,
                onSelected: (_) => setState(() => selectedDivision = div),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // 🔸 토너먼트 시각화 영역
          if (selectedDivision != null)
            Expanded(
              child: StreamBuilder<List<Match>>(
                stream: firestoreService.watchTournamentMatchesByDivision(selectedDivision!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final matches = snapshot.data!;
                  return buildTournamentLayout(matches);
                },
              ),
            ),

          // 🔸 승리 확정 버튼 (Admin만)
          if (widget.isAdmin && selectedDivision != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text("승리 확정"),
                onPressed: () async {
                  final gender = selectedDivision!.split("_")[0];
                  final div = int.tryParse(selectedDivision!.split("_")[1]) ?? 1;

                  final allMatches = await firestoreService.loadTournamentMatches(
                    tournamentId: widget.tournamentId,
                    gender: gender,
                    division: div,
                  );

                  await generateFinalAndThirdMatches(gender, div, allMatches);
                },
              ),
            ),
        ],
      ),
    );
  }
}
