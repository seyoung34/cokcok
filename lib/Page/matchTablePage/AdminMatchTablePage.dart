import 'package:flutter/material.dart';
import '../../model/Match.dart';
import '../../model/Team.dart';
import '../../services/firestore_service.dart';
import 'MatchTableBase.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class AdminMatchTablePage extends MatchTableBase {
  const AdminMatchTablePage({super.key, required String tournamentId})
      : super(tournamentId: tournamentId, isAdmin: true);

  @override
  _AdminMatchTablePageState createState() => _AdminMatchTablePageState();
}

class _AdminMatchTablePageState extends MatchTableBaseState<AdminMatchTablePage> {
  @override
  Widget buildMatchTable(List<Match> matches) {
    final teams = getUniqueTeams(matches);
    final gender = matches[0].team1.players[0].gender;
    final teamStats = calculateStats(matches, teams);

    return _buildDataTable(teams, matches, teamStats, gender, isAdmin: true);
  }


  Widget _buildDataTable(List<Team> teams, List<Match> matches, Map<String, Map<String, dynamic>> stats, String gender, {required bool isAdmin}) {
    return Scrollbar(
      thumbVisibility: true,
      controller: verticalController,
      child: SingleChildScrollView(
        controller: verticalController,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          thumbVisibility: true,
          controller: horizontalController,
          child: SingleChildScrollView(
            controller: horizontalController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text("팀명")),
                ...teams.map((t) => DataColumn(label: Text(t.id))),
                const DataColumn(label: Text("순위")),
                const DataColumn(label: Text("승점")),
                const DataColumn(label: Text("득실")),
              ],
              rows: teams.map((rowTeam) {
                return DataRow(cells: [
                  DataCell(Text(rowTeam.id)),
                  ...teams.map((colTeam) {
                    if (rowTeam.id == colTeam.id) return const DataCell(SizedBox());

                    final match = matches.firstWhere(
                          (m) => (m.team1.id == rowTeam.id && m.team2.id == colTeam.id) ||
                          (m.team1.id == colTeam.id && m.team2.id == rowTeam.id),
                      orElse: () => Match(id: '', team1: rowTeam, team2: colTeam, division: rowTeam.division),
                    );

                    //좌우반전 여부 스코어 설정
                    final score = match.isCompleted
                        ? (rowTeam.id == match.team2.id
                        ? "${match.team2Score} - ${match.team1Score}"
                        : "${match.team1Score} - ${match.team2Score}")
                        : null;

                    //todo 게임중일 때 아이콘 변경하기
                    return DataCell(
                      InkWell(
                        onTap: () => showScoreDialog(match, gender),
                        child: () {
                          if (score != null) {
                            return Text(score);
                          } else if (match.courtNumber != null) {
                            return Row(
                              children: [
                                getCourtIcon(match.courtNumber!), // 위에서 만든 함수 사용
                                const SizedBox(width: 4),
                                Text("코트 ${match.courtNumber}"),
                              ],
                            );
                          } else {
                            return const Icon(MaterialSymbols.edit, size: 18, color: Colors.grey);
                          }
                        }(),
                      ),
                    );

                  }),
                  DataCell(Text("${stats[rowTeam.id]!["rank"]}")),
                  DataCell(Text("${stats[rowTeam.id]!["wins"]}")),
                  DataCell(Text("${stats[rowTeam.id]!["diff"]}")),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Icon getCourtIcon(int courtNumber) {
    switch (courtNumber) {
      case 1: return const Icon(MaterialSymbols.counter_1, size: 18, color: Colors.green);
      case 2: return const Icon(MaterialSymbols.counter_2, size: 18, color: Colors.green);
      case 3: return const Icon(MaterialSymbols.counter_3, size: 18, color: Colors.green);
      case 4: return const Icon(MaterialSymbols.counter_4, size: 18, color: Colors.green);
      case 5: return const Icon(MaterialSymbols.counter_5, size: 18, color: Colors.green);
      case 6: return const Icon(MaterialSymbols.counter_6, size: 18, color: Colors.green);
      default: return const Icon(Icons.error, size: 18, color: Colors.red); // 예외 처리
    }
  }

}
