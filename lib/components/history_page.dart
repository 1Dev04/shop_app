import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> orders = [
      {
        "id": "ORD-2567-001",
        "date": "28 Jan 2024, 10:30 AM",
        "status": "Shipping",
        "items": "Cat Hoodie (Blue) x 1",
        "total": "฿350",
        "image": Icons.checkroom, 
      },
      {
        "id": "ORD-2567-002",
        "date": "15 Jan 2024, 14:20 PM",
        "status": "Completed",
        "items": "Cute Bowtie (Red) x 2",
        "total": "฿120",
        "image": Icons.pets,
      },
      {
        "id": "ORD-2566-099",
        "date": "20 Dec 2023, 09:15 AM",
        "status": "Cancelled",
        "items": "Summer Shirt (S) x 1",
        "total": "฿200",
        "image": Icons.shopping_bag,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), 
      appBar: AppBar(
        title: const Text(
          "History",
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
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(context, order);
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    Color statusColor;
    String btnText;
    Color btnColor;
    VoidCallback? onBtnPress;

    // กำหนดสีและปุ่มตามสถานะ
    switch (order['status']) {
      case 'Shipping':
        statusColor = Colors.orange;
        btnText = "Track Order";
        btnColor = Colors.black87;
        onBtnPress = () {};
        break;
      case 'Completed':
        statusColor = Colors.green;
        btnText = "Rate & Review";
        btnColor = Colors.blue;
        onBtnPress = () {};
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        btnText = "Buy Again";
        btnColor = Colors.grey;
        onBtnPress = () {};
        break;
      default:
        statusColor = Colors.grey;
        btnText = "View Details";
        btnColor = Colors.black;
        onBtnPress = () {};
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            // --- HEADER: Date & Status ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order['date'],
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order['status'],
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 25),

            // --- BODY: Image & Info ---
            Row(
              children: [
                // รูปสินค้า (Mockup)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(order['image'], color: Colors.grey[400], size: 30),
                ),
                const SizedBox(width: 15),
                // รายละเอียด
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['items'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Order ID: ${order['id']}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // --- FOOTER: Price & Action ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Payment", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      order['total'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: onBtnPress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Text(
                    btnText,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
