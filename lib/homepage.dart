import 'package:flutter/material.dart';
import 'main.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final profileImageUrl = user?.userMetadata?['avatar_url'];
    final fullName = user?.userMetadata?['full_name'];
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildGreetingSection(fullName),
            _buildAnnouncementsSection(),
            _buildCampusInfoSection(),
          ],
        ),
      ),
    );
  }

  // Greeting Section
  Widget _buildGreetingSection(String? fullName) {
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0, bottom: 20.0),
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
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          SizedBox(height: 8),
          Text(
            'Your last login was 13 Jun 2024 03:32 PM',
            style: TextStyle(color: Colors.white70, fontSize: 14),
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
        SizedBox(height: 5),
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
              Text(
                'RECENT ANNOUNCEMENTS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: Text('View All'),
              ),
            ],
          ),
          SizedBox(height: 10),
          _buildAnnouncementCard(
              'Ceremonial turn-over of ICT', 'view', '38m ago'),
          _buildAnnouncementCard('2024 Sport Fest', 'view', '1h ago'),
        ],
      ),
    );
  }

  // Helper for Announcement Card
  Widget _buildAnnouncementCard(String title, String type, String time) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.announcement, color: Colors.green),
        title: Text(title),
        subtitle: Text(time),
        trailing: Text(
          type,
          style: TextStyle(color: Colors.blue),
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
          Text(
            'CAMPUS INFORMATION',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCampusInfoCard('Mission', Color(0xFF2E3192)),
              _buildCampusInfoCard('Quality Policy', Color(0xFF2E3192)),
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
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
