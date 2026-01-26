import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/Language_Provider.dart';

import 'package:flutter_application_1/provider/Theme_Provider.dart';
import 'package:provider/provider.dart';

class Basket extends StatefulWidget {
  const Basket({super.key});

  @override
  State<Basket> createState() => _BasketState();
}

class _BasketState extends State<Basket> {


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(languageProvider.translate(
            en: 'BASKET',
            th: 'ตะกร้า'),
          style: TextStyle(
            fontFamily: "catFont",
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDark ? Colors.black : Colors.white,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      body: Column(
        children: [
          // ส่วนเนื้อหาหลัก (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildEmptyState(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 1️⃣ หน้าจอเปล่า (Default - ยังไม่มีรูป)
  Widget _buildEmptyState(bool isDark) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(height: 150),
          Center(
          
    
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pets,
                  size: 80,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                    languageProvider.translate(
                        en: 'Your basket is empty',
                        th: 'ตะกร้าของคุณว่างอยู่'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                // SizedBox(height: 8),
                // Text(
                //   'ตะกร้าของคุณว่างพูด',
                //   style: TextStyle(
                //     fontSize: 14,
                //     color: isDark ? Colors.grey[500] : Colors.grey[500],
                //   ),
                // ),
              ],
            ),
          
          )
          
        ],
      ),
    );
  }
}
