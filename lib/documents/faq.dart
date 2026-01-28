import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "FAQ",
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
              "How can we help you?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Here are the most frequently asked questions about Purrfect Fit.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // รายการคำถาม-คำตอบ
            _buildFAQItem(
              "How does the AI Sizing work?",
              "Our AI analyzes the photo of your cat to estimate body measurements (chest, neck, length). It then matches these data with our clothing database to recommend the best size.",
            ),
            _buildFAQItem(
              "How accurate is the size recommendation?",
              "It is about 95% accurate. However, we always recommend checking the specific size chart provided on the product page as fabric elasticity varies.",
            ),
            _buildFAQItem(
              "Can I return the product if it doesn't fit?",
              "Yes! You can return or exchange items within 7 days of receiving them, provided they are unwashed and in original condition.",
            ),
            _buildFAQItem(
              "How long does shipping take?",
              "Standard shipping takes 3-5 business days. Express shipping takes 1-2 business days.",
            ),
            _buildFAQItem(
              "Do you ship internationally?",
              "Currently, we only ship within Thailand. International shipping will be available soon!",
            ),
            _buildFAQItem(
              "How do I track my order?",
              "Go to 'My Orders' in your profile menu. You will see the tracking number once your order has been shipped.",
            ),

            const SizedBox(height: 30),
            // ปุ่มติดต่อ Support กรณีหาคำตอบไม่เจอ
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.headset_mic, color: Colors.blueAccent),
                  const SizedBox(width: 15),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Still have questions?", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("Contact our support team", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget สร้างกล่องคำถามแบบยืดหดได้
  Widget _buildFAQItem(String question, String answer) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: const Color.fromARGB(255, 255, 255, 255)),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15 ,color: Colors.black87),
          
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            answer,
            style: const TextStyle(color: Colors.black54, height: 1.5),
          ),
        ],
      ),
    );
  }
}

