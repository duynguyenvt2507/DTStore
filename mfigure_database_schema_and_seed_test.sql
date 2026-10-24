-- SQL integration test for mfigure_database_schema_and_seed.sql
-- Run with: mysql -u <user> -p < mfigure_database_schema_and_seed_test.sql

SOURCE ./mfigure_database_schema_and_seed.sql;
SOURCE ./mfigure_database_schema_and_seed.sql;

USE `mfigure_shop`;

DROP PROCEDURE IF EXISTS `sp_assert_true`;
DELIMITER $$
CREATE PROCEDURE `sp_assert_true`(IN p_condition TINYINT, IN p_message VARCHAR(255))
BEGIN
  IF p_condition IS NULL OR p_condition = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = p_message;
  END IF;
END$$
DELIMITER ;

-- 1) Objects exist
SET @table_count = (
  SELECT COUNT(*) FROM information_schema.tables
  WHERE table_schema = 'mfigure_shop'
    AND table_name IN ('categories','brands','series','products','product_images','promotions','promotion_rules','users','orders','order_items','promotion_usages')
);
CALL sp_assert_true(@table_count = 11, 'Expected all base tables to exist');

SET @view_count = (
  SELECT COUNT(*) FROM information_schema.views
  WHERE table_schema = 'mfigure_shop'
    AND table_name IN ('vw_product_catalog_pricing','vw_promotion_performance')
);
CALL sp_assert_true(@view_count = 2, 'Expected both views to exist');

SET @proc_count = (
  SELECT COUNT(*) FROM information_schema.routines
  WHERE routine_schema = 'mfigure_shop'
    AND routine_type = 'PROCEDURE'
    AND routine_name = 'sp_place_order_with_promotions'
);
CALL sp_assert_true(@proc_count = 1, 'Expected checkout procedure to exist');

-- 2) Minimum seed counts
SET @product_count = (SELECT COUNT(*) FROM products);
CALL sp_assert_true(@product_count >= 12, 'Expected at least 12 products');

SET @order_count_seed = (SELECT COUNT(*) FROM orders);
CALL sp_assert_true(@order_count_seed >= 3, 'Expected sample orders to exist');

SET @usage_count_seed = (SELECT COUNT(*) FROM promotion_usages);
CALL sp_assert_true(@usage_count_seed >= 3, 'Expected sample promotion usages to exist');

-- 3) Catalog pricing view returns usable prices
SET @pricing_ok = (
  SELECT COUNT(*) FROM vw_product_catalog_pricing
  WHERE final_display_price IS NOT NULL AND final_display_price > 0
);
CALL sp_assert_true(@pricing_ok > 0, 'Catalog pricing view returned invalid prices');

-- 4) Successful checkout: Scale product should add MICA gift and reduce stock
SET @main_stock_before = (SELECT stock_quantity FROM products WHERE product_id = 101);
SET @gift_stock_before = (SELECT stock_quantity FROM products WHERE product_id = 105);
SET @promo1_used_before = (SELECT used_count FROM promotions WHERE promotion_id = 1);
SET @usage_before = (SELECT COUNT(*) FROM promotion_usages);

CALL sp_place_order_with_promotions(
  2,
  101,
  1,
  NULL,
  'Test Scale Buyer',
  '0900000001',
  'scale-buyer@example.com',
  'Ha Noi',
  'BANK_TRANSFER',
  @order_scale_id,
  @order_scale_code,
  @order_scale_message
);

CALL sp_assert_true(@order_scale_id IS NOT NULL, 'Scale order id should be returned');
CALL sp_assert_true(@order_scale_code IS NOT NULL, 'Scale order code should be returned');

SET @main_stock_after = (SELECT stock_quantity FROM products WHERE product_id = 101);
SET @gift_stock_after = (SELECT stock_quantity FROM products WHERE product_id = 105);
SET @promo1_used_after = (SELECT used_count FROM promotions WHERE promotion_id = 1);
SET @usage_after = (SELECT COUNT(*) FROM promotion_usages);

CALL sp_assert_true(@main_stock_after = @main_stock_before - 1, 'Main stock should decrease by checkout quantity');
CALL sp_assert_true(@gift_stock_after = @gift_stock_before - 1, 'Gift stock should decrease when gift applied');
CALL sp_assert_true(@promo1_used_after = @promo1_used_before + 1, 'Gift promotion used_count should increment');
CALL sp_assert_true(@usage_after = @usage_before + 1, 'Promotion usage should be logged for gift promotion');
CALL sp_assert_true(
  (SELECT COUNT(*) FROM order_items WHERE order_id = @order_scale_id AND product_id = 105 AND is_free_gift = 1) = 1,
  'Gift order item should be created'
);

-- 5) Pre-order checkout should calculate deposit correctly
CALL sp_place_order_with_promotions(
  2,
  102,
  1,
  NULL,
  'Test Preorder Buyer',
  '0900000002',
  'preorder-buyer@example.com',
  'Ha Noi',
  'BANK_TRANSFER',
  @order_pre_id,
  @order_pre_code,
  @order_pre_message
);

CALL sp_assert_true(@order_pre_id IS NOT NULL, 'Pre-order id should be returned');
CALL sp_assert_true(
  (SELECT payment_status FROM orders WHERE order_id = @order_pre_id) = 'DEPOSIT_PAID',
  'Pre-order payment_status must be DEPOSIT_PAID'
);
CALL sp_assert_true(
  (SELECT order_status FROM orders WHERE order_id = @order_pre_id) = 'PRE_ORDER_WAITING',
  'Pre-order order_status must be PRE_ORDER_WAITING'
);
CALL sp_assert_true(
  (SELECT deposit_paid = ROUND(final_amount * 0.30, 2) FROM orders WHERE order_id = @order_pre_id),
  'Deposit amount must equal 30% of final amount'
);

-- 6) Over-stock checkout must rollback and not update stock/usages
DROP PROCEDURE IF EXISTS `sp_test_expect_fail`; 
DELIMITER $$
CREATE PROCEDURE `sp_test_expect_fail`()
BEGIN
  DECLARE v_failed TINYINT DEFAULT 0;
  DECLARE v_orders_before INT;
  DECLARE v_usages_before INT;
  DECLARE v_promo_before INT;
  DECLARE v_flash_before INT;
  DECLARE v_main_stock_before_local INT;
  DECLARE v_gift_stock_before_local INT;

  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
    SET v_failed = 1;
  END;

  SET v_orders_before = (SELECT COUNT(*) FROM orders);
  SET v_usages_before = (SELECT COUNT(*) FROM promotion_usages);
  SET v_promo_before = (SELECT used_count FROM promotions WHERE promotion_id = 1);
  SET v_flash_before = (SELECT used_count FROM promotions WHERE promotion_id = 5);
  SET v_main_stock_before_local = (SELECT stock_quantity FROM products WHERE product_id = 101);
  SET v_gift_stock_before_local = (SELECT stock_quantity FROM products WHERE product_id = 105);

  CALL sp_place_order_with_promotions(
    2,
    101,
    99999,
    NULL,
    'Test Fail Buyer',
    '0900000003',
    'fail-buyer@example.com',
    'Ha Noi',
    'BANK_TRANSFER',
    @order_fail_id,
    @order_fail_code,
    @order_fail_message
  );

  CALL sp_assert_true(v_failed = 1, 'Expected checkout to fail when quantity exceeds stock');
  CALL sp_assert_true((SELECT COUNT(*) FROM orders) = v_orders_before, 'Order count changed on rollback scenario');
  CALL sp_assert_true((SELECT COUNT(*) FROM promotion_usages) = v_usages_before, 'Promotion usages changed on rollback scenario');
  CALL sp_assert_true((SELECT used_count FROM promotions WHERE promotion_id = 1) = v_promo_before, 'Promotion used_count changed on rollback scenario');
  CALL sp_assert_true((SELECT used_count FROM promotions WHERE promotion_id = 5) = v_flash_before, 'Flash promotion used_count changed on rollback scenario');
  CALL sp_assert_true((SELECT stock_quantity FROM products WHERE product_id = 101) = v_main_stock_before_local, 'Main product stock changed on rollback');
  CALL sp_assert_true((SELECT stock_quantity FROM products WHERE product_id = 105) = v_gift_stock_before_local, 'Gift product stock changed on rollback');
END$$
DELIMITER ;

CALL sp_test_expect_fail();

DROP PROCEDURE IF EXISTS `sp_test_expect_fail`;
DROP PROCEDURE IF EXISTS `sp_assert_true`;

SELECT 'ALL TESTS PASSED' AS result;
