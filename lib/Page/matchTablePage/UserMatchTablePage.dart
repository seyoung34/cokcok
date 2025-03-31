import 'package:flutter/material.dart';
import 'MatchTableBase.dart';

class UserMatchTablePage extends MatchTableBase {
  const UserMatchTablePage({super.key, required String tournamentId})
      : super(tournamentId: tournamentId, isAdmin: false);

  @override
  _UserMatchTablePageState createState() => _UserMatchTablePageState();
}

class _UserMatchTablePageState
    extends MatchTableBaseState<UserMatchTablePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("경기 결과 확인")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: matchTable.keys.map((categoryKey) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<String?>(
                    value: categoryKey,
                    groupValue: selectedTableKey,
                    onChanged: (value) =>
                        setState(() => selectedTableKey = value),
                    toggleable: true,
                  ),
                  Text(categoryKey),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          if (selectedTableKey != null)
            Expanded(
              child: buildMatchTable(
                matchTable[selectedTableKey!] ?? [],
              ),
            )
          else
            const Text("표시할 경기가 없습니다."),
        ],
      ),
    );
  }
}
