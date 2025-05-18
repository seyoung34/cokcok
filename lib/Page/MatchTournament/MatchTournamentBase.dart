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
  final ScrollController verticalController = ScrollController();
  final ScrollController horizontalController = ScrollController();

  List<String> divisions = [];       // 예: ["남성_1", "여성_2"]
  String? selectedDivision;
  List<Match> finalMatches = [];

  @override
  void initState() {
    super.initState();
    _loadDivisions();
  }

  /// 🔽 모든 division 불러오기 (남성/여성/혼성 부 각각)
  Future<void> _loadDivisions() async {
    final divisionMap = await firestoreService.loadDivision("부");
    final List<String> result = [];

    for (final gender in ['남성', '여성', '혼성']) {
      final count = divisionMap[gender] ?? 0;
      for (int i = 1; i <= count; i++) {
        result.add("$gender\_$i");
      }
    }

    setState(() {
      divisions = result;
      selectedDivision = result.isNotEmpty ? result.first : null;
    });
  }

  /// ✅ 본선 경기(준결승) 생성 버튼 누르면 실행
  Future<void> generateSemiFinals() async {
    if (selectedDivision == null) return;

    final gender = selectedDivision!.split("_")[0];
    final division = int.tryParse(selectedDivision!.split("_")[1]) ?? 1;

    final exists = await firestoreService.hasFinalMatches(widget.tournamentId, gender, division);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이미 본선 경기가 존재합니다.")),
      );
      return;
    }

    final matchMap = await firestoreService.loadMatches();

    final groupAKey = "${gender}_${division}_A";
    final groupBKey = "${gender}_${division}_B";
    final singleKey = "${gender}_${division}";

    final aMatches = matchMap[groupAKey] ?? [];
    final bMatches = matchMap[groupBKey] ?? [];
    final singleMatches = matchMap[singleKey] ?? [];

    // ✅ 케이스 1: A/B 조가 존재하는 경우
    if (aMatches.isNotEmpty && bMatches.isNotEmpty) {
      if (!aMatches.every((m) => m.isCompleted) || !bMatches.every((m) => m.isCompleted)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("A/B 조 경기가 모두 완료되어야 합니다.")),
        );
        return;
      }

      final aTeams = getUniqueTeams(aMatches);
      final bTeams = getUniqueTeams(bMatches);
      if (aTeams.length < 2 || bTeams.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("A/B 조에 각각 2팀 이상이 있어야 합니다.")),
        );
        return;
      }

      final aStats = calculateStats(aMatches, aTeams);
      final bStats = calculateStats(bMatches, bTeams);
      final aSorted = [...aTeams]..sort((a, b) => aStats[a.id]!['rank'].compareTo(aStats[b.id]!['rank']));
      final bSorted = [...bTeams]..sort((a, b) => bStats[a.id]!['rank'].compareTo(bStats[b.id]!['rank']));

      final semi1 = Match(
        id: "${aSorted[0].id} VS ${bSorted[1].id}",
        team1: aSorted[0],
        team2: bSorted[1],
        division: division,
        group: "본선_준결승",
      );

      final semi2 = Match(
        id: "${bSorted[0].id} VS ${aSorted[1].id}",
        team1: bSorted[0],
        team2: aSorted[1],
        division: division,
        group: "본선_준결승",
      );

      await firestoreService.saveTournamentMatches(
        tournamentId: widget.tournamentId,
        gender: gender,
        division: division,
        matches: [semi1, semi2],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("본선(준결승) 경기가 생성되었습니다.")),
      );
      return;
    }

    // ✅ 케이스 2: 단일 조인 경우
    if (singleMatches.isEmpty || !singleMatches.every((m) => m.isCompleted)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("단일 조 경기가 없거나 완료되지 않았습니다.")),
      );
      return;
    }

    final teams = getUniqueTeams(singleMatches);
    if (teams.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("단일 조에서는 최소 4팀 이상이 필요합니다.")),
      );
      return;
    }

    final stats = calculateStats(singleMatches, teams);
    final sorted = [...teams]..sort((a, b) => stats[a.id]!['rank'].compareTo(stats[b.id]!['rank']));

    final semi1 = Match(
      id: "${sorted[0].id} VS ${sorted[3].id}",
      team1: sorted[0],
      team2: sorted[3],
      division: division,
      group: "본선_준결승",
    );

    final semi2 = Match(
      id: "${sorted[1].id} VS ${sorted[2].id}",
      team1: sorted[1],
      team2: sorted[2],
      division: division,
      group: "본선_준결승",
    );

    await firestoreService.saveTournamentMatches(
      tournamentId: widget.tournamentId,
      gender: gender,
      division: division,
      matches: [semi1, semi2],
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("단일 조 기반 본선(준결승) 경기가 생성되었습니다.")),
    );
  }

  ///결승 3.4위전 생성할 때 라인 그리는 함수
  void paintLine();

  ///결승 3.4위전 생성
  Future<void> generateFinalAndThirdMatches(String gender, int division, List<Match> allMatches) async {
    final alreadyExists = allMatches.any((m) =>
    m.group == "본선_결승" || m.group == "본선_3·4위");

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("결승 또는 3·4위전이 이미 생성되어 있습니다.")),
      );
      return;
    }

    final semiFinals = allMatches.where((m) => m.group == "본선_준결승").toList();

    if (semiFinals.length != 2 || !semiFinals.every((m) => m.isCompleted)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("준결승 경기가 모두 완료되어야 합니다.")),
      );
      return;
    }

    final m1 = semiFinals[0];
    final m2 = semiFinals[1];

    final winner1 = m1.team1Score > m1.team2Score ? m1.team1 : m1.team2;
    final loser1  = m1.team1Score < m1.team2Score ? m1.team1 : m1.team2;
    final winner2 = m2.team1Score > m2.team2Score ? m2.team1 : m2.team2;
    final loser2  = m2.team1Score < m2.team2Score ? m2.team1 : m2.team2;

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

    paintLine();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("결승 및 3·4위 경기가 생성되었습니다.")),
    );
  }


  //note buildMatchBox
  /// ✅ 본선 매치 박스 UI (준결승/결승/3·4위 포함)
  Widget buildMatchBox(Match? match, String title, {Color? highlightColor}) {
    final team1 = match?.team1.id ?? "-";
    final team2 = match?.team2.id ?? "-";
    final score1 = match?.team1Score?.toString() ?? "";
    final score2 = match?.team2Score?.toString() ?? "";


    bool isTeam1Winner = match?.winnerTeamId == match?.team1.id;
    bool isTeam2Winner = match?.winnerTeamId == match?.team2.id;

    if(match == null){
      isTeam1Winner = false;
      isTeam2Winner = false;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isMobile = screenWidth < 600;
        final boxWidth = isMobile ? screenWidth * 0.3 : 220.0;
        final fontSize = isMobile ? 10.0 : 14.0;
        final boxHeight = isMobile ? screenHeight * 0.06: 50.0;

        Widget buildTeamBox(String name, String score, bool isWinner) {
          print("isWinner : $isWinner");
          return Stack(
            children: [
              Container(
                alignment: Alignment.center,
                width: double.infinity,
                height: boxHeight,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$name ${score.isNotEmpty ? "($score)" : ""}",
                  style: TextStyle(
                    fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                    fontSize: fontSize,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (isWinner)
                Positioned(
                  right: 3,
                  top: boxHeight * 0.25, // 위치도 boxHeight에 따라 조정
                  child: Icon(Icons.emoji_events, size: boxHeight * 0.5, color: Colors.amber),
                ),
            ],
          );
        }

        return GestureDetector(
          onTap: widget.isAdmin && match != null && match.id.isNotEmpty
              ? () => _showScoreDialog(match!)
              : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 🟫 본체 박스
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: boxWidth,
                height: screenHeight * 0.2,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: highlightColor ?? Colors.grey[100],
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    buildTeamBox(team1, score1, isTeam1Winner),
                    const SizedBox(height: 12),
                    buildTeamBox(team2, score2, isTeam2Winner),
                  ],
                ),
              ),

              // 🏷 타이틀 라벨
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 10 : 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }





  /// 본선 점수 입력 다이얼로그
  void _showScoreDialog(Match match) {
    final team1Controller = TextEditingController(text: match.team1Score?.toString() == "0" ? "" : match.team1Score?.toString());
    final team2Controller = TextEditingController(text: match.team2Score?.toString() == "0" ? "" : match.team2Score?.toString());
    print("base team1Controller : ${team1Controller}");


    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${match.team1.id} vs ${match.team2.id}"),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: team1Controller,
                decoration: InputDecoration(labelText: match.team1.id),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: team2Controller,
                decoration: InputDecoration(labelText: match.team2.id),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () async {
              final s1 = int.tryParse(team1Controller.text);
              final s2 = int.tryParse(team2Controller.text);

              if (s1 != null && s2 != null) {
                match.team1Score = s1;
                match.team2Score = s2;
                match.isCompleted = true;

                // ✅ 승자 설정 (무승부 없음 가정)
                match.winnerTeamId = s1 > s2 ? match.team1.id : match.team2.id;

                final gender = selectedDivision!.split("_")[0];
                final div = int.tryParse(selectedDivision!.split("_")[1]) ?? 1;

                await firestoreService.updateTournamentMatch(
                  tournamentId: widget.tournamentId,
                  gender: gender,
                  division: div,
                  match: match,
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("점수가 저장되었습니다.")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("유효한 점수를 입력해주세요.")),
                );
              }
            },
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }

  Widget buildFinalRanking(List<Match> matches) {
    // 결승 및 3·4위전 존재 여부 확인
    final finalMatch = matches.firstWhere(
          (m) => m.group == "본선_결승",
      orElse: () => Match.empty(),
    );
    final thirdMatch = matches.firstWhere(
          (m) => m.group == "본선_3·4위",
      orElse: () => Match.empty(),
    );

    // 둘 다 존재하고 완료되었는지 확인
    if (!finalMatch.isCompleted || !thirdMatch.isCompleted) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "🏁 본선 경기가 아직 완료되지 않았습니다.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // 점수가 null이면 비교 불가
    if (finalMatch.team1Score == null || finalMatch.team2Score == null ||
        thirdMatch.team1Score == null || thirdMatch.team2Score == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "❗ 점수가 입력되지 않은 경기가 있어 순위를 계산할 수 없습니다.",
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    // 1~4위 계산
    final first = finalMatch.team1Score! > finalMatch.team2Score!
        ? finalMatch.team1
        : finalMatch.team2;
    final second = finalMatch.team1Score! < finalMatch.team2Score!
        ? finalMatch.team1
        : finalMatch.team2;
    final third = thirdMatch.team1Score! > thirdMatch.team2Score!
        ? thirdMatch.team1
        : thirdMatch.team2;
    final fourth = thirdMatch.team1Score! < thirdMatch.team2Score!
        ? thirdMatch.team1
        : thirdMatch.team2;

    final rankings = [
      {'rank': 1, 'team': first},
      {'rank': 2, 'team': second},
      {'rank': 3, 'team': third},
      {'rank': 4, 'team': fourth},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          "🏆 본선 최종 순위",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...rankings.map((entry) {
          final team = entry['team'] as Team;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Text("${entry['rank']}위", style: const TextStyle(fontSize: 16)),
              title: Text(team.id, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        }),
      ],
    );
  }

  

  //note ✅ 토너먼트 시각화 구현은 자식 클래스에서 구현
  Widget buildTournamentLayout(List<Match> matches);


  /// ✅ 공통 유틸
  List<Team> getUniqueTeams(List<Match> matches) {
    final map = <String, Team>{};
    for (var m in matches) {
      map[m.team1.id] = m.team1;
      map[m.team2.id] = m.team2;
    }
    return map.values.toList();
  }

  Map<String, Map<String, dynamic>> calculateStats(List<Match> matches, List<Team> teams) {
    final stats = <String, Map<String, dynamic>>{};
    for (var team in teams) {
      stats[team.id] = {'wins': 0, 'diff': 0, 'team': team};
    }

    for (var match in matches) {
      if (!match.isCompleted) continue;
      final t1 = match.team1.id, t2 = match.team2.id;
      final s1 = match.team1Score, s2 = match.team2Score;

      if (s1 > s2)
        stats[t1]!['wins'] += 1;
      else
        stats[t2]!['wins'] += 1;

      stats[t1]!['diff'] += s1 - s2;
      stats[t2]!['diff'] += s2 - s1;
    }

    final sorted = [...stats.values]..sort((a, b) {
      int w = (b['wins'] as int).compareTo(a['wins'] as int);
      return w != 0 ? w : (b['diff'] as int).compareTo(a['diff'] as int);
    });

    for (int i = 0; i < sorted.length; i++) {
      final id = (sorted[i]['team'] as Team).id;
      stats[id]!['rank'] = i + 1;
    }

    return stats;
  }

  //note build
  /// ✅ 전체 본선 페이지 UI 구성
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("본선 토너먼트")),

      // 📌 본문 영역
      body: Column(
        children: [
          const SizedBox(height: 8),

          // 🔹 부 선택
          SingleChildScrollView(
            controller: horizontalController,
            child: Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.center,
              children: divisions.map((div) {
                return ChoiceChip(
                  label: Text(div),
                  selected: selectedDivision == div,
                  onSelected: (_) => setState(() => selectedDivision = div),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),
          Container(color: Colors.grey.shade400,height: 2,),

          // 🔹 본선 경기 영역
          if (selectedDivision != null)
            Expanded(
              child: StreamBuilder<List<Match>>(
                stream: firestoreService.watchTournamentMatchesByDivision(selectedDivision!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  finalMatches = snapshot.data!;

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                    controller: verticalController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🟨 본선 토너먼트 시각화
                        SizedBox(
                          // width: 600,
                          height: 460,
                          child: buildTournamentLayout(finalMatches),
                        ),

                        const SizedBox(width: 24),

                        // 🟩 순위표
                        SizedBox(
                          // width: 300,
                          child: buildFinalRanking(finalMatches),
                        ),

                        SizedBox(
                          height: 200,
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),

      // 🔹 Floating 버튼 (Admin 전용)
      floatingActionButton: widget.isAdmin && selectedDivision != null
          ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(onPressed: paintLine,label: const Text("그리기"),),
          
          const SizedBox(height: 12),
          
          FloatingActionButton.extended(
            heroTag: "generate_semi",
            onPressed: generateSemiFinals,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text("본선 생성"),
          ),

          const SizedBox(height: 12),

          FloatingActionButton.extended(
            heroTag: "generate_final",
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
            icon: const Icon(Icons.emoji_events),
            label: const Text("결승 / 3·4위 생성"),
          ),

          const SizedBox(height: 12),

          FloatingActionButton.extended(
              heroTag: "delete_tounament",
              onPressed: () async{
                firestoreService.deleteAllTournamentMatches();
              },
            label: const Text("토너먼트 정보 삭제"),
          )
        ],
      )
          : null,
    );
  }

}

class BracketLinePainter extends CustomPainter {

  final Match semi1;
  final Match semi2;

  BracketLinePainter({required this.semi1, required this.semi2});

  @override
  void paint(Canvas canvas, Size size) {
    // 선 스타일 정의
    final winnerPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;

    final loserPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    Path createDashedLine(Offset from, Offset to, {double dashLength = 5, double gap = 3}) {
      final path = Path();
      final totalDistance = (to - from).distance;
      final direction = (to - from) / totalDistance;

      double distance = 0;
      while (distance < totalDistance) {
        final start = from + direction * distance;
        final end = from + direction * (distance + dashLength);
        path.moveTo(start.dx, start.dy);
        path.lineTo(end.dx, end.dy);
        distance += dashLength + gap;
      }

      return path;
    }

    // 준결승 박스 위치
    final semi1RightWinner = Offset(220, 120); // 준결승1 승자 라인 출발점
    final semi1RightLoser = Offset(220, 180);  // 준결승1 패자 라인 출발점

    final semi2RightWinner = Offset(220, 290); // 준결승2 승자 라인 출발점
    final semi2RightLoser = Offset(220, 350);  // 준결승2 패자 라인 출발점

    // 결승, 3·4위전 박스 위치
    final finalCenter = Offset(350, 240);
    final thirdCenter = Offset(300, 440);

    // ✅ 준결승1 → 결승 또는 3·4위
    final semi1WinnerIsTeam1 = semi1.team1.id == semi1.winnerTeamId;
    final semi1WinnerTarget = semi1WinnerIsTeam1 ? finalCenter : thirdCenter;
    final semi1LoserTarget = semi1WinnerIsTeam1 ? thirdCenter : finalCenter;

    canvas.drawLine(semi1RightWinner, semi1WinnerTarget, winnerPaint);
    // canvas.drawLine(semi1RightLoser, semi1LoserTarget, loserPaint);
    canvas.drawPath(createDashedLine(semi1RightLoser, semi1LoserTarget), loserPaint);

    // ✅ 준결승2 → 결승 또는 3·4위
    final semi2WinnerIsTeam1 = semi2.team1.id == semi2.winnerTeamId;
    final semi2WinnerTarget = semi2WinnerIsTeam1 ? finalCenter : thirdCenter;
    final semi2LoserTarget = semi2WinnerIsTeam1 ? thirdCenter : finalCenter;

    canvas.drawLine(semi2RightWinner, semi2WinnerTarget, winnerPaint);
    // canvas.drawLine(semi2RightLoser, semi2LoserTarget, loserPaint);
    canvas.drawPath(createDashedLine(semi2RightLoser, semi2LoserTarget), loserPaint);
  }



  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


