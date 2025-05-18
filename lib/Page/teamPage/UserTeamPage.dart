import 'package:flutter/material.dart';
import 'TeamPageBase.dart';

class UserTeamPage extends TeamPageBase {
  final VoidCallback onAdminRequest;

  const UserTeamPage({super.key, required this.onAdminRequest})
      : super(isAdmin: false);

  @override
  _UserTeamPageState createState() => _UserTeamPageState();
}

class _UserTeamPageState extends TeamPageBaseState<UserTeamPage> {
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
                  onPressed: widget.onAdminRequest,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          buildCategorySelector(),
          const SizedBox(height: 8),
          Expanded(child: buildSelectedCategoryView()),
        ],
      ),
    );
  }

}
