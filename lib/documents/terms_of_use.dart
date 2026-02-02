import 'package:flutter/material.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Terms of Use",
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
              "Last updated: January 2024",
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            const Text(
              "Please read these Terms of Use carefully before using the Purrfect Fit application.",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const Divider(height: 40),

            _buildSectionTitle("1. Agreement to Terms"),
            _buildSectionContent(
              "By accessing or using our application, you agree to be bound by these Terms. If you disagree with any part of the terms, you may not use our services.",
            ),

            _buildSectionTitle("2. User Accounts"),
            _buildSectionContent(
              "When you create an account with us, you must provide accurate and complete information. You are responsible for safeguarding the password that you use to access the service.",
            ),

            // ข้อนี้สำคัญมากสำหรับแอปวัดไซซ์เสื้อ
            _buildSectionTitle("3. AI Sizing Recommendations"),
            _buildSectionContent(
              "Our AI Smart Sizing tool provides size recommendations based on the photos or data you submit. While we strive for high accuracy, these are estimates. We recommend checking the specific size chart for each product before purchasing.",
            ),

            _buildSectionTitle("4. Purchases and Payments"),
            _buildSectionContent(
              "If you wish to purchase any product, you may be asked to supply certain information relevant to your purchase including your credit card number, billing address, and shipping information.",
            ),

            _buildSectionTitle("5. Intellectual Property"),
            _buildSectionContent(
              "The service and its original content (excluding content provided by users), features, and functionality are and will remain the exclusive property of Purrfect Fit and its licensors.",
            ),

            _buildSectionTitle("6. Changes to Terms"),
            _buildSectionContent(
              "We reserve the right to modify or replace these Terms at any time. We will try to provide at least 30 days' notice prior to any new terms taking effect.",
            ),

            _buildSectionTitle("7. Contact Us"),
            _buildSectionContent(
              "If you have any questions about these Terms, please contact us at support@purrfectfit.com",
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Widget ช่วยสร้างหัวข้อ
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

  // Widget ช่วยสร้างเนื้อหา
  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black54,
          height: 1.6,
        ),
      ),
    );
  }
}