import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

enum _BoardType { trophies, streak }

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  static const double _itemExtent = 90.0;

  late final TabController _tabController;

  late Future<List<DocumentSnapshot<Map<String, dynamic>>>> _trophyFuture;
  late Future<List<DocumentSnapshot<Map<String, dynamic>>>> _streakFuture;

  final ScrollController _trophyScroll = ScrollController();
  final ScrollController _streakScroll = ScrollController();

  // --- TROPHY visible tracking
  bool _trophyUserTileVisible = false;
  double _trophyViewportHeight = 0;
  int _trophyFirstVisibleIndex = 0;
  int _trophyLastVisibleIndex = 0;
  bool _trophyVisibleRangeReady = false;

  // --- STREAK visible tracking
  bool _streakUserTileVisible = false;
  double _streakViewportHeight = 0;
  int _streakFirstVisibleIndex = 0;
  int _streakLastVisibleIndex = 0;
  bool _streakVisibleRangeReady = false;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _trophyFuture = _loadLeaderboard(_BoardType.trophies);
    _streakFuture = _loadLeaderboard(_BoardType.streak);

    _trophyScroll.addListener(() => _updateVisibleRange(_BoardType.trophies));
    _streakScroll.addListener(() => _updateVisibleRange(_BoardType.streak));
  }

  @override
  void dispose() {
    _trophyScroll.dispose();
    _streakScroll.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> _loadLeaderboard(
      _BoardType type,
      ) async {
    final db = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return [];

    final field =
    type == _BoardType.trophies ? 'trophies' : 'currentStreakDays';

    final top50snap = await db
        .collection('users')
        .orderBy(field, descending: true)
        .limit(50)
        .get();

    final top50 = top50snap.docs;

    final me = await db.collection('users').doc(user.uid).get();
    final isInTop50 = top50.any((d) => d.id == user.uid);

    return isInTop50 ? top50 : [...top50, me];
  }

  Future<void> _onRefresh(_BoardType type) async {
    setState(() {
      if (type == _BoardType.trophies) {
        _trophyFuture = _loadLeaderboard(_BoardType.trophies);
        _trophyUserTileVisible = false;
        _trophyVisibleRangeReady = false;
        _trophyFirstVisibleIndex = 0;
        _trophyLastVisibleIndex = 0;
      } else {
        _streakFuture = _loadLeaderboard(_BoardType.streak);
        _streakUserTileVisible = false;
        _streakVisibleRangeReady = false;
        _streakFirstVisibleIndex = 0;
        _streakLastVisibleIndex = 0;
      }
    });

    if (type == _BoardType.trophies) {
      await _trophyFuture;
    } else {
      await _streakFuture;
    }
  }

  void _updateVisibleRange(_BoardType type) {
    final sc = type == _BoardType.trophies ? _trophyScroll : _streakScroll;
    final viewport =
    type == _BoardType.trophies ? _trophyViewportHeight : _streakViewportHeight;

    if (!sc.hasClients || viewport <= 0) return;

    final offset = sc.offset.clamp(0.0, double.infinity);

    final first = (offset / _itemExtent).floor().clamp(0, 1000000);
    final last =
    ((offset + viewport) / _itemExtent).floor().clamp(first, 1000000);

    setState(() {
      if (type == _BoardType.trophies) {
        if (first != _trophyFirstVisibleIndex ||
            last != _trophyLastVisibleIndex ||
            !_trophyVisibleRangeReady) {
          _trophyFirstVisibleIndex = first;
          _trophyLastVisibleIndex = last;
          _trophyVisibleRangeReady = true;
        }
      } else {
        if (first != _streakFirstVisibleIndex ||
            last != _streakLastVisibleIndex ||
            !_streakVisibleRangeReady) {
          _streakFirstVisibleIndex = first;
          _streakLastVisibleIndex = last;
          _streakVisibleRangeReady = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF2C015D);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Removed the title text (e.g., "Рейтинг")

              // Tabs (icon-only), shorter height, full-width indicator
              SizedBox(
                height: 44, // ✅ shorter
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x142C015D),
                        blurRadius: 14,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab, // ✅ full tab width
                    indicator: BoxDecoration(
                      color: const Color(0xFFEDD9FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorPadding: EdgeInsets.zero,
                    dividerColor: Colors.transparent,
                    splashBorderRadius: BorderRadius.circular(12),
                    labelPadding: EdgeInsets.zero, // ✅ no extra height
                    labelColor: purple,
                    unselectedLabelColor: purple.withOpacity(0.55),
                    tabs: const [
                      Tab(
                        iconMargin: EdgeInsets.zero,
                        icon: Icon(Icons.emoji_events_rounded, size: 22),
                      ),
                      Tab(
                        iconMargin: EdgeInsets.zero,
                        icon: Icon(Icons.local_fire_department_rounded, size: 22),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _LeaderboardTab(
                      type: _BoardType.trophies,
                      future: _trophyFuture,
                      scrollController: _trophyScroll,
                      onRefresh: () => _onRefresh(_BoardType.trophies),
                      itemExtent: _itemExtent,
                      onViewportHeight: (h) {
                        if (_trophyViewportHeight != h) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            _trophyViewportHeight = h;
                            _updateVisibleRange(_BoardType.trophies);
                          });
                        }
                      },
                      isUserTileVisible: _trophyUserTileVisible,
                      setUserTileVisible: (v) {
                        if (_trophyUserTileVisible != v) {
                          setState(() => _trophyUserTileVisible = v);
                        }
                      },
                      visibleRangeReady: _trophyVisibleRangeReady,
                      firstVisibleIndex: _trophyFirstVisibleIndex,
                      lastVisibleIndex: _trophyLastVisibleIndex,
                      metricField: 'trophies',
                      metricIcon: Icons.emoji_events_rounded,
                      metricIconColor: const Color(0xFFFFC107),
                    ),
                    _LeaderboardTab(
                      type: _BoardType.streak,
                      future: _streakFuture,
                      scrollController: _streakScroll,
                      onRefresh: () => _onRefresh(_BoardType.streak),
                      itemExtent: _itemExtent,
                      onViewportHeight: (h) {
                        if (_streakViewportHeight != h) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            _streakViewportHeight = h;
                            _updateVisibleRange(_BoardType.streak);
                          });
                        }
                      },
                      isUserTileVisible: _streakUserTileVisible,
                      setUserTileVisible: (v) {
                        if (_streakUserTileVisible != v) {
                          setState(() => _streakUserTileVisible = v);
                        }
                      },
                      visibleRangeReady: _streakVisibleRangeReady,
                      firstVisibleIndex: _streakFirstVisibleIndex,
                      lastVisibleIndex: _streakLastVisibleIndex,
                      metricField: 'currentStreakDays', // ✅ Firestore field
                      metricIcon: Icons.local_fire_department_rounded,
                      metricIconColor: const Color(0xFFFF6A00),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final _BoardType type;
  final Future<List<DocumentSnapshot<Map<String, dynamic>>>> future;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final double itemExtent;

  final void Function(double height) onViewportHeight;

  final bool isUserTileVisible;
  final void Function(bool visible) setUserTileVisible;

  final bool visibleRangeReady;
  final int firstVisibleIndex;
  final int lastVisibleIndex;

  final String metricField;
  final IconData metricIcon;
  final Color metricIconColor;

  const _LeaderboardTab({
    required this.type,
    required this.future,
    required this.scrollController,
    required this.onRefresh,
    required this.itemExtent,
    required this.onViewportHeight,
    required this.isUserTileVisible,
    required this.setUserTileVisible,
    required this.visibleRangeReady,
    required this.firstVisibleIndex,
    required this.lastVisibleIndex,
    required this.metricField,
    required this.metricIcon,
    required this.metricIconColor,
  });

  int _readInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    return FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snap.hasData || snap.data!.isEmpty || userId == null) {
          return Center(
            child: Text(
              "No users yet",
              style: TextStyle(
                color: Colors.black.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          );
        }

        final docs = snap.data!;
        final myIndex = docs.indexWhere((d) => d.id == userId);

        return LayoutBuilder(
          builder: (context, constraints) {
            onViewportHeight(constraints.maxHeight);

            bool showTop = false;
            bool showBottom = false;

            if (visibleRangeReady && myIndex != -1 && !isUserTileVisible) {
              if (myIndex < firstVisibleIndex) {
                showTop = true;
              } else if (myIndex > lastVisibleIndex) {
                showBottom = true;
              }
            }

            return RefreshIndicator(
              onRefresh: onRefresh,
              child: Stack(
                children: [
                  ListView.separated(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() ?? {};

                      final String name = (data['fullName'] ?? '—') as String;
                      final String? photoUrl = data['photoUrl'] as String?;

                      final int metricValue = _readInt(data[metricField]);

                      final bool isMe = doc.id == userId;

                      if (isMe) {
                        return VisibilityDetector(
                          key: Key("${type.name}-user-tile-$userId"),
                          onVisibilityChanged: (info) {
                            final visible = info.visibleFraction > 0.45;
                            setUserTileVisible(visible);
                          },
                          child: _LeaderboardTile(
                            index: index,
                            name: name,
                            metricValue: metricValue,
                            photoUrl: photoUrl,
                            isMe: true,
                            metricIcon: metricIcon,
                            metricIconColor: metricIconColor,
                          ),
                        );
                      }

                      return _LeaderboardTile(
                        index: index,
                        name: name,
                        metricValue: metricValue,
                        photoUrl: photoUrl,
                        isMe: false,
                        metricIcon: metricIcon,
                        metricIconColor: metricIconColor,
                      );
                    },
                  ),

                  if (showTop || showBottom)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: showTop ? 4 : null,
                      bottom: showBottom ? 4 : null,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: -50, end: 0),
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, value),
                            child: child,
                          );
                        },
                        child: _FloatingMyTile(
                          docs: docs,
                          userId: userId,
                          metricField: metricField,
                          metricIcon: metricIcon,
                          metricIconColor: metricIconColor,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FloatingMyTile extends StatelessWidget {
  final List<DocumentSnapshot<Map<String, dynamic>>> docs;
  final String userId;
  final String metricField;
  final IconData metricIcon;
  final Color metricIconColor;

  const _FloatingMyTile({
    super.key,
    required this.docs,
    required this.userId,
    required this.metricField,
    required this.metricIcon,
    required this.metricIconColor,
  });

  int _readInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final doc = docs.firstWhere((d) => d.id == userId);
    final data = doc.data() ?? {};

    final String name = (data['fullName'] ?? '—') as String;
    final String? photoUrl = data['photoUrl'] as String?;

    final int metricValue = _readInt(data[metricField]);

    return _LeaderboardTile(
      index: docs.indexOf(doc),
      name: name,
      metricValue: metricValue,
      photoUrl: photoUrl,
      isMe: true,
      metricIcon: metricIcon,
      metricIconColor: metricIconColor,
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final int index;
  final String name;
  final int metricValue;
  final String? photoUrl;
  final bool isMe;

  final IconData metricIcon;
  final Color metricIconColor;

  const _LeaderboardTile({
    super.key,
    required this.index,
    required this.name,
    required this.metricValue,
    required this.photoUrl,
    required this.isMe,
    required this.metricIcon,
    required this.metricIconColor,
  });

  Color _rankColor(int rank) {
    switch (rank) {
      case 0:
        return const Color(0xFFFFD700);
      case 1:
        return const Color(0xFFC0C0C0);
      case 2:
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFF2C015D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rank = index + 1;
    final rankColor = _rankColor(index);

    final tileColor = isMe ? const Color(0xFFEDD9FF) : Colors.white;
    final borderColor = isMe ? const Color(0xFF9A4DFF) : Colors.transparent;

    return AnimatedScale(
      scale: isMe ? 1.03 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: isMe ? 2 : 0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x142C015D),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rankColor.withOpacity(0.1),
              ),
              alignment: Alignment.center,
              child: Text(
                "$rank",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: rankColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF2C015D),
              backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                  ? NetworkImage(photoUrl!)
                  : null,
              child: (photoUrl == null || photoUrl!.isEmpty)
                  ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : "?",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C015D),
                      ),
                    ),
                  ),
                  if (isMe)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9A4DFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "YOU",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                Icon(metricIcon, size: 20, color: metricIconColor),
                const SizedBox(width: 4),
                Text(
                  "$metricValue",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF2C015D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
