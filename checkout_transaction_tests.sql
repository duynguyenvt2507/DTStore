-- =============================================================================
-- CHECKOUT TRANSACTION TESTS
-- Run after importing mfigure_database_schema_and_seed.sql
-- =============================================================================

USE `mfigure_shop`;

-- Reset state for deterministic tests
DELETE FROM promotion_usages;
DELETE FROM order_items;
DELETE FROM orders;
UPDATE products
SET stock_quantity = CASE product_id
  WHEN 101 THEN 8
  WHEN 102 THEN 5
  WHEN 105 THEN 40
  ELSE stock_quantity
END,
sold_count = CASE product_id
  WHEN 101 THEN 0
  WHEN 102 THEN 0
  WHEN 105 THEN 0
  ELSE sold_count
END
WHERE product_id IN (101, 102, 105);
UPDATE promotions SET used_count = 0 WHERE promotion_id = 1;

-- 1) Success checkout with free gift
CALL sp_place_order_with_promotions(
  2,101,1,0,'BANK_TRANSFER',
  'Test Success','0900000001','success@example.com','Ha Noi',
  @order_id_1,@msg_1
);
SELECT @order_id_1 AS order_id, @msg_1 AS message;
SELECT
  CASE WHEN @order_id_1 IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS created_order,
  CASE WHEN EXISTS (
    SELECT 1 FROM order_items WHERE order_id=@order_id_1 AND product_id=105 AND is_free_gift=1 AND quantity=1
  ) THEN 'PASS' ELSE 'FAIL' END AS created_gift_item,
  CASE WHEN (SELECT stock_quantity FROM products WHERE product_id=101)=7 THEN 'PASS' ELSE 'FAIL' END AS main_stock_decreased,
  CASE WHEN (SELECT stock_quantity FROM products WHERE product_id=105)=39 THEN 'PASS' ELSE 'FAIL' END AS gift_stock_decreased;

-- 2) Pre-order deposit checkout
CALL sp_place_order_with_promotions(
  2,102,1,1,'BANK_TRANSFER',
  'Test Preorder','0900000002','preorder@example.com','HCM',
  @order_id_2,@msg_2
);
SELECT @order_id_2 AS order_id, @msg_2 AS message;
SELECT
  CASE WHEN @order_id_2 IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS preorder_created,
  CASE WHEN EXISTS (
    SELECT 1 FROM orders
    WHERE order_id=@order_id_2
      AND payment_status='DEPOSIT_PAID'
      AND order_status='PRE_ORDER_WAITING'
      AND deposit_paid=ROUND(final_amount*0.30,2)
  ) THEN 'PASS' ELSE 'FAIL' END AS preorder_deposit_ok;

-- 3) Reward out of stock must rollback all
SET @before_orders_3 := (SELECT COUNT(*) FROM orders);
SET @before_main_stock_3 := (SELECT stock_quantity FROM products WHERE product_id=101);
UPDATE products SET stock_quantity=0 WHERE product_id=105;
CALL sp_place_order_with_promotions(
  2,101,1,0,'BANK_TRANSFER',
  'Test Reward OOS','0900000003','reward-oos@example.com','Da Nang',
  @order_id_3,@msg_3
);
SELECT @order_id_3 AS order_id, @msg_3 AS message;
SELECT
  CASE WHEN @order_id_3 IS NULL THEN 'PASS' ELSE 'FAIL' END AS rejected_order,
  CASE WHEN (SELECT COUNT(*) FROM orders)=@before_orders_3 THEN 'PASS' ELSE 'FAIL' END AS no_new_order,
  CASE WHEN (SELECT stock_quantity FROM products WHERE product_id=101)=@before_main_stock_3 THEN 'PASS' ELSE 'FAIL' END AS main_stock_unchanged;
UPDATE products SET stock_quantity=39 WHERE product_id=105;

-- 4) Promotion quota exhausted must rollback
SET @before_orders_4 := (SELECT COUNT(*) FROM orders);
SET @before_main_stock_4 := (SELECT stock_quantity FROM products WHERE product_id=101);
UPDATE promotions SET used_count=usage_limit WHERE promotion_id=1;
CALL sp_place_order_with_promotions(
  2,101,1,0,'BANK_TRANSFER',
  'Test Promo Quota','0900000004','promo-quota@example.com','Can Tho',
  @order_id_4,@msg_4
);
SELECT @order_id_4 AS order_id, @msg_4 AS message;
SELECT
  CASE WHEN @order_id_4 IS NULL THEN 'PASS' ELSE 'FAIL' END AS rejected_order,
  CASE WHEN (SELECT COUNT(*) FROM orders)=@before_orders_4 THEN 'PASS' ELSE 'FAIL' END AS no_new_order,
  CASE WHEN (SELECT stock_quantity FROM products WHERE product_id=101)=@before_main_stock_4 THEN 'PASS' ELSE 'FAIL' END AS main_stock_unchanged;
UPDATE promotions SET used_count=0 WHERE promotion_id=1;

-- 5) Invalid quantity must not create duplicate orders
SET @before_orders_5 := (SELECT COUNT(*) FROM orders);
CALL sp_place_order_with_promotions(
  2,101,0,0,'BANK_TRANSFER',
  'Test Invalid Qty','0900000005','invalid-qty@example.com','Hue',
  @order_id_5,@msg_5
);
SELECT @order_id_5 AS order_id, @msg_5 AS message;
SELECT
  CASE WHEN @order_id_5 IS NULL THEN 'PASS' ELSE 'FAIL' END AS rejected_order,
  CASE WHEN (SELECT COUNT(*) FROM orders)=@before_orders_5 THEN 'PASS' ELSE 'FAIL' END AS no_duplicate_order;
