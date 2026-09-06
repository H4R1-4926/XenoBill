import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/calculate_invoice_totals.dart';
import '../../infrastructure/database/app_database.dart';

abstract class InvoiceEvent extends Equatable {
  const InvoiceEvent();
  @override
  List<Object?> get props => [];
}

class AddProductToCartEvent extends InvoiceEvent {
  final Item item;
  const AddProductToCartEvent(this.item);
  @override
  List<Object?> get props => [item];
}

class UpdateCartQuantityEvent extends InvoiceEvent {
  final String productId;
  final int delta;
  const UpdateCartQuantityEvent({required this.productId, required this.delta});
  @override
  List<Object?> get props => [productId, delta];
}

class UpdateCartItemPriceEvent extends InvoiceEvent {
  final String productId;
  final double newPrice;
  const UpdateCartItemPriceEvent({required this.productId, required this.newPrice});
  @override
  List<Object?> get props => [productId, newPrice];
}

class UpdateCartItemDiscountEvent extends InvoiceEvent {
  final String productId;
  final double newDiscount;
  const UpdateCartItemDiscountEvent({required this.productId, required this.newDiscount});
  @override
  List<Object?> get props => [productId, newDiscount];
}

class SetCustomerEvent extends InvoiceEvent {
  final Customer customer;
  const SetCustomerEvent(this.customer);
  @override
  List<Object?> get props => [customer];
}

class UpdateCustomerDetailsEvent extends InvoiceEvent {
  final String? name;
  final String? phone;
  const UpdateCustomerDetailsEvent({this.name, this.phone});
  @override
  List<Object?> get props => [name, phone];
}

class SetPaymentTypeEvent extends InvoiceEvent {
  final PaymentType paymentType;
  const SetPaymentTypeEvent(this.paymentType);
  @override
  List<Object?> get props => [paymentType];
}

class SetDiscountEvent extends InvoiceEvent {
  final double discount;
  const SetDiscountEvent(this.discount);
  @override
  List<Object?> get props => [discount];
}

class SetPaidAmountEvent extends InvoiceEvent {
  final double amount;
  const SetPaidAmountEvent(this.amount);
  @override
  List<Object?> get props => [amount];
}

class AddExtraExpenseEvent extends InvoiceEvent {
  final String name;
  final double amount;
  const AddExtraExpenseEvent({required this.name, required this.amount});
  @override
  List<Object?> get props => [name, amount];
}

class RemoveExtraExpenseEvent extends InvoiceEvent {
  final String expenseId;
  const RemoveExtraExpenseEvent(this.expenseId);
  @override
  List<Object?> get props => [expenseId];
}

class SaveInvoiceEvent extends InvoiceEvent {}

class ResetCartEvent extends InvoiceEvent {}

class ExtraExpenseItem extends Equatable {
  final String id;
  final String name;
  final double amount;

  const ExtraExpenseItem({
    required this.id,
    required this.name,
    required this.amount,
  });

  @override
  List<Object?> get props => [id, name, amount];
}

class InvoiceState extends Equatable {
  final List<InvoiceItem> items;
  final Customer customer;
  final PaymentType paymentType;
  final String customCustomerName;
  final String customCustomerPhone;
  final List<ExtraExpenseItem> extraExpenses;
  final double overallDiscount;
  final double customPaidAmount;
  final double subtotal;
  final double cgst;
  final double sgst;
  final double igst;
  final double totalTax;
  final double grandTotal;
  final double dueAmount;
  final bool isSaving;
  final Invoice? savedInvoice;
  final String? errorMessage;

  const InvoiceState({
    required this.items,
    required this.customer,
    required this.paymentType,
    this.customCustomerName = '',
    this.customCustomerPhone = '',
    this.extraExpenses = const [],
    this.overallDiscount = 0.0,
    this.customPaidAmount = -1.0,
    this.subtotal = 0.0,
    this.cgst = 0.0,
    this.sgst = 0.0,
    this.igst = 0.0,
    this.totalTax = 0.0,
    this.grandTotal = 0.0,
    this.dueAmount = 0.0,
    this.isSaving = false,
    this.savedInvoice,
    this.errorMessage,
  });

  double get totalExtraExpenses => extraExpenses.fold(0.0, (sum, e) => sum + e.amount);
  int get totalItemCount => items.fold(0, (sum, i) => sum + i.quantity);

  bool get isCredit => paymentType == PaymentType.credit;
  bool get isWalkIn => customer.id == 'cust_walk_in';
  bool get isContactReadOnly => isCredit && !isWalkIn;

  String get effectiveCustomerName {
    if (isContactReadOnly) return customer.name;
    return customCustomerName;
  }

  String get effectiveCustomerPhone {
    if (isContactReadOnly) return customer.phone;
    return customCustomerPhone;
  }

  factory InvoiceState.initial() {
    final walkIn = AppDatabase.instance.customers.firstWhere(
      (c) => c.id == 'cust_walk_in',
      orElse: () => const Customer(
        id: 'cust_walk_in',
        businessId: 'biz_1',
        name: 'Walk-in Customer',
        phone: '',
        email: '',
        address: '',
        gstin: '',
        outstandingBalance: 0.0,
        totalInvoices: 0,
      ),
    );

    return InvoiceState(
      items: const [],
      customer: walkIn,
      paymentType: PaymentType.cash,
      customCustomerName: '',
      customCustomerPhone: '',
      extraExpenses: const [],
    );
  }

  InvoiceState copyWith({
    List<InvoiceItem>? items,
    Customer? customer,
    PaymentType? paymentType,
    String? customCustomerName,
    String? customCustomerPhone,
    List<ExtraExpenseItem>? extraExpenses,
    double? overallDiscount,
    double? customPaidAmount,
    double? subtotal,
    double? cgst,
    double? sgst,
    double? igst,
    double? totalTax,
    double? grandTotal,
    double? dueAmount,
    bool? isSaving,
    Invoice? savedInvoice,
    String? errorMessage,
  }) {
    return InvoiceState(
      items: items ?? this.items,
      customer: customer ?? this.customer,
      paymentType: paymentType ?? this.paymentType,
      customCustomerName: customCustomerName ?? this.customCustomerName,
      customCustomerPhone: customCustomerPhone ?? this.customCustomerPhone,
      extraExpenses: extraExpenses ?? this.extraExpenses,
      overallDiscount: overallDiscount ?? this.overallDiscount,
      customPaidAmount: customPaidAmount ?? this.customPaidAmount,
      subtotal: subtotal ?? this.subtotal,
      cgst: cgst ?? this.cgst,
      sgst: sgst ?? this.sgst,
      igst: igst ?? this.igst,
      totalTax: totalTax ?? this.totalTax,
      grandTotal: grandTotal ?? this.grandTotal,
      dueAmount: dueAmount ?? this.dueAmount,
      isSaving: isSaving ?? this.isSaving,
      savedInvoice: savedInvoice,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        items,
        customer,
        paymentType,
        customCustomerName,
        customCustomerPhone,
        extraExpenses,
        overallDiscount,
        customPaidAmount,
        subtotal,
        cgst,
        sgst,
        igst,
        totalTax,
        grandTotal,
        dueAmount,
        isSaving,
        savedInvoice,
        errorMessage,
      ];
}

class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  final InvoiceRepository repository;
  final CalculateInvoiceTotals calculateTotals = CalculateInvoiceTotals();

  InvoiceBloc({required this.repository}) : super(InvoiceState.initial()) {
    on<AddProductToCartEvent>((event, emit) {
      final currentItems = List<InvoiceItem>.from(state.items);
      final index = currentItems.indexWhere((i) => i.productId == event.item.id);

      if (index != -1) {
        final existing = currentItems[index];
        final newQty = existing.quantity + 1;
        final newLineSubtotal = existing.unitPrice * newQty - existing.discountAmount;
        final newTax = (newLineSubtotal * event.item.gstRate) / 100.0;
        currentItems[index] = existing.copyWith(
          quantity: newQty,
          taxAmount: newTax,
          totalAmount: newLineSubtotal,
        );
      } else {
        final lineSubtotal = event.item.sellingPrice;
        final lineTax = (lineSubtotal * event.item.gstRate) / 100.0;
        currentItems.add(
          InvoiceItem(
            id: const Uuid().v4(),
            productId: event.item.id,
            productName: event.item.name,
            quantity: 1,
            unitPrice: event.item.sellingPrice,
            discountAmount: 0.0,
            gstRate: event.item.gstRate,
            taxAmount: lineTax,
            totalAmount: lineSubtotal,
          ),
        );
      }

      _recalculateAndEmit(
        emit: emit,
        items: currentItems,
        customer: state.customer,
        paymentType: state.paymentType,
        customCustomerName: state.customCustomerName,
        customCustomerPhone: state.customCustomerPhone,
        extraExpenses: state.extraExpenses,
        discount: state.overallDiscount,
        customPaidAmount: state.customPaidAmount,
      );
    });

    on<UpdateCartQuantityEvent>((event, emit) {
      final currentItems = List<InvoiceItem>.from(state.items);
      final index = currentItems.indexWhere((i) => i.productId == event.productId);

      if (index != -1) {
        final existing = currentItems[index];
        final newQty = existing.quantity + event.delta;

        if (newQty <= 0) {
          currentItems.removeAt(index);
        } else {
          final lineSubtotal = existing.unitPrice * newQty - existing.discountAmount;
          final lineTax = (lineSubtotal * existing.gstRate) / 100.0;
          currentItems[index] = existing.copyWith(
            quantity: newQty,
            taxAmount: lineTax,
            totalAmount: lineSubtotal,
          );
        }
      }

      _recalculateAndEmit(
        emit: emit,
        items: currentItems,
        customer: state.customer,
        paymentType: state.paymentType,
        customCustomerName: state.customCustomerName,
        customCustomerPhone: state.customCustomerPhone,
        extraExpenses: state.extraExpenses,
        discount: state.overallDiscount,
        customPaidAmount: state.customPaidAmount,
      );
    });

    on<UpdateCartItemPriceEvent>((event, emit) {
      final currentItems = List<InvoiceItem>.from(state.items);
      final index = currentItems.indexWhere((i) => i.productId == event.productId);

      if (index != -1) {
        final existing = currentItems[index];
        final lineSubtotal = event.newPrice * existing.quantity - existing.discountAmount;
        final lineTax = (lineSubtotal * existing.gstRate) / 100.0;
        currentItems[index] = existing.copyWith(
          unitPrice: event.newPrice,
          taxAmount: lineTax,
          totalAmount: lineSubtotal,
        );
      }

      _recalculateAndEmit(
        emit: emit,
        items: currentItems,
        customer: state.customer,
        paymentType: state.paymentType,
        customCustomerName: state.customCustomerName,
        customCustomerPhone: state.customCustomerPhone,
        extraExpenses: state.extraExpenses,
        discount: state.overallDiscount,
        customPaidAmount: state.customPaidAmount,
      );
    });

    on<UpdateCartItemDiscountEvent>((event, emit) {
      final currentItems = List<InvoiceItem>.from(state.items);
      final index = currentItems.indexWhere((i) => i.productId == event.productId);

      if (index != -1) {
        final existing = currentItems[index];
        final lineSubtotal = existing.unitPrice * existing.quantity - event.newDiscount;
        final lineTax = (lineSubtotal * existing.gstRate) / 100.0;
        currentItems[index] = existing.copyWith(
          discountAmount: event.newDiscount,
          taxAmount: lineTax,
          totalAmount: lineSubtotal,
        );
      }

      _recalculateAndEmit(
        emit: emit,
        items: currentItems,
        customer: state.customer,
        paymentType: state.paymentType,
        customCustomerName: state.customCustomerName,
        customCustomerPhone: state.customCustomerPhone,
        extraExpenses: state.extraExpenses,
        discount: state.overallDiscount,
        customPaidAmount: state.customPaidAmount,
      );
    });

    on<AddExtraExpenseEvent>((event, emit) {
      final currentExpenses = List<ExtraExpenseItem>.from(state.extraExpenses);
      currentExpenses.add(ExtraExpenseItem(
        id: const Uuid().v4(),
        name: event.name,
        amount: event.amount,
      ));
      _recalculateAndEmit(
        emit: emit,
        items: state.items,
        customer: state.customer,
        paymentType: state.paymentType,
        customCustomerName: state.customCustomerName,
        customCustomerPhone: state.customCustomerPhone,
        extraExpenses: currentExpenses,
        discount: state.overallDiscount,
        customPaidAmount: state.customPaidAmount,
      );
    });

    on<RemoveExtraExpenseEvent>((event, emit) {
      final currentExpenses = List<ExtraExpenseItem>.from(state.extraExpenses)
        ..removeWhere((e) => e.id == event.expenseId);
      _recalculateAndEmit(
        emit: emit,
        items: state.items,
        customer: state.customer,
        paymentType: state.paymentType,
        customCustomerName: state.customCustomerName,
        customCustomerPhone: state.customCustomerPhone,
        extraExpenses: currentExpenses,
        discount: state.overallDiscount,
        customPaidAmount: state.customPaidAmount,
      );
    });

    on<SetCustomerEvent>((event, emit) {
      final newName = event.customer.id != 'cust_walk_in' ? event.customer.name : state.customCustomerName;
      final newPhone = event.customer.id != 'cust_walk_in' ? event.customer.phone : state.customCustomerPhone;
      _recalculateAndEmit(
        emit: emit,
        items: state.items,
        customer: event.customer,
        paymentType: state.paymentType,
        customCustomerName: newName,
        customCustomerPhone: newPhone,
        extraExpenses: state.extraExpenses,
        discount: state.overallDiscount,
        customPaidAmount: state.customPaidAmount,
      );
    });

    on<UpdateCustomerDetailsEvent>((event, emit) {
      final updatedName = event.name ?? state.customCustomerName;
      final updatedPhone = event.phone ?? state.customCustomerPhone;
      _recalculateAndEmit(
        emit: emit,
        items: state.items,
        customer: state.customer,
        paymentType: state.paymentType,
        customCustomerName: updatedName,
        customCustomerPhone: updatedPhone,
        extraExpenses: state.extraExpenses,
        discount: state.overallDiscount,
        customPaidAmount: state.customPaidAmount,
      );
    });

    on<SetPaymentTypeEvent>((event, emit) {
      Customer newCustomer = state.customer;
      String newCustomName = state.customCustomerName;
      String newCustomPhone = state.customCustomerPhone;

      if (event.paymentType == PaymentType.cash) {
        // Credit -> Cash: reset to walk-in customer and clear credit customer details
        newCustomer = AppDatabase.instance.customers.firstWhere(
          (c) => c.id == 'cust_walk_in',
          orElse: () => const Customer(
            id: 'cust_walk_in',
            businessId: 'biz_1',
            name: 'Walk-in Customer',
            phone: '',
            email: '',
            address: '',
            gstin: '',
            outstandingBalance: 0.0,
            totalInvoices: 0,
          ),
        );
        newCustomName = '';
        newCustomPhone = '';
      }

      _recalculateAndEmit(
        emit: emit,
        items: state.items,
        customer: newCustomer,
        paymentType: event.paymentType,
        customCustomerName: newCustomName,
        customCustomerPhone: newCustomPhone,
        extraExpenses: state.extraExpenses,
        discount: state.overallDiscount,
        customPaidAmount: state.customPaidAmount,
      );
    });

    on<SetDiscountEvent>((event, emit) {
      _recalculateAndEmit(
        emit: emit,
        items: state.items,
        customer: state.customer,
        paymentType: state.paymentType,
        customCustomerName: state.customCustomerName,
        customCustomerPhone: state.customCustomerPhone,
        extraExpenses: state.extraExpenses,
        discount: event.discount,
        customPaidAmount: state.customPaidAmount,
      );
    });

    on<SetPaidAmountEvent>((event, emit) {
      _recalculateAndEmit(
        emit: emit,
        items: state.items,
        customer: state.customer,
        paymentType: state.paymentType,
        customCustomerName: state.customCustomerName,
        customCustomerPhone: state.customCustomerPhone,
        extraExpenses: state.extraExpenses,
        discount: state.overallDiscount,
        customPaidAmount: event.amount,
      );
    });

    on<SaveInvoiceEvent>((event, emit) async {
      if (state.items.isEmpty) {
        emit(state.copyWith(errorMessage: 'Cart is empty. Please add items first.'));
        return;
      }

      if (state.paymentType == PaymentType.credit && state.customer.id == 'cust_walk_in') {
        emit(state.copyWith(errorMessage: 'Credit sales require selecting a registered customer.'));
        return;
      }

      emit(state.copyWith(isSaving: true));

      final biz = AppDatabase.instance.currentBusiness!;
      final prefix = biz.invoicePrefix;
      final num = biz.nextInvoiceNumber;
      final invNumber = '$prefix-$num';

      double actualPaid = state.grandTotal;
      if (state.paymentType == PaymentType.credit) {
        actualPaid = state.customPaidAmount >= 0 ? state.customPaidAmount : 0.0;
      }
      final due = (state.grandTotal - actualPaid).clamp(0.0, double.infinity);

      final String finalCustName = state.effectiveCustomerName.trim().isNotEmpty
          ? state.effectiveCustomerName.trim()
          : 'Walk-in Customer';
      final String finalCustPhone = state.effectiveCustomerPhone.trim();

      final newInvoice = Invoice(
        id: const Uuid().v4(),
        businessId: biz.id,
        invoiceNumber: invNumber,
        invoiceDate: DateTime.now(),
        customerId: state.customer.id,
        customerName: finalCustName,
        customerPhone: finalCustPhone,
        items: state.items,
        subtotal: state.subtotal,
        discount: state.overallDiscount,
        cgst: state.cgst,
        sgst: state.sgst,
        igst: state.igst,
        grandTotal: state.grandTotal,
        paymentType: state.paymentType,
        paidAmount: actualPaid,
        dueAmount: due,
        status: state.paymentType == PaymentType.credit ? InvoiceStatus.credit : InvoiceStatus.paid,
      );

      await repository.saveInvoice(newInvoice);

      emit(state.copyWith(
        isSaving: false,
        savedInvoice: newInvoice,
      ));
    });

    on<ResetCartEvent>((event, emit) {
      emit(InvoiceState.initial());
    });
  }

  void _recalculateAndEmit({
    required Emitter<InvoiceState> emit,
    required List<InvoiceItem> items,
    required Customer customer,
    required PaymentType paymentType,
    required String customCustomerName,
    required String customCustomerPhone,
    required List<ExtraExpenseItem> extraExpenses,
    required double discount,
    required double customPaidAmount,
  }) {
    final biz = AppDatabase.instance.currentBusiness;
    final extraTotal = extraExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final totals = calculateTotals.execute(
      items: items,
      overallDiscount: discount,
      gstEnabled: biz?.gstEnabled ?? true,
      isInterState: false,
      extraExpensesTotal: extraTotal,
    );

    final grand = totals['grandTotal']!;
    double due = 0.0;
    if (paymentType == PaymentType.credit) {
      final paid = customPaidAmount >= 0 ? customPaidAmount : 0.0;
      due = (grand - paid).clamp(0.0, double.infinity);
    }

    emit(InvoiceState(
      items: items,
      customer: customer,
      paymentType: paymentType,
      customCustomerName: customCustomerName,
      customCustomerPhone: customCustomerPhone,
      extraExpenses: extraExpenses,
      overallDiscount: discount,
      customPaidAmount: customPaidAmount,
      subtotal: totals['subtotal']!,
      cgst: totals['cgst']!,
      sgst: totals['sgst']!,
      igst: totals['igst']!,
      totalTax: totals['totalTax']!,
      grandTotal: grand,
      dueAmount: due,
    ));
  }
}
