import 'package:flutter/material.dart';
import '../../model/Match.dart';
import '../../model/Team.dart';
import '../../services/firestore_service.dart';

abstract class MatchStatusBase extends StatefulWidget {
  final bool isAdmin;
  const MatchStatusBase({super.key, required this.isAdmin});

  @override
  MatchStatusBaseState createState();
}

abstract class MatchStatusBaseState<T extends MatchStatusBase> extends State<T> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Match> allMatches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    Map<String, List<Match>> matchMap = await _firestoreService.loadMatches();
    allMatches = matchMap.values.expand((matchList) => matchList).toList();
    setState(() => isLoading = false);
  }

  Future<void> _assignMatchToCourt(Match match, int courtNumber, String gender, int division) async {
    match.courtNumber = courtNumber;
    await _firestoreService.updateMatchCourt(match.id, courtNumber, gender, division);
    _loadMatches();
  }

  /*@override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    List<Match> ongoingMatches = allMatches
        .where((m) => m.courtNumber != null && !m.isCompleted)
        .toList();

    List<String> activeTeamIds = ongoingMatches
        .expand((m) => [m.team1.id, m.team2.id])
        .toSet()
        .toList();

    List<Match> waitingMatches = [];
    Set<String> waitingTeamIds = {};

    for (var match in allMatches) {
      if (match.courtNumber == null && !match.isCompleted) {
        if (activeTeamIds.contains(match.team1.id) ||
            activeTeamIds.contains(match.team2.id) ||
            waitingTeamIds.contains(match.team1.id) ||
            waitingTeamIds.contains(match.team2.id)) continue;

        waitingMatches.add(match);
        waitingTeamIds.add(match.team1.id);
        waitingTeamIds.add(match.team2.id);

        if (waitingMatches.length >= 3) break;
      }
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20,),
          _buildCourtsGrid(ongoingMatches),
          const SizedBox(height: 20),
          const Text("대기 팀", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ...waitingMatches.map(_buildWaitingCard).toList(),
        ],
      ),
    );
  }*/

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Match>>(
      stream: _firestoreService.watchAllMatches(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final allMatches = snapshot.data!;

        // 진행 중 + 대기 경기 분류 (기존 로직 유지)
        final ongoingMatches = allMatches.where((m) => m.courtNumber != null && !m.isCompleted).toList();
        final activeTeamIds = ongoingMatches.expand((m) => [m.team1.id, m.team2.id]).toSet();

        final waitingMatches = <Match>[];
        final waitingTeamIds = <String>{};

        for (var match in allMatches) {
          if (match.courtNumber == null && !match.isCompleted) {
            if (activeTeamIds.contains(match.team1.id) ||
                activeTeamIds.contains(match.team2.id) ||
                waitingTeamIds.contains(match.team1.id) ||
                waitingTeamIds.contains(match.team2.id)) continue;

            waitingMatches.add(match);
            waitingTeamIds.add(match.team1.id);
            waitingTeamIds.add(match.team2.id);
            if (waitingMatches.length >= 3) break;
          }
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildCourtsGrid(ongoingMatches),
              const SizedBox(height: 20),
              const Text("대기 팀", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ...waitingMatches.map(_buildWaitingCard).toList(),
            ],
          ),
        );
      },
    );
  }


  ///코트 상황 판
  Widget _buildCourtsGrid(List<Match> matches) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      childAspectRatio: 0.8,
      children: List.generate(12, (index) {
        int courtNum = index + 1;
        final match = matches.firstWhere(
              (m) => m.courtNumber == courtNum,
          orElse: () => Match(
            id: "",
            team1: Team.empty(),
            team2: Team.empty(),
            division: 0,
            courtNumber: courtNum,
          ),
        );

        ///UI부분
        return Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            color: match.id == "" ? Colors.grey[200] : Colors.lightGreen[200],
          ),
          child: Center(
            child: match.id == "" ? Text("코트 $courtNum\n(비어 있음)", textAlign: TextAlign.center)
                : Text("${match.team1.id}\nvs\n${match.team2.id}", textAlign: TextAlign.center),
          ),
        );
      }),
    );
  }

  Widget _buildWaitingCard(Match match) {
    final gender = match.team1.players[0].gender;
    final division = match.division;
    final label = "$gender ${division}부";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text("${match.team1.players[0].name}, ${match.team1.players[1].name}"),
            const Text("  VS  "),
            Text("${match.team2.players[0].name}, ${match.team2.players[1].name}"),
            const Spacer(),

            // ✅ 운영자일 때만 입장 버튼 표시
            if (widget.isAdmin)
              ElevatedButton(
                onPressed: () {
                  Set<int> usedCourts = allMatches
                      .where((m) => m.courtNumber != null && !m.isCompleted)
                      .map((m) => m.courtNumber!)
                      .toSet();

                  int? availableCourt;
                  for (int i = 1; i <= 12; i++) {
                    if (!usedCourts.contains(i)) {
                      availableCourt = i;
                      break;
                    }
                  }

                  if (availableCourt != null) {
                    _assignMatchToCourt(match, availableCourt, gender, division);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("모든 코트가 사용 중입니다.")),
                    );
                  }
                },
                child: const Text("입장"),
              ),
          ],
        ),
      ),
    );
  }
}
