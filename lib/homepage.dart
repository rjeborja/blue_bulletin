import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:blue_bulletin/main.dart';
import 'package:blue_bulletin/item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> announcements = [];

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  // Fetch announcements from Supabase
  Future<void> _fetchAnnouncements() async {
    final response =
        await supabase.from('events').select('*, event_images(image_url)');

    if (response != null && response.isNotEmpty) {
      setState(() {
        announcements = List<Map<String, dynamic>>.from(response);
      });
    } else {
      print('Error fetching announcements: No data found');
    }
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildGreetingSection(fullName, formattedLastLogin),
            _buildAnnouncementsSection(),
            _buildCampusInfoSection(),
          ],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    height: 30, // Height of the vertical line
                    width: 3, // Width of the vertical line
                    color: const Color(0xFF2e3192), // Color of the line
                  ),
                  const SizedBox(width: 10), // Space between the line and text
                  const Text(
                    'RECENT ANNOUNCEMENTS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          // Display the announcements using ListView.builder
          if (announcements.isNotEmpty)
            ListView.builder(
              shrinkWrap: true, // To avoid overflow
              physics: NeverScrollableScrollPhysics(), // Disable scrolling
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                final title = announcement['title'] ?? '';
                final imageUrls = announcement['event_images'] != null &&
                        announcement['event_images'].isNotEmpty
                    ? List<String>.from(
                        announcement['event_images'][0]['image_url'])
                    : [];

                // Get the first URL if available
                final photoUrl = imageUrls.isNotEmpty ? imageUrls.first : '';
                final date_created = announcement['date_created'] != null
                    ? DateTime.parse(announcement['date_created']).toLocal()
                    : null;

                if (date_created != null) {
                  return _buildAnnouncementCard(
                      title, photoUrl, date_created, announcement['id']);
                } else {
                  return const SizedBox
                      .shrink(); // Return an empty widget if date_created is null
                }
              },
            )
          else
            const Text('No announcements available'), // Fallback if no data
        ],
      ),
    );
  }

  // Helper for Announcement Card
  Widget _buildAnnouncementCard(
      String title, String photoUrl, DateTime postedTime, int eventId) {
    // Format the posted time as "DD Mon YYYY HH:MM AM/PM"
    final formattedPostedTime =
        '${postedTime.day} ${_getMonthName(postedTime.month)} ${postedTime.year} ${_formatTime(postedTime)}';

    return Card(
      child: ListTile(
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
                  // Display a placeholder if the image fails to load
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
          ), // Ensure it adds an ellipsis if needed
        ),
        subtitle: Text(
          formattedPostedTime,
          style: TextStyle(fontSize: 11),
        ),
        trailing: TextButton(
          onPressed: () {
            // Navigate to item.dart with the eventId
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemPage(eventId: eventId),
              ),
            );
          },
          child: const Text(
            'View',
            style: TextStyle(color: Colors.blue),
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
