import 'package:flutter/material.dart';

class HowToUsePage extends StatelessWidget {
  const HowToUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "How to Use",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Get the Purrfect Fit in 3 Steps",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Follow these simple steps to use our AI Smart Sizing feature correctly.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 30),

            // --- STEP 1 ---
            _buildStepCard(
              step: "1",
              title: "Prepare Your Cat",
              description: "Place your cat on a flat surface. Make sure there is good lighting and no clutter in the background.",
              icon: Icons.pets,
              color: Colors.orange.shade100,
              iconColor: Colors.orange,
            ),

            // --- STEP 2 ---
            _buildStepCard(
              step: "2",
              title: "Take a Side Photo",
              description: "Position the camera at your cat's eye level. Capture the full side profile (head to tail) for the best accuracy.",
              icon: Icons.camera_alt_rounded,
              color: Colors.blue.shade100,
              iconColor: Colors.blue,
            ),

            // --- STEP 3 ---
            _buildStepCard(
              step: "3",
              title: "Get Size & Shop",
              description: "Wait a few seconds for our AI to analyze the photo. We will recommend the perfect size for your furry friend!",
              icon: Icons.checkroom_rounded,
              color: Colors.green.shade100,
              iconColor: Colors.green,
            ),

            const Divider(height: 40),

            // --- TIPS Section ---
            const Text(
              "Pro Tips for Best Results",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildTip(Icons.check_circle, Colors.green, "Use bright, natural lighting."),
            _buildTip(Icons.check_circle, Colors.green, "Keep the camera steady."),
            _buildTip(Icons.cancel, Colors.red, "Avoid dark or blurry photos."),
            _buildTip(Icons.cancel, Colors.red, "Do not hide the cat's legs or tail."),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Helper Widget สร้างการ์ดขั้นตอน (Card)
  Widget _buildStepCard({
    required String step,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ส่วน Icon ด้านซ้าย
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 15),
          // ส่วนเนื้อหา
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "STEP $step",
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget สร้างรายการ Tips
  Widget _buildTip(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 15, color: Colors.black87)),
        ],
      ),
    );
  }
}
