import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

enum _BoardType { trophies, streak }

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  // ✅ Compact tile height (real tiles + floating tile + shimmer all match this)
  static const double _itemExtent = 70.0;

  late final TabController _tabController;

  late Future<List<DocumentSnapshot<Map<String, dynamic>>>> _trophyFuture;
  late Future<List<DocumentSnapshot<Map<String, dynamic>>>> _streakFuture;

  final ScrollController _trophyScroll = ScrollController();
  final ScrollController _streakScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _trophyFuture = _loadLeaderboard(_BoardType.trophies);
    _streakFuture = _loadLeaderboard(_BoardType.streak);
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
      } else {
        _streakFuture = _loadLeaderboard(_BoardType.streak);
      }
    });

    if (type == _BoardType.trophies) {
      await _trophyFuture;
    } else {
      await _streakFuture;
    }
  }

  void _openUserDialog(
      BuildContext context,
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};
    final fullName = _readDisplayName(data);

    final photoUrlRaw = data['photoUrl'];
    final photoUrl = (photoUrlRaw is String && photoUrlRaw.trim().isNotEmpty)
        ? photoUrlRaw
        : null;

    int readInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    final trophies = readInt(data['trophies']);
    final streakDays = readInt(data['currentStreakDays']);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _CenteredUserDialog(
        fullName: fullName,
        photoUrl: photoUrl,
        trophies: trophies,
        streakDays: streakDays,
      ),
    );
  }

  String _readDisplayName(Map<String, dynamic> data) {
    String pick(dynamic v) => (v ?? '').toString().trim();

    final displayName = pick(data['displayName']);
    if (displayName.isNotEmpty) return displayName;

    final fullName = pick(data['fullName']);
    if (fullName.isNotEmpty) return fullName;

    final firstName = pick(data['firstName']);
    final surname = pick(data['surname']);
    final combined = ('$firstName $surname').trim();
    if (combined.isNotEmpty) return combined;

    final name = pick(data['name']);
    if (name.isNotEmpty) return name;

    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 44,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.60),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withOpacity(0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.45),
                      ),
                    ),
                    indicatorPadding: EdgeInsets.zero,
                    dividerColor: Colors.transparent,
                    splashBorderRadius: BorderRadius.circular(12),
                    labelPadding: EdgeInsets.zero,
                    labelColor: cs.onPrimaryContainer,
                    unselectedLabelColor: cs.onSurfaceVariant,
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
                      metricField: 'trophies',
                      metricIcon: Icons.emoji_events_rounded,
                      metricIconColor: cs.tertiary,
                      shortenMetric: true,
                      onOpenUser: _openUserDialog,
                    ),
                    _LeaderboardTab(
                      type: _BoardType.streak,
                      future: _streakFuture,
                      scrollController: _streakScroll,
                      onRefresh: () => _onRefresh(_BoardType.streak),
                      itemExtent: _itemExtent,
                      metricField: 'currentStreakDays',
                      metricIcon: Icons.local_fire_department_rounded,
                      metricIconColor: const Color(0xFFFF5A00),
                      shortenMetric: false,
                      onOpenUser: _openUserDialog,
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

class _LeaderboardTab extends StatefulWidget {
  final _BoardType type;
  final Future<List<DocumentSnapshot<Map<String, dynamic>>>> future;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final double itemExtent;

  final String metricField;
  final IconData metricIcon;
  final Color metricIconColor;
  final bool shortenMetric;

  final void Function(
      BuildContext context,
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) onOpenUser;

  const _LeaderboardTab({
    required this.type,
    required this.future,
    required this.scrollController,
    required this.onRefresh,
    required this.itemExtent,
    required this.metricField,
    required this.metricIcon,
    required this.metricIconColor,
    required this.shortenMetric,
    required this.onOpenUser,
  });

  @override
  State<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<_LeaderboardTab> {
  static const double _gap = 8.0;

  double _viewportHeight = 0;

  int _firstVisibleIndex = 0;
  int _lastVisibleIndex = 0;
  bool _visibleRangeReady = false;

  bool _userTileVisible = false;

  bool _rangeUpdateScheduled = false;

  int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  String _readDisplayName(Map<String, dynamic> data) {
    String pick(dynamic v) => (v ?? '').toString().trim();

    final displayName = pick(data['displayName']);
    if (displayName.isNotEmpty) return displayName;

    final fullName = pick(data['fullName']);
    if (fullName.isNotEmpty) return fullName;

    final firstName = pick(data['firstName']);
    final surname = pick(data['surname']);
    final combined = ('$firstName $surname').trim();
    if (combined.isNotEmpty) return combined;

    final name = pick(data['name']);
    if (name.isNotEmpty) return name;

    return '—';
  }

  String? _readPhotoUrl(Map<String, dynamic> data) {
    final raw = data['photoUrl'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  double get _rowExtent => widget.itemExtent + _gap;

  void _scheduleRangeUpdate() {
    if (_rangeUpdateScheduled) return;
    _rangeUpdateScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rangeUpdateScheduled = false;
      if (!mounted) return;
      _updateVisibleRangeNow();
    });
  }

  void _updateVisibleRangeNow() {
    final sc = widget.scrollController;
    if (!sc.hasClients || _viewportHeight <= 0) return;

    final offset = sc.offset.clamp(0.0, double.infinity);

    final first = (offset / _rowExtent).floor().clamp(0, 1000000);
    final last =
    ((offset + _viewportHeight) / _rowExtent).floor().clamp(first, 1000000);

    if (first != _firstVisibleIndex ||
        last != _lastVisibleIndex ||
        !_visibleRangeReady) {
      setState(() {
        _firstVisibleIndex = first;
        _lastVisibleIndex = last;
        _visibleRangeReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    final shimmerBase =
    isDark ? const Color(0xFF2A2434) : const Color(0xFFE3DDF0);
    final shimmerHighlight =
    isDark ? const Color(0xFF3A3346) : const Color(0xFFF9F7FF);

    return FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
      future: widget.future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _LeaderboardShimmer(
            itemExtent: widget.itemExtent,
            gap: _gap,
            baseColor: shimmerBase,
            highlightColor: shimmerHighlight,
          );
        }

        if (!snap.hasData || snap.data!.isEmpty || userId == null) {
          return Center(
            child: Text(
              "No users yet",
              style: TextStyle(
                color: cs.onBackground.withOpacity(0.65),
                fontSize: 14,
              ),
            ),
          );
        }

        final docs = snap.data!;
        final myIndex = docs.indexWhere((d) => d.id == userId);

        final nowUserVisible = _visibleRangeReady &&
            myIndex != -1 &&
            myIndex >= _firstVisibleIndex &&
            myIndex <= _lastVisibleIndex;

        if (nowUserVisible != _userTileVisible) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_userTileVisible != nowUserVisible) {
              setState(() => _userTileVisible = nowUserVisible);
            }
          });
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (_viewportHeight != constraints.maxHeight) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _viewportHeight = constraints.maxHeight;
                _scheduleRangeUpdate();
              });
            }

            bool showTop = false;
            bool showBottom = false;

            if (_visibleRangeReady && myIndex != -1 && !_userTileVisible) {
              if (myIndex < _firstVisibleIndex) {
                showTop = true;
              } else if (myIndex > _lastVisibleIndex) {
                showBottom = true;
              }
            }

            return NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollUpdateNotification ||
                    n is UserScrollNotification ||
                    n is ScrollEndNotification) {
                  _scheduleRangeUpdate();
                }
                return false;
              },
              child: RefreshIndicator(
                onRefresh: widget.onRefresh,
                child: Stack(
                  children: [
                    ListView.builder(
                      controller: widget.scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemExtent: _rowExtent, // ✅ fixed extent
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() ?? {};

                        final String name = _readDisplayName(data);
                        final String? photoUrl = _readPhotoUrl(data);
                        final int metricValue = _readInt(data[widget.metricField]);
                        final bool isMe = doc.id == userId;

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == docs.length - 1 ? 0 : _gap,
                          ),
                          child: SizedBox(
                            height: widget.itemExtent, // ✅ real tile height locked
                            child: RepaintBoundary(
                              child: LeaderboardUserTile(
                                index: index,
                                name: name,
                                metricValue: metricValue,
                                photoUrl: photoUrl,
                                isMe: isMe,
                                metricIcon: widget.metricIcon,
                                metricIconColor: widget.metricIconColor,
                                shortenMetric: widget.shortenMetric,
                                onTap: () => widget.onOpenUser(context, doc),
                              ),
                            ),
                          ),
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
                          child: SizedBox(
                            height: widget.itemExtent, // ✅ floating tile height matches
                            child: _FloatingMyTile(
                              itemExtent: widget.itemExtent,
                              docs: docs,
                              userId: userId,
                              metricField: widget.metricField,
                              metricIcon: widget.metricIcon,
                              metricIconColor: widget.metricIconColor,
                              shortenMetric: widget.shortenMetric,
                              onTapDoc: (doc) => widget.onOpenUser(context, doc),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LeaderboardShimmer extends StatelessWidget {
  final double itemExtent;
  final double gap;
  final Color baseColor;
  final Color highlightColor;

  const _LeaderboardShimmer({
    required this.itemExtent,
    required this.gap,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 0),
        itemCount: 10,
        // ✅ shimmer row height EXACTLY matches list row height
        itemExtent: itemExtent + gap,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index == 9 ? 0 : gap),
            child: SizedBox(
              height: itemExtent, // ✅ shimmer tile height locked
              child: _LeaderboardShimmerTile(itemExtent: itemExtent),
            ),
          );
        },
      ),
    );
  }
}

class _LeaderboardShimmerTile extends StatelessWidget {
  final double itemExtent;

  const _LeaderboardShimmerTile({required this.itemExtent});

  @override
  Widget build(BuildContext context) {
    Widget pill({double w = 80, double h = 12, double r = 10}) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      height: itemExtent,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                pill(w: 160, h: 12),
                const SizedBox(height: 6),
                pill(w: 110, h: 11),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          pill(w: 44, h: 12),
        ],
      ),
    );
  }
}

class _FloatingMyTile extends StatelessWidget {
  final double itemExtent;
  final List<DocumentSnapshot<Map<String, dynamic>>> docs;
  final String userId;
  final String metricField;
  final IconData metricIcon;
  final Color metricIconColor;
  final bool shortenMetric;
  final void Function(DocumentSnapshot<Map<String, dynamic>> doc) onTapDoc;

  const _FloatingMyTile({
    super.key,
    required this.itemExtent,
    required this.docs,
    required this.userId,
    required this.metricField,
    required this.metricIcon,
    required this.metricIconColor,
    required this.shortenMetric,
    required this.onTapDoc,
  });

  int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  String _readDisplayName(Map<String, dynamic> data) {
    String pick(dynamic v) => (v ?? '').toString().trim();

    final displayName = pick(data['displayName']);
    if (displayName.isNotEmpty) return displayName;

    final fullName = pick(data['fullName']);
    if (fullName.isNotEmpty) return fullName;

    final firstName = pick(data['firstName']);
    final surname = pick(data['surname']);
    final combined = ('$firstName $surname').trim();
    if (combined.isNotEmpty) return combined;

    final name = pick(data['name']);
    if (name.isNotEmpty) return name;

    return '—';
  }

  String? _readPhotoUrl(Map<String, dynamic> data) {
    final raw = data['photoUrl'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final doc = docs.firstWhere((d) => d.id == userId);
    final data = doc.data() ?? {};

    final String name = _readDisplayName(data);
    final String? photoUrl = _readPhotoUrl(data);
    final int metricValue = _readInt(data[metricField]);

    return RepaintBoundary(
      child: SizedBox(
        height: itemExtent, // ✅ match real tiles
        child: LeaderboardUserTile(
          index: docs.indexOf(doc),
          name: name,
          metricValue: metricValue,
          photoUrl: photoUrl,
          isMe: true,
          metricIcon: metricIcon,
          metricIconColor: metricIconColor,
          shortenMetric: shortenMetric,
          onTap: () => onTapDoc(doc),
        ),
      ),
    );
  }
}

class LeaderboardUserTile extends StatelessWidget {
  final int index;
  final String name;
  final int metricValue;
  final String? photoUrl;
  final bool isMe;

  final IconData metricIcon;
  final Color metricIconColor;
  final bool shortenMetric;

  final VoidCallback onTap;

  const LeaderboardUserTile({
    super.key,
    required this.index,
    required this.name,
    required this.metricValue,
    required this.photoUrl,
    required this.isMe,
    required this.metricIcon,
    required this.metricIconColor,
    required this.shortenMetric,
    required this.onTap,
  });

  Color _rankColor(ColorScheme cs, int rankIndex) {
    final gold = Color.lerp(cs.tertiary, cs.secondary, 0.40)!;
    final silver = Color.lerp(cs.primary, cs.onSurface, 0.55)!;
    final bronze = Color.lerp(cs.secondary, cs.primary, 0.65)!;

    switch (rankIndex) {
      case 0:
        return gold;
      case 1:
        return silver;
      case 2:
        return bronze;
      default:
        return cs.primary;
    }
  }

  String _shortenCount(int value) {
    if (value < 1000) return value.toString();
    if (value < 10000) return "${(value / 1000).toStringAsFixed(1)}k";
    if (value < 1000000) return "${(value / 1000).floor()}k";
    if (value < 10000000) return "${(value / 1000000).toStringAsFixed(1)}M";
    return "${(value / 1000000).floor()}M";
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;
    final isDark = brightness == Brightness.dark;

    final rank = index + 1;
    final rankColor = _rankColor(cs, index);

    final baseTile = cs.surfaceContainerHigh;

    final meTile = isLight
        ? Color.alphaBlend(
      cs.primary.withOpacity(0.18),
      cs.surfaceContainerHighest,
    )
        : Color.alphaBlend(
      cs.primary.withOpacity(0.22),
      cs.surfaceContainerHigh,
    );

    final tileColor = isMe ? meTile : baseTile;

    final displayMetric =
    shortenMetric ? _shortenCount(metricValue) : "$metricValue";

    final Widget content = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          // ✅ reduced vertical padding => shorter tiles
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              // ✅ reduced shadow to avoid “tall” look
              BoxShadow(
                color: cs.shadow.withOpacity(
                  isMe ? (isLight ? 0.16 : 0.24) : (isDark ? 0.18 : 0.08),
                ),
                blurRadius: isMe ? 16 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (isMe)
                Positioned(
                  left: 0,
                  top: 8,
                  bottom: 8,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(left: isMe ? 10 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: rankColor.withOpacity(isDark ? 0.16 : 0.12),
                        ),
                        child: Center(
                          child: Text(
                            "$rank",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: rankColor,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // ✅ slightly smaller avatar
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        backgroundImage:
                        (photoUrl != null && photoUrl!.isNotEmpty)
                            ? NetworkImage(photoUrl!)
                            : null,
                        child: (photoUrl == null || photoUrl!.isEmpty)
                            ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "?",
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 8),
                              Container(
                                // ✅ smaller badge height
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "YOU",
                                  style: TextStyle(
                                    color: cs.onPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    SizedBox(
                      width: 86,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(metricIcon, size: 20, color: metricIconColor),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                displayMetric,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: cs.onSurface,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!isMe) return content;

    return AnimatedScale(
      scale: 1.02, // ✅ slightly smaller than before
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      child: content,
    );
  }
}

class _CenteredUserDialog extends StatelessWidget {
  final String fullName;
  final String? photoUrl;
  final int trophies;
  final int streakDays;

  const _CenteredUserDialog({
    required this.fullName,
    required this.photoUrl,
    required this.trophies,
    required this.streakDays,
  });

  String _shortenCount(int value) {
    if (value < 1000) return value.toString();
    if (value < 10000) return "${(value / 1000).toStringAsFixed(1)}k";
    if (value < 1000000) return "${(value / 1000).floor()}k";
    if (value < 10000000) return "${(value / 1000000).toStringAsFixed(1)}M";
    return "${(value / 1000000).floor()}M";
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.scrim.withOpacity(0.35),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        backgroundImage:
                        (photoUrl != null && photoUrl!.isNotEmpty)
                            ? NetworkImage(photoUrl!)
                            : null,
                        child: (photoUrl == null || photoUrl!.isEmpty)
                            ? Text(
                          fullName.isNotEmpty
                              ? fullName[0].toUpperCase()
                              : "?",
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fullName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: cs.onSurface.withOpacity(0.75),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: "Trophies",
                          value: _shortenCount(trophies),
                          icon: Icons.emoji_events_rounded,
                          iconColor: cs.tertiary,
                          bg: cs.tertiaryContainer,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          title: "Streak",
                          value: "$streakDays",
                          icon: Icons.local_fire_department_rounded,
                          iconColor: cs.secondary,
                          bg: cs.secondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bg;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.50)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.75),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withOpacity(0.70),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
