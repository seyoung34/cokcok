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
  }

  //매치에 코트 넘버 부여
  Future<void> _assignMatchToCourt(Match match, int courtNumber, String gender, String division) async {
    match.courtNumber = courtNumber;
    await _firestoreService.updateMatchCourt(match.id, courtNumber, gender, division);
    // _loadMatches();
  }
  

  //note build
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Match>>(
      stream: _firestoreService.watchAllMatches(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        allMatches = snapshot.data!;

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
    return Container(
      margin: EdgeInsets.fromLTRB(8, 20, 8, 0),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        children: List.generate(6, (index) {
          int courtNum = index + 1;
      
          // 2열 1행(5번 인덱스)을 막힌 코트로 처리
          if (index == 1) {
            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
                color: Colors.grey[300],
              ),
              child: const Center(
                child: Text("막혀있음\n(사용 불가)", textAlign: TextAlign.center),
              ),
            );
          }
      
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
      
          return Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black54),
              color: match.id == "" ? Colors.grey[200] : Colors.lightGreen[200],
            ),
            child: Center(
              child: match.id == ""
                  ? Text("코트 $courtNum\n(비어 있음)", textAlign: TextAlign.center)
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${match.team1.players[0].name}\n${match.team1.players[1].name}", textAlign: TextAlign.center),
                  const Divider(color: Colors.grey, thickness: 1),
                  Text("${match.team2.players[0].name}\n${match.team2.players[1].name}", textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }


  ///대기팀
  Widget _buildWaitingCard(Match match) {
    final gender = match.team1.players[0].gender == match.team1.players[1].gender ? match.team1.players[0].gender : "혼성";
    final division = match.group != null ? "${match.division}_${match.group}" : match.division.toString();

    final label = "$gender ${division}부";

    return Card(
      color:gender == "남성" ? Colors.blue.shade100 : gender == "여성"? Colors.pink.shade100 : Colors.green.shade100,
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
                    Set<int> usedCourts = allMatches  ///사용중인 코트
                        .where((m) => m.courtNumber != null && !m.isCompleted)  /// 널아님,완료
                        .map((m) => m.courtNumber!)
                        .toSet(); ///사용중인 코트

                    int? availableCourt;
                    for (int i = 1; i <= 6; i++) {
                      print("i : $i");
                      if (!usedCourts.contains(i) && i != 2) {
                        availableCourt = i; ///비어있으면 브레이크로 탈출
                        print("availableCourt : $availableCourt");
                        break;
                      }
                    }

                    if (availableCourt != null) { ///비어있는 코트가 있으면
                      _assignMatchToCourt(match, availableCourt, gender, division); //코트 할당
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
