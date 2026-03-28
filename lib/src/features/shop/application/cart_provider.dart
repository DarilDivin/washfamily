import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/order_model.dart';
import '../domain/models/product_model.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<OrderItemModel>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<OrderItemModel>> {
  CartNotifier() : super([]);

  void addProduct(ProductModel product, {int quantity = 1}) {
    // Check if product is already in cart
    final existingIndex = state.indexWhere((item) => item.productId == product.id);
    if (existingIndex >= 0) {
      final existingItem = state[existingIndex];
      // Create new list
      final newState = [...state];
      // Update item
      newState[existingIndex] = OrderItemModel(
        productId: existingItem.productId,
        name: existingItem.name,
        quantity: existingItem.quantity + quantity,
        priceAtPurchase: existingItem.priceAtPurchase,
      );
      state = newState;
    } else {
      // Add new item
      state = [
        ...state,
        OrderItemModel(
          productId: product.id,
          name: product.name,
          quantity: quantity,
          priceAtPurchase: product.price,
        ),
      ];
    }
  }

  void removeProduct(String productId) {
    state = state.where((item) => item.productId != productId).toList();
  }

  void decrementQuantity(String productId) {
    final existingIndex = state.indexWhere((item) => item.productId == productId);
    if (existingIndex >= 0) {
      final existingItem = state[existingIndex];
      if (existingItem.quantity > 1) {
        final newState = [...state];
        newState[existingIndex] = OrderItemModel(
          productId: existingItem.productId,
          name: existingItem.name,
          quantity: existingItem.quantity - 1,
          priceAtPurchase: existingItem.priceAtPurchase,
        );
        state = newState;
      } else {
        removeProduct(productId);
      }
    }
  }

  void clearCart() {
    state = [];
  }

  double get totalPrice {
    return state.fold(0, (total, item) => total + (item.priceAtPurchase * item.quantity));
  }
}
