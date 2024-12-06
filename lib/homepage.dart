import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:blue_bulletin/main.dart';
import 'package:blue_bulletin/item.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> announcements = [];
  List<Map<String, dynamic>> filteredAnnouncements = [];
  TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final LayerLink layerLink = LayerLink();
  List<String> previousSearches = [];
  OverlayEntry? overlayEntry;
  bool showSuggestions = false;
  DateTime? startDate;
  DateTime? endDate;
  final userId = supabase.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
    searchFocusNode.addListener(() {
      if (searchFocusNode.hasFocus) {
        _showSuggestionsOverlay();
      } else {
        _hideSuggestionsOverlay();
      }
    });
    _loadSearchHistory(userId);
  }

  // Fetch announcements from Supabase
  Future<void> _fetchAnnouncements() async {
    final response =
        await supabase.from('events').select('*, event_images(image_url)');

    if (response != null && response.isNotEmpty) {
      setState(() {
        announcements = List<Map<String, dynamic>>.from(response);
        filteredAnnouncements = List<Map<String, dynamic>>.from(announcements);
      });
    } else {
      print('Error fetching announcements: No data found');
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (pickedRange != null) {
      setState(() {
        startDate = pickedRange.start;
        endDate = pickedRange.end;
        _applyFilters();
      });
    }
  }

  Future<void> _loadSearchHistory(String userId) async {
    if (userId.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? storedSearches =
          prefs.getStringList('previousSearches_$userId');
      if (storedSearches != null) {
        setState(() {
          previousSearches = storedSearches;
        });
        print("Search history loaded for user $userId");
      } else {
        print("No search history found for user $userId");
      }
    } else {
      print("Invalid user ID");
    }
  }

  Future<void> _saveSearchHistory(String userId) async {
    if (userId.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('previousSearches_$userId', previousSearches);
      print("Search history saved for user $userId");
    } else {
      print("Invalid user ID");
    }
  }

  void _applyFilters() {
    String searchText = searchController.text.toLowerCase();
    setState(() {
      filteredAnnouncements = announcements.where((announcement) {
        final title = (announcement['title'] ?? '').toLowerCase();
        final dateCreated = announcement['date_created'] != null
            ? DateTime.parse(announcement['date_created']).toLocal()
            : null;
        bool matchesSearch = title.contains(searchText);
        bool matchesDate = true;
        if (startDate != null && endDate != null && dateCreated != null) {
          matchesDate = dateCreated.isAfter(startDate!) &&
              !dateCreated.isAfter(endDate!.add(const Duration(days: 1)));
        }

        return matchesSearch && matchesDate;
      }).toList();
    });
  }

  OverlayEntry _buildSuggestionsOverlay() {
    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: MediaQuery.of(context).size.width -
              58, // Match width to TextField
          child: CompositedTransformFollower(
            link: layerLink,
            offset: const Offset(0, 48), // Adjust offset as needed
            child: Material(
              elevation: 4.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                ), // Apply rounded corners
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: previousSearches.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(previousSearches[index]),
                      onTap: () {
                        searchController.text = previousSearches[index];
                        _applyFilters();
                        _hideSuggestionsOverlay();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Show the overlay
  void _showSuggestionsOverlay() {
    _hideSuggestionsOverlay();
    overlayEntry = _buildSuggestionsOverlay();
    Overlay.of(context).insert(overlayEntry!);
  }

  // Hide the overlay
  void _hideSuggestionsOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final profileImageUrl = user?.userMetadata?['avatar_url'];
    final fullName =
        (user != null) ? (user.userMetadata?['full_name'] ?? 'User') : 'Guest';
    final email = user?.email ?? 'Guest';

    // Get the last login time
    final lastLoginTime = user?.lastSignInAt != null
        ? DateTime.parse(user!.lastSignInAt!).toLocal()
        : null;
    final formattedLastLogin = lastLoginTime != null
        ? '${lastLoginTime.day} ${_getMonthName(lastLoginTime.month)} ${lastLoginTime.year} ${_formatTime(lastLoginTime)}'
        : 'Unknown';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF21264d),
              Color(0xFF525eb4),
            ], // Customize the colors
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildGreetingSection(fullName, formattedLastLogin),
              _buildAnnouncementsSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchAnnouncements,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // Helper to get month name
  String _getMonthName(int month) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return monthNames[month - 1];
  }

  // Helper to format time as HH:MM AM/PM
  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  // Greeting Section
  Widget _buildGreetingSection(String? fullName, String lastLogin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
          top: 50.0, left: 20.0, right: 20.0, bottom: 20.0),
      decoration: const BoxDecoration(
        color: Color(0xE62E3192),
        image: DecorationImage(
          image: AssetImage('assets/images/banner.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Color(0x992E3192),
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/icons/addu.png',
            height: 100,
          ),
          Text(
            'Good Morning, $fullName',
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'Your last login was $lastLogin',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Helper for Bookmark Icons
  Widget _buildBookmarkIcon(String iconPath, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey[200],
          child: Image.asset(iconPath, height: 30),
        ),
        const SizedBox(height: 5),
        Text(label),
      ],
    );
  }

  // Announcements Section
  Widget _buildAnnouncementsSection() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      SizedBox(width: 10),
                      Text(
                        'RECENT ANNOUNCEMENTS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      searchController.clear();
                      setState(() {
                        startDate = null;
                        endDate = null;
                        filteredAnnouncements =
                            List<Map<String, dynamic>>.from(announcements);
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: CompositedTransformTarget(
              link: layerLink,
              child: TextField(
                onTap: () {
                  _showSuggestionsOverlay();
                },
                controller: searchController,
                focusNode: searchFocusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search announcements...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.3),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.date_range, color: Colors.white),
                    onPressed: () => _selectDateRange(context),
                  ),
                  border: InputBorder.none,
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onChanged: (value) => _applyFilters(),
                onSubmitted: (value) {
                  _applyFilters();
                  setState(() {
                    previousSearches.insert(0, value);
                    if (previousSearches.length > 5) {
                      previousSearches.removeLast();
                    }
                    _saveSearchHistory(userId);
                  });
                  _hideSuggestionsOverlay();
                },
              ),
            ),
          ),
          if (filteredAnnouncements.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredAnnouncements.length,
              itemBuilder: (context, index) {
                final announcement = filteredAnnouncements[index];
                final title = announcement['title'] ?? '';
                final imageUrls = announcement['event_images'] != null &&
                        announcement['event_images'].isNotEmpty
                    ? List<String>.from(
                        announcement['event_images'][0]['image_url'])
                    : [];
                final photoUrl = imageUrls.isNotEmpty ? imageUrls.first : '';
                final date_created = announcement['date_created'] != null
                    ? DateTime.parse(announcement['date_created']).toLocal()
                    : null;

                if (date_created != null) {
                  return _buildAnnouncementCard(
                      title, photoUrl, date_created, announcement['id']);
                } else {
                  return const SizedBox.shrink();
                }
              },
            )
          else
            const Text('No announcements available'),
        ],
      ),
    );
  }

  // Helper for Announcement Card
  Widget _buildAnnouncementCard(
      String title, String photoUrl, DateTime postedTime, int eventId) {
    final formattedPostedTime =
        '${postedTime.day} ${_getMonthName(postedTime.month)} ${postedTime.year} ${_formatTime(postedTime)}';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: Colors.white.withOpacity(0.3),
      child: ListTile(
        contentPadding: EdgeInsets.all(10),
        leading: SizedBox(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8.0)),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Image(
                    image: AssetImage('assets/images/placeholder.jpg'),
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ),
        ),
        title: Text(
          truncateWithEllipsis(title, 10),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          formattedPostedTime,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        trailing: TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemPage(eventId: eventId),
              ),
            );
          },
          child: const Text(
            'View',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // Campus Information Section
  Widget _buildCampusInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CAMPUS INFORMATION',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCampusInfoCard('Mission', const Color(0xFF2E3192)),
              _buildCampusInfoCard('Quality Policy', const Color(0xFF2E3192)),
            ],
          ),
        ],
      ),
    );
  }

  // Helper for Campus Information Cards
  Widget _buildCampusInfoCard(String label, Color color) {
    return Expanded(
      child: Card(
        color: color,
        child: Container(
          height: 100,
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

String truncateWithEllipsis(String text, int wordLimit) {
  List<String> words = text.split(' ');
  if (words.length <= wordLimit) {
    return text;
  }
  return words.sublist(0, wordLimit).join(' ') + '...';
}
