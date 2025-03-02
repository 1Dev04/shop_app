class Cats {
  String message;
  String status;

  Cats({required this.message, required this.status});

  Cats.fromJson(Map<String, dynamic> json)
      : message = json['message'],
        status = json['status'];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    data['status'] = this.status;
    return data;
  }
}
/*
class Products {
  int id;
  String title;
  double price;
  String image;

  Products({
    required this.id,
    required this.title,
    required this.price,
    required this.image,
  });
  
  Products.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        price = json['price'],
        image = json['image'];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['price'] = this.price;
    data['image'] = this.image;
    return data;
  }
}
*/

class Carts {
  int? id;
  int? userId;
  String? date;
  int? iV;

  Carts({this.id, this.userId, this.date, this.iV});

  Carts.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    date = json['date'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['userId'] = this.userId;
    data['date'] = this.date;
    data['__v'] = this.iV;
   
    return data;
  }
}
