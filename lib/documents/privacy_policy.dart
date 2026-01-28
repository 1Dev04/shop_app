import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // กำหนดวันที่อัปเดตล่าสุด
    final String lastUpdated = "Last updated: January 2024";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Privacy Policy",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.white, // หรือสี Theme ของคุณ
        elevation: 0,
        foregroundColor: Colors.black, // สีของไอคอนและข้อความ
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนเกริ่นนำ
            Text(
              lastUpdated,
              style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            const Text(
              "Welcome to Purrfect Fit. We value the privacy of our customers and their pets. This Privacy Policy explains how we collect, use, and protect your information.",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const Divider(height: 40),

            // 1. ข้อมูลที่เราเก็บ
            _buildSectionTitle("1. Information We Collect"),
            _buildSectionContent(
              "We collect information to provide better services, including:\n"
              "• Personal Account Info: Name, email address, and shipping address.\n"
              "• Pet Information: Breed, weight, and photos of your cat for our AI Sizing System.\n"
              "• Transaction Data: Purchase history and payment details (processed securely via third-party providers).",
            ),

            // 2. การใช้งานระบบ AI (สำคัญสำหรับโปรเจกต์คุณ)
            _buildSectionTitle("2. AI Smart Sizing Data"),
            _buildSectionContent(
              "Our application uses Artificial Intelligence (AI) to recommend clothing sizes. "
              "Photos or measurements of your pet are used solely for processing size recommendations. "
              "We do not share these images with third parties without your explicit consent.",
            ),

            // 3. การใช้งานข้อมูล
            _buildSectionTitle("3. How We Use Your Information"),
            _buildSectionContent(
              "• To process and deliver your orders.\n"
              "• To improve our AI algorithms for better accuracy.\n"
              "• To communicate with you regarding updates, offers, and support.",
            ),

            // 4. ความปลอดภัย
            _buildSectionTitle("4. Data Security"),
            _buildSectionContent(
              "We implement industry-standard security measures to protect your personal data against unauthorized access, alteration, or destruction.",
            ),

            // 5. ติดต่อเรา
            _buildSectionTitle("5. Contact Us"),
            _buildSectionContent(
              "If you have any questions about this Privacy Policy, please contact us at:\n\n"
              "Email: support@purrfectfit.com\n"
              "Phone: +66 2 123 4567",
            ),
            
            const SizedBox(height: 40),
            // ปุ่มกดยอมรับ (ถ้าต้องการ)
            Center(
              child: Text(
                "By using our app, you agree to the terms of this policy.",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper Widget สำหรับสร้างหัวข้อ (จะได้ไม่ต้องเขียนซ้ำ)
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // Helper Widget สำหรับสร้างเนื้อหา
  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black54,
          height: 1.6, // ระยะห่างระหว่างบรรทัดให้อ่านง่าย
        ),
      ),
    );
  }
}