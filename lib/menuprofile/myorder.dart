import 'package:flutter/material.dart';

class MyOrderPage extends StatelessWidget {
  const MyOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> activeOrders = [
      {
        "id": "ORD-2567-005",
        "item_name": "Shark Costume (Size L)",
        "price": "฿490",
        "quantity": 1,
        "status": "On The Way", 
        "current_step": 2,      
        "eta": "29 Jan 2026",   
      },
      {
        "id": "ORD-2567-008",
        "item_name": "Cat Nip Toy Set",
        "price": "฿150",
        "quantity": 2,
        "status": "Packing",
        "current_step": 1,
        "eta": "31 Jan 2026",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "My Orders",
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
      body: activeOrders.isEmpty
          ? _buildEmptyState() 
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: activeOrders.length,
              itemBuilder: (context, index) {
                return _buildActiveOrderCard(activeOrders[index]);
              },
            ),
    );
  }

  // Widget: ถ้าไม่มีคำสั่งซื้อ
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text("No active orders", style: TextStyle(color: Colors.grey, fontSize: 18)),
        ],
      ),
    );
  }

  // Widget: การ์ดสินค้าแต่ละใบ
  Widget _buildActiveOrderCard(Map<String, dynamic> order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            // 1. Header: Order ID & ETA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order ${order['id']}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  "Est. Arrival: ${order['eta']}",
                  style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 25),

            // 2. Product Info
            Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.checkroom, color: Colors.grey, size: 35),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['item_name'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text("Qty: ${order['quantity']} • ${order['price']}", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // 3. Status Timeline (ส่วนสำคัญ!)
            _buildTimeline(order['current_step']),

            const SizedBox(height: 25),

            // 4. Track Button
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text("Track Order", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget: สร้างเส้น Timeline (Confirmed -> Shipped -> Delivery)
  Widget _buildTimeline(int currentStep) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStep(Icons.inventory_2_outlined, "Packed", currentStep >= 1, isFirst: true),
        _buildLine(currentStep >= 2),
        _buildStep(Icons.local_shipping_outlined, "Shipping", currentStep >= 2),
        _buildLine(currentStep >= 3),
        _buildStep(Icons.home_outlined, "Delivered", currentStep >= 3, isLast: true),
      ],
    );
  }

  Widget _buildStep(IconData icon, String label, bool isActive, {bool isFirst = false, bool isLast = false}) {
    Color color = isActive ? Colors.blue : Colors.grey.shade300;
    Color textColor = isActive ? Colors.black : Colors.grey;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue.shade50 : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: textColor, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
        )
      ],
    );
  }

  Widget _buildLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Colors.blue : Colors.grey.shade300,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 15), 
      ),
    );
  }
}