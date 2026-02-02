import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 

class MyCouponPage extends StatelessWidget {
  const MyCouponPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> coupons = [
      {
        "code": "WELCOME2024",
        "title": "ส่วนลดต้อนรับลูกค้าใหม่",
        "amount": "15%",
        "type": "Discount",
        "min_spend": "ไม่มีขั้นต่ำ",
        "expiry": "31 Dec 2026",
        "status": "Available", 
      },
      {
        "code": "FREESHIP",
        "title": "ส่งฟรีทั่วไทย",
        "amount": "Free",
        "type": "Shipping",
        "min_spend": "ขั้นต่ำ ฿300",
        "expiry": "28 Feb 2026",
        "status": "Available",
      },
      {
        "code": "CATLOVER",
        "title": "ส่วนลดอาหารแมว",
        "amount": "฿50",
        "type": "Discount",
        "min_spend": "ขั้นต่ำ ฿500",
        "expiry": "10 Jan 2024",
        "status": "Used",
      },
      {
        "code": "EXPIRED99",
        "title": "โปรโมชั่นปีใหม่",
        "amount": "฿100",
        "type": "Discount",
        "min_spend": "ขั้นต่ำ ฿1000",
        "expiry": "01 Jan 2023",
        "status": "Expired",
      },
    ];

    // สีพื้นหลังตาม Theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFF5F5F5);

    return DefaultTabController(
      length: 3, // จำนวน Tab
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text("My Coupons", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            indicatorColor: isDark ? Colors.white : Colors.black,
            labelColor: isDark ? Colors.white : Colors.black,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Available"),
              Tab(text: "Used"),
              Tab(text: "Expired"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCouponList(context, coupons, "Available"),
            _buildCouponList(context, coupons, "Used"),
            _buildCouponList(context, coupons, "Expired"),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponList(BuildContext context, List<Map<String, dynamic>> allCoupons, String status) {
    final filteredCoupons = allCoupons.where((c) => c['status'] == status).toList();

    if (filteredCoupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.discount_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text("No $status coupons", style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: filteredCoupons.length,
      itemBuilder: (context, index) {
        return _buildTicketCard(context, filteredCoupons[index]);
      },
    );
  }

  Widget _buildTicketCard(BuildContext context, Map<String, dynamic> coupon) {
    bool isAvailable = coupon['status'] == 'Available';
    Color mainColor = isAvailable ? Colors.orange : Colors.grey;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      height: 120,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  coupon['amount'],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                  ),
                ),
                Text(
                  coupon['type'] == 'Shipping' ? "Off" : "Discount",
                  style: TextStyle(fontSize: 12, color: mainColor),
                ),
              ],
            ),
          ),

          SizedBox(
            height: double.infinity,
            child: CustomPaint(
              size: const Size(1, double.infinity),
              painter: DashedLinePainter(color: Colors.grey.shade300),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "${coupon['min_spend']} • Exp: ${coupon['expiry']}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isAvailable)
                        InkWell(
                          onTap: () {
                             Clipboard.setData(ClipboardData(text: coupon['code']));
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text("Copied ${coupon['code']}")),
                             );
                          },
                          child: Text(
                            "Use Now >",
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 13
                            ),
                          ),
                        )
                      else
                        Text(
                          coupon['status'],
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 0;
    final paint = Paint()..color = color..strokeWidth = 1;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}