import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:product_catalog/product_catalog.dart';
import 'package:media_manager/media_manager.dart';

class ProductFormState {
  final String title;
  final String description;
  final double basePrice;
  final List<ProductVariant> variants;
  final fp.PlatformFile? selectedImage;

  ProductFormState({
    this.title = '',
    this.description = '',
    this.basePrice = 0.0,
    this.variants = const [],
    this.selectedImage,
  });

  ProductFormState copyWith({
    String? title,
    String? description,
    double? basePrice,
    List<ProductVariant>? variants,
    fp.PlatformFile? selectedImage,
  }) {
    return ProductFormState(
      title: title ?? this.title,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      variants: variants ?? this.variants,
      selectedImage: selectedImage ?? this.selectedImage,
    );
  }
}

class ProductFormNotifier extends Notifier<ProductFormState> {
  @override
  ProductFormState build() {
    return ProductFormState();
  }

  void updateTitle(String title) => state = state.copyWith(title: title);
  void updateBasePrice(double price) => state = state.copyWith(basePrice: price);
  void setImage(fp.PlatformFile file) => state = state.copyWith(selectedImage: file);
  
  void generateVariants(List<String> colors, List<String> sizes, int defaultStock) {
    List<ProductVariant> newVariants = [];
    int idCounter = 1;
    for (var color in colors) {
      for (var size in sizes) {
        newVariants.add(ProductVariant(
          id: 'v_${idCounter++}',
          sku: 'SKU-$color-$size',
          attributes: {'Color': color, 'Size': size},
          price: state.basePrice,
          stock: defaultStock,
        ));
      }
    }
    state = state.copyWith(variants: newVariants);
  }

  Future<void> saveProduct() async {
    final repository = ref.read(productRepositoryProvider);
    final mediaRepo = ref.read(mediaRepositoryProvider);
    
    final productId = DateTime.now().millisecondsSinceEpoch.toString();
    String? uploadedImageUrl;

    // 1. Upload Media
    if (state.selectedImage != null && state.selectedImage!.bytes != null) {
      uploadedImageUrl = await mediaRepo.uploadProductMedia(
        productId,
        state.selectedImage!.name,
        state.selectedImage!.bytes!,
      );
    }

    // 2. Save Product
    final product = Product(
      id: productId,
      title: state.title,
      basePrice: state.basePrice,
      status: 'active',
    );
    await repository.saveProduct(product);

    // 3. Save Variants
    for (var variant in state.variants) {
      final updatedVariant = variant.copyWith(
        images: uploadedImageUrl != null ? [uploadedImageUrl] : [],
      );
      await repository.saveVariant(productId, updatedVariant);
    }
  }
}

final productFormNotifierProvider = NotifierProvider<ProductFormNotifier, ProductFormState>(() {
  return ProductFormNotifier();
});

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  int _currentStep = 0;
  bool _isSaving = false;
  
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _colorsController = TextEditingController();
  final _sizesController = TextEditingController();
  final _stockController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _colorsController.dispose();
    _sizesController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ProductFormNotifier notifier) async {
    final result = await fp.FilePicker.pickFiles(
      type: fp.FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      notifier.setImage(result.files.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(productFormNotifierProvider);
    final notifier = ref.read(productFormNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/products'),
        ),
      ),
      body: _isSaving 
        ? const Center(child: CircularProgressIndicator()) 
        : Stepper(
        currentStep: _currentStep,
        onStepContinue: () async {
          if (_currentStep == 0) {
            notifier.updateTitle(_titleController.text);
            notifier.updateBasePrice(double.tryParse(_priceController.text) ?? 0.0);
            setState(() => _currentStep++);
          } else if (_currentStep == 1) {
            final colors = _colorsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            final sizes = _sizesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            final defaultStock = int.tryParse(_stockController.text) ?? 0;
            notifier.generateVariants(
              colors.isNotEmpty ? colors : ['Default'], 
              sizes.isNotEmpty ? sizes : ['Default'],
              defaultStock
            );
            setState(() => _currentStep++);
          } else if (_currentStep == 2) {
            setState(() => _isSaving = true);
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final router = GoRouter.of(context);
            try {
              await notifier.saveProduct();
              if (mounted) router.go('/products');
            } catch (e) {
              setState(() => _isSaving = false);
              if (mounted) scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
        },
        steps: [
          Step(
            title: const Text('Basic Information'),
            content: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Product Title'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Base Price'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Variants & Inventory'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter comma separated values for matrix generation.'),
                const SizedBox(height: 16),
                TextField(
                  controller: _colorsController,
                  decoration: const InputDecoration(labelText: 'Colors (e.g. Red, Blue)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sizesController,
                  decoration: const InputDecoration(labelText: 'Sizes (e.g. S, M, L)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _stockController,
                  decoration: const InputDecoration(labelText: 'Default Stock per Variant'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Media & Review'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(notifier),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Product Image'),
                ),
                if (formState.selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Selected: ${formState.selectedImage!.name}'),
                  ),
                const Divider(height: 32),
                Text('Title: ${formState.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Base Price: \$${formState.basePrice}'),
                const SizedBox(height: 16),
                const Text('Generated Variants (with Stock):', style: TextStyle(fontWeight: FontWeight.bold)),
                ...formState.variants.map((v) => Text('${v.sku} - \$${v.price} (Stock: ${v.stock})')),
              ],
            ),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }
}
