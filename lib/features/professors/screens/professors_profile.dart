import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eduguide/features/rating_professors/rating_service.dart';
import 'package:eduguide/features/widgets/professor_status_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eduguide/features/services/email_service.dart';

// --- Constants ---
const Color primaryBlue = Color(0xFF407BFF);
const Color lightBackground = Color(0xFFF7F7FD);
const Color cardBackground = Colors.white;
const Color iconGray = Color(0xFF8A8A8E);
const Color textSubtle = Color(0xFF6E6E73);
const Color textBody = Color(0xFF1D1D1F);

class ProfessorDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const ProfessorDetailPage({required this.data, super.key});

  @override
  State<ProfessorDetailPage> createState() => _ProfessorDetailPageState();
}

class _ProfessorDetailPageState extends State<ProfessorDetailPage> {
  int selectedDay = 0;
  int selectedRating = 0;
  final RatingService _ratingService = RatingService();

  static const List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  /// TEMP user id (replace with FirebaseAuth uid later)
  final String currentUserId = "TEST_USER_1";

  // ---------------- URL LAUNCH ----------------
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ---------------- GET USER DATA FROM FIRESTORE ----------------
  Future<Map<String, dynamic>?> _getUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // ---------------- BOOK SESSION ----------------
  Future<void> _bookSession() async {
    try {
      final professorId = widget.data['id'];
      final professorName = widget.data['name'] ?? 'Professor';
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to book a session")),
        );
        return;
      }

      // Get user data from Firestore to get the actual name
      final userData = await _getUserData();
      final studentName =
          userData?['name'] ??
          currentUser.displayName ??
          currentUser.email?.split('@')[0] ??
          'Student';

      // Send notification to professor
      await FirebaseFirestore.instance.collection('notifications').add({
        'professorId': professorId,
        'studentId': currentUser.uid,
        'studentName': studentName,
        'studentEmail': currentUser.email,
        'professorEmail': 'sahil253636@gmail.com', // Test email for professor
        'message': 'Student wants to meet you',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': 'session_request',
      });

      // Send actual email
      await _sendEmailToProfessor(
        professorEmail: 'sahil253636@gmail.com',
        studentName: studentName,
        studentEmail: currentUser.email ?? 'No email provided',
        professorName: professorName,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Session request sent to $professorName"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error booking session: $e")));
    }
  }

  // ---------------- SEND EMAIL ----------------
  Future<void> _sendEmailToProfessor({
    required String professorEmail,
    required String studentName,
    required String studentEmail,
    required String professorName,
  }) async {
    try {
      final subject = "Session Request from Student";
      final body =
          '''
Dear Professor $professorName,

A student has requested to meet with you:

Student Name: $studentName
Student Email: $studentEmail
Message: Student wants to meet you

Please check your notifications in the EduGuide app for more details.

Best regards,
EduGuide Team
      ''';

      // Send email directly using EmailService
      final success = await EmailService.sendSessionRequestEmail(
        toEmail: '211822@kit.ac.in',
        professorName: professorName,
        studentName: studentName,
        studentEmail: studentEmail,
        messageContent: body,
      );

      if (success) {
        print("Email sent successfully to $professorEmail");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email sent successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print("Failed to send email to $professorEmail");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to send email, but notification was saved"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print("Error sending email: $e");
      // Continue even if email fails - notification is saved in Firestore
    }
  }

  // ---------------- SUBMIT RATING ----------------
  Future<void> _submitRating(int rating) async {
    try {
      final professorId = widget.data['id'];
      final studentId = currentUserId;

      // Check if user already rated
      final hasRated = await _ratingService.hasUserRated(
        professorId,
        studentId,
      );
      if (hasRated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You have already rated this professor"),
          ),
        );
        return;
      }

      await _ratingService.submitRating(
        professorId: professorId,
        studentId: studentId,
        rating: rating,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Rating submitted")));

      setState(() => selectedRating = 0);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error submitting rating: $e")));
    }
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    final availabilityMap =
        widget.data['availability'] as Map<String, dynamic>? ?? {};

    final availableDays = weekDays
        .where((d) => availabilityMap.containsKey(d))
        .toList();

    if (selectedDay >= availableDays.length && availableDays.isNotEmpty) {
      selectedDay = 0;
    }

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        title: Text(
          widget.data['name'] ?? 'Professor',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 16),

          _buildRatingSection(),
          const SizedBox(height: 24),

          _buildInfoCard(
            title: "Qualifications",
            icon: Icons.school_rounded,
            children: (widget.data['qualifications'] as List<dynamic>? ?? [])
                .map((e) => _buildListItem(e.toString()))
                .toList(),
          ),

          _buildInfoCard(
            title: "Research Areas",
            icon: Icons.science_rounded,
            children: (widget.data['research'] as List<dynamic>? ?? [])
                .map((e) => _buildListItem(e.toString()))
                .toList(),
          ),

          _buildInfoCard(
            title: "Research Papers",
            icon: Icons.article_rounded,
            children: (widget.data['research_papers'] as List<dynamic>? ?? [])
                .map((paper) {
                  final String title = paper['title'] ?? 'Untitled';
                  final String? link = paper['link'];
                  return _buildListItem(
                    title,
                    isLink: link != null,
                    onTap: link != null ? () => _launchURL(link) : null,
                  );
                })
                .toList(),
          ),

          _buildInfoCard(
            title: "Contact",
            icon: Icons.contact_mail_rounded,
            children: [
              _contactRow(
                Icons.email_outlined,
                widget.data['contact']?['email'] ?? 'N/A',
              ),
              _contactRow(
                Icons.phone_outlined,
                widget.data['contact']?['phone'] ?? 'N/A',
              ),
              _contactRow(
                Icons.location_on_outlined,
                widget.data['office'] ?? 'N/A',
              ),
            ],
          ),

          _buildInfoCard(
            title: "Weekly Availability",
            icon: Icons.calendar_today_rounded,
            children: [
              if (availableDays.isEmpty)
                const Text("Availability not provided")
              else ...[
                // Day selector buttons - show only available days
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: availableDays.asMap().entries.map((entry) {
                      final index = entry.key;
                      final day = entry.value;
                      final isSelected = selectedDay == index;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => selectedDay = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryBlue : lightBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? primaryBlue
                                    : primaryBlue.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              day,
                              style: TextStyle(
                                color: isSelected ? Colors.white : textBody,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                // Selected day's availability
                Builder(
                  builder: (context) {
                    final selectedDayName = availableDays[selectedDay];
                    final availability =
                        availabilityMap[selectedDayName] ?? 'Not Available';

                    return Text(
                      "$selectedDayName: $availability",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textBody,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- STATUS BADGE (UPDATED) ----------------
  Widget _statusBadge() {
    final availability =
        widget.data['availability'] as Map<String, dynamic>? ?? {};

    final result = ProfessorStatusHelper.calculate(availability);

    // Don't show any badge outside college hours (before 9AM or after 5PM)
    if (result.status == ProfessorStatus.outsideCollegeHours) {
      return const SizedBox.shrink();
    }

    Color color;
    String text;

    switch (result.status) {
      case ProfessorStatus.inCabin:
        color = Colors.green;
        text = "IN CABIN";
        break;
      case ProfessorStatus.busy:
        color = Colors.orange;
        text = result.nextAvailableIn != null
            ? "BUSY • Available in ${result.nextAvailableIn!.inMinutes} min"
            : "BUSY";
        break;
      default:
        color = Colors.red;
        text = "ABSENT";
    }

    return _badge(text, color);
  }

  Widget _badge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ---------------- RATING SECTION ----------------
  Widget _buildRatingSection() {
    final professorId = widget.data['id'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Rate this Professor",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textBody,
            ),
          ),
          const SizedBox(height: 12),

          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rating_summary')
                .doc(professorId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Text("No ratings yet");
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final avg = (data['avgRating'] ?? 0).toDouble();
              final count = data['ratingCount'] ?? 0;

              return Text(
                "⭐ ${avg.toStringAsFixed(1)} ($count reviews)",
                style: const TextStyle(fontSize: 16, color: textSubtle),
              );
            },
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  i < selectedRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 28,
                ),
                onPressed: () => setState(() => selectedRating = i + 1),
              );
            }),
          ),

          const SizedBox(height: 16),

          FutureBuilder<bool>(
            future: _ratingService.hasUserRated(professorId, currentUserId),
            builder: (context, snapshot) {
              final hasRated = snapshot.data ?? false;

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (selectedRating == 0 || hasRated)
                      ? null
                      : () => _submitRating(selectedRating),
                  child: Text(hasRated ? "Already Rated" : "Submit Rating"),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------- PROFILE HEADER (UNCHANGED + BADGE) ----------------
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: primaryBlue.withOpacity(0.1),
            backgroundImage:
                (widget.data['image'] != null &&
                    widget.data['image'].toString().isNotEmpty)
                ? NetworkImage(widget.data['image'])
                : null,
            child:
                (widget.data['image'] == null ||
                    widget.data['image'].toString().isEmpty)
                ? const Icon(Icons.person, size: 36, color: primaryBlue)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.data['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.data['specializations'] != null)
                  Text(
                    (widget.data['specializations'] as List).join(', '),
                    style: const TextStyle(color: textSubtle),
                  ),

                // ✅ STATUS BADGE (TOP, NO SCROLL)
                _statusBadge(),

                const SizedBox(height: 12),

                // 📅 BOOK SESSION BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _bookSession,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text("Book Session"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- HELPERS ----------------
  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    // Always show the card, even if children is empty
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListItem(
    String text, {
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            color: isLink ? primaryBlue : textSubtle,
            decoration: isLink ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: iconGray),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: const TextStyle(color: textSubtle)),
          ),
        ],
      ),
    );
  }
}
