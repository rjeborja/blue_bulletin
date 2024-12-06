import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'main.dart';

class ItemPage extends StatefulWidget {
  final int eventId;

  const ItemPage({Key? key, required this.eventId}) : super(key: key);

  @override
  _ItemPageState createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  Map<String, dynamic>? eventDetails;
  List<String> imageUrls = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEventDetails();
  }

  Future<void> fetchEventDetails() async {
    final response = await supabase
        .from('events')
        .select('title, description, location, event_date')
        .eq('id', widget.eventId)
        .single();

    if (response != null) {
      eventDetails = response;
      final imageResponse = await supabase
          .from('event_images')
          .select('image_url')
          .eq('event_id', widget.eventId)
          .single();

      if (imageResponse != null) {
        List<dynamic> images = List.from(imageResponse['image_url']);
        setState(() {
          imageUrls = images.map((e) => e.toString()).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Event Details',
              style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF2e3192),
        ),
        body: Center(child: const CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Event Details', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2e3192),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Event details section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventDetails?['title'] ?? 'No Title',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 15,
                        color: Color(0xFF808080),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        eventDetails?['location'] ?? 'No Location',
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF808080)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.calendar_today,
                          size: 15, color: Color(0xFF808080)),
                      const SizedBox(width: 4),
                      Text(
                        eventDetails?['event_date'] ?? 'Not Available',
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF808080)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            // Carousel section
            if (imageUrls.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(
                  autoPlay: true,
                  enlargeCenterPage: true,
                  aspectRatio: 16 / 9,
                  viewportFraction: 0.8,
                ),
                items: imageUrls.map((url) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        child: Image.network(url, fit: BoxFit.fitHeight),
                      );
                    },
                  );
                }).toList(),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    eventDetails?['description'] ?? 'No Description',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
