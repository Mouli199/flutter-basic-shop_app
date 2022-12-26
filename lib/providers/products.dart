import 'dart:convert';
// import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../models/http_exception.dart';
import './product.dart';


class Products with ChangeNotifier {
  List<Product> _items = [
    Product(
        id: 'p1',
        title: 'Shirt',
        description: 'A sky blue color shirt - it is awesome',
        price: 599.99,
        imageUrl:
            "https://i.pinimg.com/564x/d8/ef/db/d8efdb351951b7432974d9f91053dbc8.jpg"),
    Product(
        id: 'p2',
        title: 'Brown Shirt',
        description: 'A checked brown shirt - it is pretty straps',
        price: 790.00,
        imageUrl:
            'https://i.pinimg.com/564x/3d/b3/bf/3db3bfe75fcabf1f5f7607fef8ec9776.jpg'),
    Product(
        id: 'p3',
        title: 'Gravy Shirt',
        description: 'A gray shirt',
        price: 399,
        imageUrl:
            'https://i.pinimg.com/564x/23/7e/1d/237e1dab8d7f85e64210bb2eb90af615.jpg'),
  ];

  //var _showFavoritesOnly = false;
  final String authToken;
  final String userId;

  Products(this.authToken, this.userId ,this._items);

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favouriteItems {
    return _items.where((prodItem) => prodItem.isFavourite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    final filterString = filterByUser ? 'order"creatorId"&equalTo="$userId"' : '';
    var url = Uri.parse(
        'https://flutter-update-9258d-default-rtdb.firebaseio.com/products.json?auth=$authToken&$filterString');
    //const url = 'https://flutter-update-9258d-default-rtdb.firebaseio.com/products.json';
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      }
      url = Uri.parse(
          'https://flutter-update-9258d-default-rtdb.firebaseio.com/userFavorites/$userId.json?auth=$authToken');
      final favoriteResponse = await http.get(url);
      final favoriteData = json.decode(favoriteResponse.body);
      final List<Product> loadedProducts = [];
      extractedData.forEach((prodId, prodData) {
        loadedProducts.add(Product(
            id: prodId,
            title: prodData['title'],
            description: prodData['description'],
            price: prodData['price'],
            imageUrl: prodData['imageUrl'],
            isFavourite: favoriteData == null ? false : favoriteData[prodId] ?? false,
        ));
      });
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> addProduct(Product product) async {
    print("Add product Called");
    final url = Uri.parse(
        'https://flutter-update-9258d-default-rtdb.firebaseio.com/products.json?auth=$authToken');

    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'isFavorite': product.isFavourite,
          'creatorId': userId,
        }),
      );
      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: json.decode(response.body)['name'],
      );
      _items.add(newProduct);
      //_items.insert(0, newProduct); //at the start of the list
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }

    //print(json.decode(response.body));
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      final url = Uri.parse('https://flutter-update-9258d-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken');
      await http.patch(url, body: json.encode({
        'title': newProduct.title,
        'price': newProduct.price,
        'description': newProduct.description,
        'imageUrl': newProduct.imageUrl,
      }) );
      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {
      print('...');
    }
  }

  Future <void> deleteProduct(String id) async {
    final url = Uri.parse('https://flutter-update-9258d-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken');
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    Product? existingProduct = _items[existingProductIndex];
    _items.removeAt(existingProductIndex);
    notifyListeners();
    //_items.removeWhere((prod) => prod.id == id);

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
        throw HttpException('Could not delete product.');
      }
      existingProduct = null;




  }
}
