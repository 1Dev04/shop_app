/*

import 'dart:convert';

import 'package:flutter_application_1/model2.dart';
import 'package:http/http.dart' as http;

/*
class CatApi {
  Future getCats() async {
    Cats randomCat;
    var respone =
        await http.get(Uri.https('dog.ceo', 'api/breeds/image/random'));

    if (respone.statusCode == 200) {
      var jsonData = jsonDecode(respone.body);
      randomCat = Cats.fromJson(jsonData);
    } else {
      throw Exception('Failed to load data');
    }

    return randomCat;
  }
}

*/

/*

class ProductAPI {
  Future getProducts() async {
    List productList = [];
    var response1 = await http.get(Uri.https('fakestoreapi.com', 'products'));

    if (response1.statusCode == 200) {
      var jsonData = jsonDecode(response1.body);
      for (var data in jsonData) {
        final product = Products(
            id: data['id'],
            title: data['title'],
            price: data['price'],
            image: data['image']);

        productList.add(product);
      }
    } else {
      throw Exception('Failed to load data');
    }

    return productList;
  }
}
*/

class CartAPI {
  Future getCart() async {
    List cartList = [];
    var response1 = await http.get(Uri.https('fakestoreapi.com', 'carts'));

    if (response1.statusCode == 200) {
      var jsonData = jsonDecode(response1.body);
      for (var data in jsonData) {
        final cart = Carts(
          id: data['id'],
          userId: data['userId'],
          date: data['date'],
          iV: data['__v']
        );
        
        cartList.add(cart);
        
      }
    } else {
      throw Exception('Failed to load data');
    }

    return cartList;
  }
}
*/