-- =============================================================================
-- M FIGURE SHOP - DATABASE SCHEMA & DEMO SEED
-- MySQL 8.0+ / MariaDB 10.4+
-- =============================================================================

SET NAMES utf8mb4;
SET time_zone = '+07:00';
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';

CREATE DATABASE IF NOT EXISTS `mfigure_shop`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `mfigure_shop`;

DROP VIEW IF EXISTS `vw_product_catalog_pricing`;
DROP VIEW IF EXISTS `vw_promotion_performance`;
DROP PROCEDURE IF EXISTS `sp_place_order_with_promotions`;
DROP TABLE IF EXISTS `promotion_usages`;
DROP TABLE IF EXISTS `order_items`;
DROP TABLE IF EXISTS `orders`;
DROP TABLE IF EXISTS `users`;
DROP TABLE IF EXISTS `promotion_rules`;
DROP TABLE IF EXISTS `promotions`;
DROP TABLE IF EXISTS `product_images`;
DROP TABLE IF EXISTS `products`;
DROP TABLE IF EXISTS `series`;
DROP TABLE IF EXISTS `brands`;
DROP TABLE IF EXISTS `categories`;

CREATE TABLE `categories` (
  `category_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `parent_id` INT UNSIGNED NULL,
  `code` VARCHAR(40) NOT NULL UNIQUE,
  `name` VARCHAR(150) NOT NULL,
  `slug` VARCHAR(160) NOT NULL UNIQUE,
  `description` TEXT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_categories_parent` FOREIGN KEY (`parent_id`)
    REFERENCES `categories` (`category_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `brands` (
  `brand_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(150) NOT NULL,
  `slug` VARCHAR(160) NOT NULL UNIQUE,
  `country` VARCHAR(80) NOT NULL DEFAULT 'Japan',
  `logo_url` VARCHAR(500) NULL,
  `website_url` VARCHAR(300) NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `series` (
  `series_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(200) NOT NULL,
  `slug` VARCHAR(210) NOT NULL UNIQUE,
  `banner_url` VARCHAR(500) NULL,
  `is_featured` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `products` (
  `product_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `sku` VARCHAR(60) NOT NULL UNIQUE,
  `name` VARCHAR(300) NOT NULL,
  `slug` VARCHAR(320) NOT NULL UNIQUE,
  `category_id` INT UNSIGNED NOT NULL,
  `brand_id` INT UNSIGNED NULL,
  `series_id` INT UNSIGNED NULL,
  `original_price` DECIMAL(15,2) NOT NULL,
  `sale_price` DECIMAL(15,2) NULL,
  `stock_quantity` INT NOT NULL DEFAULT 0,
  `sold_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `product_status` ENUM('IN_STOCK','PRE_ORDER','OUT_OF_STOCK','CONTACT_PRICE') NOT NULL DEFAULT 'IN_STOCK',
  `deposit_percent` DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  `release_date` DATE NULL,
  `preorder_deadline` DATE NULL,
  `character_name` VARCHAR(150) NULL,
  `scale_ratio` VARCHAR(50) NULL DEFAULT 'Non-scale',
  `height_cm` DECIMAL(6,2) NULL,
  `material` VARCHAR(150) NOT NULL DEFAULT 'PVC, ABS',
  `is_flash_sale` TINYINT(1) NOT NULL DEFAULT 0,
  `is_featured` TINYINT(1) NOT NULL DEFAULT 0,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `short_description` VARCHAR(500) NULL,
  `description` LONGTEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_products_filters` (`category_id`,`brand_id`,`series_id`,`product_status`,`is_active`),
  CONSTRAINT `fk_products_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`category_id`),
  CONSTRAINT `fk_products_brand` FOREIGN KEY (`brand_id`) REFERENCES `brands` (`brand_id`) ON DELETE SET NULL,
  CONSTRAINT `fk_products_series` FOREIGN KEY (`series_id`) REFERENCES `series` (`series_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `product_images` (
  `image_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `product_id` INT UNSIGNED NOT NULL,
  `image_url` VARCHAR(500) NOT NULL,
  `alt_text` VARCHAR(255) NULL,
  `is_primary` TINYINT(1) NOT NULL DEFAULT 0,
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_product_images` (`product_id`,`is_primary`),
  CONSTRAINT `fk_product_images_product` FOREIGN KEY (`product_id`)
    REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `promotions` (
  `promotion_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(250) NOT NULL,
  `code` VARCHAR(50) NULL UNIQUE,
  `promotion_type` ENUM('BUY_X_GET_Y','PERCENT_DISCOUNT','FIXED_AMOUNT','FLASH_SALE','BUNDLE_DEAL') NOT NULL,
  `rule_mode` VARCHAR(50) NOT NULL DEFAULT 'CUSTOM',
  `discount_value` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  `max_discount_amount` DECIMAL(15,2) NULL,
  `min_order_value` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  `buy_quantity` INT UNSIGNED NOT NULL DEFAULT 1,
  `get_quantity` INT UNSIGNED NOT NULL DEFAULT 1,
  `get_discount_percent` DECIMAL(5,2) NOT NULL DEFAULT 100.00,
  `start_date` DATETIME NOT NULL,
  `end_date` DATETIME NOT NULL,
  `usage_limit` INT UNSIGNED NULL,
  `used_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `is_stackable` TINYINT(1) NOT NULL DEFAULT 1,
  `priority` INT NOT NULL DEFAULT 1,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_promotions_active` (`is_active`,`promotion_type`,`start_date`,`end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `promotion_rules` (
  `rule_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `promotion_id` INT UNSIGNED NOT NULL,
  `role` ENUM('BUY_CONDITION','GET_REWARD','APPLICABLE_ITEM') NOT NULL,
  `target_type` ENUM('PRODUCT','CATEGORY','BRAND','SERIES','ALL') NOT NULL,
  `target_id` INT UNSIGNED NULL,
  `flash_sale_price` DECIMAL(15,2) NULL,
  `flash_sale_quota` INT UNSIGNED NULL,
  `note` VARCHAR(255) NULL,
  INDEX `idx_promotion_rules` (`promotion_id`,`role`,`target_type`,`target_id`),
  CONSTRAINT `fk_promotion_rules_promotion` FOREIGN KEY (`promotion_id`)
    REFERENCES `promotions` (`promotion_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `users` (
  `user_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `full_name` VARCHAR(150) NOT NULL,
  `email` VARCHAR(150) NOT NULL UNIQUE,
  `phone` VARCHAR(20) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `default_address` TEXT NULL,
  `loyalty_points` INT UNSIGNED NOT NULL DEFAULT 0,
  `member_tier` ENUM('MEMBER','SILVER','GOLD','VIP_OTAKU') NOT NULL DEFAULT 'MEMBER',
  `role` ENUM('CUSTOMER','STAFF','ADMIN') NOT NULL DEFAULT 'CUSTOMER',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `orders` (
  `order_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `order_code` VARCHAR(30) NOT NULL UNIQUE,
  `user_id` INT UNSIGNED NULL,
  `customer_name` VARCHAR(150) NOT NULL,
  `customer_phone` VARCHAR(20) NOT NULL,
  `customer_email` VARCHAR(150) NULL,
  `shipping_address` TEXT NOT NULL,
  `order_note` VARCHAR(500) NULL,
  `subtotal_amount` DECIMAL(15,2) NOT NULL,
  `promo_discount_amount` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  `voucher_discount_amount` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  `discount_amount` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  `shipping_fee` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  `final_amount` DECIMAL(15,2) NOT NULL,
  `deposit_paid` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  `remaining_balance` DECIMAL(15,2) GENERATED ALWAYS AS (GREATEST(0,`final_amount`-`deposit_paid`)) STORED,
  `applied_voucher_code` VARCHAR(50) NULL,
  `payment_method` ENUM('BANK_TRANSFER','COD','VNPAY','MOMO') NOT NULL DEFAULT 'BANK_TRANSFER',
  `payment_status` ENUM('UNPAID','DEPOSIT_PAID','PAID','REFUNDED') NOT NULL DEFAULT 'UNPAID',
  `order_status` ENUM('PENDING','CONFIRMED','PRE_ORDER_WAITING','SHIPPING','COMPLETED','CANCELLED') NOT NULL DEFAULT 'PENDING',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_orders_lookup` (`order_code`,`customer_phone`),
  INDEX `idx_orders_status` (`order_status`,`payment_status`),
  CONSTRAINT `fk_orders_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `order_items` (
  `order_item_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `order_id` INT UNSIGNED NOT NULL,
  `product_id` INT UNSIGNED NOT NULL,
  `product_name_snapshot` VARCHAR(300) NOT NULL,
  `quantity` INT UNSIGNED NOT NULL DEFAULT 1,
  `unit_price` DECIMAL(15,2) NOT NULL,
  `discount_per_unit` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  `line_total` DECIMAL(15,2) NOT NULL,
  `is_free_gift` TINYINT(1) NOT NULL DEFAULT 0,
  `is_preorder_item` TINYINT(1) NOT NULL DEFAULT 0,
  `applied_promotion_id` INT UNSIGNED NULL,
  CONSTRAINT `fk_order_items_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_order_items_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`),
  CONSTRAINT `fk_order_items_promotion` FOREIGN KEY (`applied_promotion_id`) REFERENCES `promotions` (`promotion_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `promotion_usages` (
  `usage_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `promotion_id` INT UNSIGNED NOT NULL,
  `order_id` INT UNSIGNED NOT NULL,
  `user_id` INT UNSIGNED NULL,
  `discount_saved` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  `used_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_promotion_usages_promotion` FOREIGN KEY (`promotion_id`) REFERENCES `promotions` (`promotion_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_promotion_usages_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE OR REPLACE VIEW `vw_product_catalog_pricing` AS
SELECT p.product_id,p.sku,p.name,p.slug,c.code category_code,c.name category_name,
       b.name brand_name,s.name series_name,p.original_price,p.sale_price,
       COALESCE(fs.flash_sale_price,p.sale_price,p.original_price) final_display_price,
       COALESCE(
         ROUND(
           ((p.original_price - COALESCE(fs.flash_sale_price,p.sale_price,p.original_price))
            / NULLIF(p.original_price,0)) * 100,
           0
         ),
         0
       ) discount_percent,
       p.stock_quantity,p.product_status,p.deposit_percent,p.release_date,p.scale_ratio,p.height_cm,p.material,
       fs.end_date flash_sale_end_time,pi.image_url primary_image_url
FROM products p
JOIN categories c ON c.category_id = p.category_id
LEFT JOIN brands b ON b.brand_id = p.brand_id
LEFT JOIN series s ON s.series_id = p.series_id
LEFT JOIN product_images pi ON pi.product_id = p.product_id AND pi.is_primary = 1
LEFT JOIN (
  SELECT r.target_id product_id,
         MIN(r.flash_sale_price) flash_sale_price,
         MAX(pm.end_date) end_date
  FROM promotion_rules r
  JOIN promotions pm ON pm.promotion_id = r.promotion_id
  WHERE pm.promotion_type = 'FLASH_SALE'
    AND pm.is_active = 1
    AND NOW() BETWEEN pm.start_date AND pm.end_date
    AND (pm.usage_limit IS NULL OR pm.used_count < pm.usage_limit)
    AND r.target_type = 'PRODUCT'
    AND r.flash_sale_price IS NOT NULL
  GROUP BY r.target_id
) fs ON fs.product_id = p.product_id
WHERE p.is_active = 1;

CREATE OR REPLACE VIEW `vw_promotion_performance` AS
SELECT
  pm.promotion_id,
  pm.name,
  pm.code,
  pm.promotion_type,
  pm.used_count,
  pm.usage_limit,
  COUNT(pu.usage_id) AS logged_orders_count,
  COALESCE(SUM(pu.discount_saved),0) AS total_discount_granted,
  pm.start_date,
  pm.end_date,
  (CASE WHEN NOW() BETWEEN pm.start_date AND pm.end_date AND pm.is_active = 1 THEN 1 ELSE 0 END) AS is_currently_active
FROM promotions pm
LEFT JOIN promotion_usages pu ON pu.promotion_id = pm.promotion_id
GROUP BY
  pm.promotion_id,
  pm.name,
  pm.code,
  pm.promotion_type,
  pm.used_count,
  pm.usage_limit,
  pm.start_date,
  pm.end_date,
  pm.is_active;

DELIMITER $$
CREATE PROCEDURE `sp_place_order_with_promotions`(
  IN p_user_id INT UNSIGNED,
  IN p_product_id INT UNSIGNED,
  IN p_quantity INT UNSIGNED,
  IN p_use_deposit TINYINT,
  IN p_payment_method VARCHAR(20),
  IN p_customer_name VARCHAR(150),
  IN p_customer_phone VARCHAR(20),
  IN p_customer_email VARCHAR(150),
  IN p_shipping_address TEXT,
  OUT o_order_id INT UNSIGNED,
  OUT o_message VARCHAR(255)
)
proc_main: BEGIN
  DECLARE v_now DATETIME DEFAULT NOW();
  DECLARE v_order_id INT UNSIGNED;
  DECLARE v_order_code VARCHAR(30);
  DECLARE v_product_name VARCHAR(300);
  DECLARE v_category_id INT UNSIGNED;
  DECLARE v_product_status VARCHAR(20);
  DECLARE v_is_active TINYINT(1);
  DECLARE v_stock INT;
  DECLARE v_sold_count INT UNSIGNED;
  DECLARE v_deposit_percent DECIMAL(5,2);
  DECLARE v_unit_price DECIMAL(15,2);
  DECLARE v_subtotal DECIMAL(15,2);
  DECLARE v_discount_total DECIMAL(15,2) DEFAULT 0.00;
  DECLARE v_final_amount DECIMAL(15,2);
  DECLARE v_deposit_paid DECIMAL(15,2) DEFAULT 0.00;
  DECLARE v_order_status VARCHAR(20);
  DECLARE v_payment_status VARCHAR(20);
  DECLARE v_payment_method_input VARCHAR(20);

  DECLARE v_promotion_id INT UNSIGNED;
  DECLARE v_promo_buy_qty INT UNSIGNED;
  DECLARE v_promo_get_qty INT UNSIGNED;
  DECLARE v_reward_product_id INT UNSIGNED;
  DECLARE v_reward_product_name VARCHAR(300);
  DECLARE v_reward_stock INT;
  DECLARE v_reward_sold_count INT UNSIGNED;
  DECLARE v_reward_unit_price DECIMAL(15,2);
  DECLARE v_gift_sets INT UNSIGNED DEFAULT 0;
  DECLARE v_gift_qty INT UNSIGNED DEFAULT 0;
  DECLARE v_usage_limit INT UNSIGNED;
  DECLARE v_used_count INT UNSIGNED;
  DECLARE v_error_message VARCHAR(255) DEFAULT NULL;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET o_order_id = NULL;
    SET o_message = COALESCE(v_error_message,'Checkout failed and rolled back due to SQL error.');
  END;

  SET o_order_id = NULL;
  SET o_message = NULL;

  IF p_quantity IS NULL OR p_quantity = 0 THEN
    SET v_error_message = 'Quantity must be greater than 0.';
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
  END IF;
  IF p_customer_name IS NULL OR TRIM(p_customer_name) = '' THEN
    SET v_error_message = 'Customer name is required.';
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
  END IF;
  IF p_customer_phone IS NULL OR TRIM(p_customer_phone) = '' THEN
    SET v_error_message = 'Customer phone is required.';
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
  END IF;
  IF p_shipping_address IS NULL OR TRIM(p_shipping_address) = '' THEN
    SET v_error_message = 'Shipping address is required.';
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
  END IF;

  START TRANSACTION;

  SELECT p.name,p.category_id,p.product_status,p.is_active,p.stock_quantity,p.sold_count,p.deposit_percent,
         COALESCE(fs.flash_sale_price,p.sale_price,p.original_price)
  INTO v_product_name,v_category_id,v_product_status,v_is_active,v_stock,v_sold_count,v_deposit_percent,v_unit_price
  FROM products p
  LEFT JOIN (
    SELECT r.target_id,MIN(r.flash_sale_price) flash_sale_price
    FROM promotion_rules r
    JOIN promotions pm ON pm.promotion_id=r.promotion_id
    WHERE r.target_type='PRODUCT'
      AND r.role='APPLICABLE_ITEM'
      AND pm.promotion_type='FLASH_SALE'
      AND pm.is_active=1
      AND v_now BETWEEN pm.start_date AND pm.end_date
      AND (pm.usage_limit IS NULL OR pm.used_count < pm.usage_limit)
    GROUP BY r.target_id
  ) fs ON fs.target_id=p.product_id
  WHERE p.product_id=p_product_id
  FOR UPDATE;

  IF v_product_name IS NULL THEN
    SET v_error_message = 'Product not found.';
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
  END IF;
  IF v_is_active <> 1 THEN
    SET v_error_message = 'Product is inactive.';
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
  END IF;
  IF v_stock < p_quantity THEN
    SET v_error_message = 'Insufficient stock for main product.';
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
  END IF;

  SELECT pm.promotion_id,pm.buy_quantity,pm.get_quantity,rr.target_id
  INTO v_promotion_id,v_promo_buy_qty,v_promo_get_qty,v_reward_product_id
  FROM promotions pm
  JOIN promotion_rules br ON br.promotion_id=pm.promotion_id
  JOIN promotion_rules rr ON rr.promotion_id=pm.promotion_id
  WHERE pm.promotion_type='BUY_X_GET_Y'
    AND pm.is_active=1
    AND v_now BETWEEN pm.start_date AND pm.end_date
    AND (pm.usage_limit IS NULL OR pm.used_count < pm.usage_limit)
    AND br.role='BUY_CONDITION'
    AND rr.role='GET_REWARD'
    AND rr.target_type='PRODUCT'
    AND (
      (br.target_type='PRODUCT' AND br.target_id=p_product_id)
      OR (br.target_type='CATEGORY' AND br.target_id=v_category_id)
      OR br.target_type='ALL'
    )
  ORDER BY pm.priority ASC,pm.promotion_id ASC
  LIMIT 1;

  IF v_promotion_id IS NOT NULL THEN
    SELECT usage_limit,used_count
    INTO v_usage_limit,v_used_count
    FROM promotions
    WHERE promotion_id=v_promotion_id
    FOR UPDATE;

    IF v_usage_limit IS NOT NULL AND v_used_count >= v_usage_limit THEN
      SET v_error_message = 'Promotion usage limit reached.';
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END IF;

    IF v_promo_buy_qty IS NULL OR v_promo_buy_qty = 0 THEN
      SET v_promo_buy_qty = 1;
    END IF;
    IF v_promo_get_qty IS NULL OR v_promo_get_qty = 0 THEN
      SET v_promo_get_qty = 1;
    END IF;
    SET v_gift_sets = FLOOR(p_quantity / v_promo_buy_qty);
    SET v_gift_qty = v_gift_sets * v_promo_get_qty;
  END IF;

  IF v_gift_qty > 0 THEN
    SELECT p.name,p.stock_quantity,p.sold_count,COALESCE(p.sale_price,p.original_price)
    INTO v_reward_product_name,v_reward_stock,v_reward_sold_count,v_reward_unit_price
    FROM products p
    WHERE p.product_id=v_reward_product_id
      AND p.is_active=1
    FOR UPDATE;

    IF v_reward_product_name IS NULL THEN
      SET v_error_message = 'Reward product is missing or inactive.';
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END IF;
    IF v_reward_stock < v_gift_qty THEN
      SET v_error_message = 'Insufficient stock for reward product.';
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END IF;
  END IF;

  SET v_subtotal = v_unit_price * p_quantity;
  IF v_gift_qty > 0 THEN
    SET v_discount_total = v_reward_unit_price * v_gift_qty;
  END IF;
  SET v_final_amount = v_subtotal;

  IF v_product_status = 'PRE_ORDER' THEN
    SET v_order_status = 'PRE_ORDER_WAITING';
    IF p_use_deposit = 1 THEN
      SET v_deposit_paid = ROUND(v_final_amount * (v_deposit_percent / 100),2);
      SET v_payment_status = 'DEPOSIT_PAID';
    ELSE
      SET v_deposit_paid = v_final_amount;
      SET v_payment_status = 'PAID';
    END IF;
  ELSE
    SET v_order_status = 'PENDING';
    SET v_deposit_paid = v_final_amount;
    SET v_payment_status = 'PAID';
  END IF;

  SET v_payment_method_input = COALESCE(NULLIF(p_payment_method,''),'BANK_TRANSFER');
  IF v_payment_method_input NOT IN ('BANK_TRANSFER','COD','VNPAY','MOMO') THEN
    SET v_payment_method_input = 'BANK_TRANSFER';
  END IF;

  SET v_order_code = CONCAT('OD', DATE_FORMAT(v_now,'%Y%m%d%H%i%s'), LPAD(FLOOR(RAND() * 1000),3,'0'));

  INSERT INTO orders (
    order_code,user_id,customer_name,customer_phone,customer_email,shipping_address,
    subtotal_amount,promo_discount_amount,voucher_discount_amount,discount_amount,shipping_fee,final_amount,
    deposit_paid,payment_method,payment_status,order_status
  ) VALUES (
    v_order_code,p_user_id,p_customer_name,p_customer_phone,p_customer_email,p_shipping_address,
    v_subtotal,v_discount_total,0,v_discount_total,0,v_final_amount,
    v_deposit_paid,v_payment_method_input,v_payment_status,v_order_status
  );
  SET v_order_id = LAST_INSERT_ID();

  INSERT INTO order_items (
    order_id,product_id,product_name_snapshot,quantity,unit_price,discount_per_unit,line_total,is_free_gift,is_preorder_item,applied_promotion_id
  ) VALUES (
    v_order_id,p_product_id,v_product_name,p_quantity,v_unit_price,0,v_subtotal,0,(v_product_status='PRE_ORDER'),v_promotion_id
  );

  UPDATE products
  SET stock_quantity=stock_quantity-p_quantity,
      sold_count=sold_count+p_quantity
  WHERE product_id=p_product_id;

  IF v_gift_qty > 0 THEN
    INSERT INTO order_items (
      order_id,product_id,product_name_snapshot,quantity,unit_price,discount_per_unit,line_total,is_free_gift,is_preorder_item,applied_promotion_id
    ) VALUES (
      v_order_id,v_reward_product_id,v_reward_product_name,v_gift_qty,v_reward_unit_price,v_reward_unit_price,0,1,0,v_promotion_id
    );

    UPDATE products
    SET stock_quantity=stock_quantity-v_gift_qty,
        sold_count=sold_count+v_gift_qty
    WHERE product_id=v_reward_product_id;

    INSERT INTO promotion_usages (promotion_id,order_id,user_id,discount_saved)
    VALUES (v_promotion_id,v_order_id,p_user_id,v_discount_total);

    UPDATE promotions
    SET used_count=used_count+1
    WHERE promotion_id=v_promotion_id;
  END IF;

  COMMIT;

  SET o_order_id = v_order_id;
  SET o_message = CONCAT('Order placed successfully: ', v_order_code);
END$$
DELIMITER ;

INSERT INTO categories (category_id,parent_id,code,name,slug,description,sort_order) VALUES
(1,NULL,'PRIZE','Game Prize Figure','game-prize-figure','Mô hình Prize Figure - Mua 2 tặng 1',1),
(2,NULL,'SCALE','Scale Figure','scale-figure','Mô hình tỷ lệ cao cấp - Tặng hộp MICA',2),
(3,NULL,'NENDOROID','Nendoroid / Chibi','nendoroid-chibi','Mô hình chibi chính hãng',3),
(4,NULL,'ACCESSORY','Hộp trưng bày MICA','hop-trung-bay-mica','Phụ kiện trưng bày mô hình',4),
(5,NULL,'POP_UP','Pop Up Parade','pop-up-parade','Dòng figure phổ biến',5),
(6,NULL,'RESIN','Mô hình Resin','mo-hinh-resin','Tượng Resin giới hạn',6),
(7,NULL,'TCG','Thẻ bài TCG','the-bai-tcg','Pokemon TCG và thẻ bài Anime',7);

INSERT INTO brands (brand_id,name,slug,country,website_url) VALUES
(1,'Good Smile Company','good-smile-company','Japan','https://www.goodsmile.info'),
(2,'Taito','taito','Japan','https://www.taito.co.jp'),
(3,'FuRyu','furyu','Japan','https://www.furyu.jp'),
(4,'Bandai Spirits','bandai-spirits','Japan','https://www.bandaispirits.co.jp'),
(5,'Myethos','myethos','China','https://www.myethos.cn'),
(6,'Kotobukiya','kotobukiya','Japan','https://www.kotobukiya.co.jp'),
(7,'M Figure Gear','m-figure-gear','Vietnam','https://mfigure.vn');

INSERT INTO series (series_id,name,slug) VALUES
(1,'Vocaloid / Hatsune Miku','hatsune-miku'),
(2,'Jujutsu Kaisen','jujutsu-kaisen'),
(3,'Zenless Zone Zero','zenless-zone-zero'),
(4,'Blue Archive','blue-archive'),
(5,'One Piece','one-piece'),
(6,'Honkai: Star Rail','honkai-star-rail'),
(7,'Frieren: Beyond Journey''s End','frieren-beyond-journeys-end');

INSERT INTO products
(product_id,sku,name,slug,category_id,brand_id,series_id,original_price,sale_price,stock_quantity,sold_count,product_status,deposit_percent,release_date,preorder_deadline,character_name,scale_ratio,height_cm,material,is_flash_sale,is_featured,short_description)
VALUES
(101,'MYE-ZZZ-101','MÔ HÌNH Asaba Harumasa - Zenless Zone Zero - Scale 1/8','asaba-harumasa-zzz-1-8',2,5,3,2570000,1990000,9,1,'IN_STOCK',0,'2026-08-15',NULL,'Asaba Harumasa','1/8',24.5,'PVC, ABS',1,1,'Scale Figure chính hãng.'),
(102,'GSC-DAL-102','[PRE-ORDER] Sunohara Kokona - Blue Archive - 1/7','sunohara-kokona-blue-archive-1-7',2,1,4,6400000,5800000,5,1,'PRE_ORDER',30,'2027-01-20','2026-12-15','Sunohara Kokona','1/7',26,'PVC, ABS',0,1,'Đặt cọc 30%.'),
(103,'FUR-MIK-103','Hatsune Miku Trio-Try-iT Raincoat Ver.','hatsune-miku-trio-try-it-raincoat',1,3,1,750000,560000,15,0,'IN_STOCK',0,'2026-05-10',NULL,'Hatsune Miku','Non-scale',21,'PVC',1,1,'Game Prize Figure.'),
(104,'BAN-JJK-104','Choso Jujutsu Kaisen Maximatic','choso-jujutsu-kaisen-maximatic',1,4,2,970000,720000,12,0,'IN_STOCK',0,'2026-06-01',NULL,'Choso','Non-scale',22,'PVC',1,1,'Bandai Spirits.'),
(105,'MFG-MICA-LED','Hộp trưng bày MICA đế LED 30x25x25cm','hop-mica-led-30x25x25',4,7,NULL,250000,250000,39,1,'IN_STOCK',0,NULL,NULL,'Display Box','30x25x25cm',30,'Acrylic MICA + LED',0,1,'Quà tặng cho Scale Figure.'),
(106,'TAI-MIK-106','Hatsune Miku Coreful Lolita Ver.','hatsune-miku-coreful-lolita',1,2,1,700000,520000,16,2,'IN_STOCK',0,'2026-04-12',NULL,'Hatsune Miku','Non-scale',20,'PVC',0,1,'Taito chính hãng.'),
(107,'GSC-NEN-983','Magical Star Girl Nendoroid #983','magical-star-girl-nendoroid-983',3,1,NULL,1150000,850000,10,0,'IN_STOCK',0,'2026-07-01',NULL,'Magical Star Girl','Non-scale',10,'PVC, ABS',1,1,'Nendoroid Deluxe.'),
(108,'GSC-NEN-387','[PRE-ORDER] Kasane Teto Nendoroid SynthV','kasane-teto-nendoroid-synthv',3,1,1,1500000,1100000,9,0,'PRE_ORDER',30,'2026-12-20','2026-11-30','Kasane Teto','Non-scale',10,'PVC, ABS',0,1,'Pre-order đặt cọc 30%.'),
(109,'KOT-OP-109','Roronoa Zoro Battle Version Scale 1/8','roronoa-zoro-battle-version-1-8',2,6,5,3800000,3490000,7,0,'IN_STOCK',0,'2026-08-20',NULL,'Roronoa Zoro','1/8',23.8,'PVC, ABS',1,1,'Scale Figure One Piece.'),
(110,'GSC-FRR-110','Frieren Pop Up Parade L Size','frieren-pop-up-parade-l-size',5,1,7,1650000,1490000,11,0,'IN_STOCK',0,'2026-09-10',NULL,'Frieren','Non-scale',23.0,'PVC, ABS',0,1,'POP UP PARADE cỡ L.'),
(111,'MYE-HSR-111','Kafka Resin Statue Limited','kafka-resin-statue-limited',6,5,6,14500000,13900000,3,0,'IN_STOCK',0,'2026-10-01',NULL,'Kafka','1/6',32.0,'Polystone Resin',0,0,'Resin bản giới hạn.'),
(112,'BAN-TCG-112','Pokemon TCG Scarlet & Violet Booster Box','pokemon-tcg-sv-booster-box',7,4,NULL,3200000,3050000,20,0,'IN_STOCK',0,'2026-06-15',NULL,'Pokemon TCG','Non-scale',0,'Cardboard',0,1,'Booster Box chính hãng.');

INSERT INTO product_images (product_id,image_url,alt_text,is_primary,sort_order) VALUES
(101,'/assets/images/products/asaba-harumasa-1-8.jpg','Asaba Harumasa',1,1),
(102,'/assets/images/products/sunohara-kokona-1-7.jpg','Sunohara Kokona',1,1),
(103,'/assets/images/products/miku-raincoat-furyu.jpg','Hatsune Miku Raincoat',1,1),
(104,'/assets/images/products/choso-maximatic-bandai.jpg','Choso Maximatic',1,1),
(105,'/assets/images/products/hop-mica-led-30x25x25.jpg','Hộp MICA LED',1,1),
(106,'/assets/images/products/miku-coreful-lolita-taito.jpg','Miku Coreful',1,1),
(107,'/assets/images/products/magical-star-girl-nen-983.jpg','Magical Star Girl',1,1),
(108,'/assets/images/products/kasane-teto-synthv-nen.jpg','Kasane Teto',1,1),
(109,'/assets/images/products/zoro-battle-1-8.jpg','Roronoa Zoro',1,1),
(110,'/assets/images/products/frieren-pop-up-parade-l.jpg','Frieren Pop Up Parade',1,1),
(111,'/assets/images/products/kafka-resin-limited.jpg','Kafka Resin Limited',1,1),
(112,'/assets/images/products/pokemon-sv-booster-box.jpg','Pokemon SV Booster Box',1,1);

INSERT INTO promotions
(promotion_id,name,code,promotion_type,rule_mode,discount_value,max_discount_amount,min_order_value,buy_quantity,get_quantity,get_discount_percent,start_date,end_date,usage_limit,used_count,is_stackable,priority)
VALUES
(1,'Mua 1 Scale Figure tặng 1 Hộp MICA',NULL,'BUY_X_GET_Y','BUY_SCALE_GET_MICA',0,NULL,0,1,1,100,'2026-01-01 00:00:00','2027-12-31 23:59:59',500,1,1,1),
(2,'Mua 2 tặng 1 Game Prize',NULL,'BUY_X_GET_Y','BUY_2_GET_1_PRIZE',0,NULL,0,2,1,100,'2026-01-01 00:00:00','2027-12-31 23:59:59',500,0,1,2),
(3,'Voucher MFIGURE100 giảm 100.000đ','MFIGURE100','FIXED_AMOUNT','VOUCHER_FIXED',100000,100000,1000000,1,1,0,'2026-01-01 00:00:00','2027-12-31 23:59:59',1000,1,1,3),
(4,'Voucher OTAKU10 giảm 10%','OTAKU10','PERCENT_DISCOUNT','VOUCHER_PERCENT',10,300000,500000,1,1,0,'2026-01-01 00:00:00','2027-12-31 23:59:59',1000,0,1,4),
(5,'Flash Sale Đếm Ngược',NULL,'FLASH_SALE','FLASH_SALE_EVENT',0,NULL,0,1,1,0,'2026-01-01 00:00:00','2027-12-31 23:59:59',300,1,1,0),
(6,'Voucher hết hạn demo','EXPIRED10','PERCENT_DISCOUNT','VOUCHER_PERCENT',10,100000,500000,1,1,0,'2025-01-01 00:00:00','2025-12-31 23:59:59',100,0,1,5);

INSERT INTO promotion_rules (rule_id,promotion_id,role,target_type,target_id,flash_sale_price,flash_sale_quota,note) VALUES
(1,1,'BUY_CONDITION','CATEGORY',2,NULL,NULL,'Mua Scale Figure'),
(2,1,'GET_REWARD','PRODUCT',105,NULL,NULL,'Tặng Hộp MICA LED'),
(3,2,'BUY_CONDITION','CATEGORY',1,NULL,NULL,'Mua Game Prize'),
(4,2,'GET_REWARD','CATEGORY',1,NULL,NULL,'Miễn phí món rẻ nhất'),
(5,5,'APPLICABLE_ITEM','PRODUCT',101,1890000,10,'Flash Sale Asaba Harumasa'),
(6,5,'APPLICABLE_ITEM','PRODUCT',103,540000,20,'Flash Sale Hatsune Miku'),
(7,5,'APPLICABLE_ITEM','PRODUCT',104,690000,15,'Flash Sale Choso'),
(8,5,'APPLICABLE_ITEM','PRODUCT',107,790000,15,'Flash Sale Nendoroid'),
(9,5,'APPLICABLE_ITEM','PRODUCT',109,3290000,8,'Flash Sale Zoro Scale');

-- Password demo hash only; replace it in a real deployment.
INSERT INTO users (user_id,full_name,email,phone,password_hash,default_address,member_tier,role) VALUES
(1,'Quản Trị Viên M Figure','admin@mfigure.vn','0987770035','$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi','Hà Nội','VIP_OTAKU','ADMIN'),
(2,'Trần Hoàng Nam','nam.tran@gmail.com','0912345678','$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi','Hà Nội','GOLD','CUSTOMER');

INSERT INTO orders
(order_id,order_code,user_id,customer_name,customer_phone,customer_email,shipping_address,order_note,subtotal_amount,promo_discount_amount,voucher_discount_amount,discount_amount,shipping_fee,final_amount,deposit_paid,applied_voucher_code,payment_method,payment_status,order_status,created_at)
VALUES
(1,'OD202610240001',2,'Trần Hoàng Nam','0912345678','nam.tran@gmail.com','Hà Nội','Scale + quà MICA',1890000,250000,0,250000,0,1890000,0,NULL,'BANK_TRANSFER','PAID','COMPLETED','2026-10-24 09:00:00'),
(2,'OD202610240002',2,'Trần Hoàng Nam','0912345678','nam.tran@gmail.com','Hà Nội','Dùng voucher MFIGURE100',1040000,0,100000,100000,0,940000,0,'MFIGURE100','BANK_TRANSFER','PAID','COMPLETED','2026-10-24 10:00:00'),
(3,'OD202610240003',2,'Trần Hoàng Nam','0912345678','nam.tran@gmail.com','Hà Nội','Pre-order đặt cọc',5800000,0,0,0,0,5800000,1740000,NULL,'BANK_TRANSFER','DEPOSIT_PAID','PRE_ORDER_WAITING','2026-10-24 11:00:00');

INSERT INTO order_items
(order_item_id,order_id,product_id,product_name_snapshot,quantity,unit_price,discount_per_unit,line_total,is_free_gift,is_preorder_item,applied_promotion_id)
VALUES
(1,1,101,'MÔ HÌNH Asaba Harumasa - Zenless Zone Zero - Scale 1/8',1,1890000,680000,1890000,0,0,NULL),
(2,1,105,'Hộp trưng bày MICA đế LED 30x25x25cm',1,250000,250000,0,1,0,1),
(3,2,106,'Hatsune Miku Coreful Lolita Ver.',2,520000,180000,1040000,0,0,3),
(4,3,102,'[PRE-ORDER] Sunohara Kokona - Blue Archive - 1/7',1,5800000,600000,5800000,0,1,NULL);

INSERT INTO promotion_usages (usage_id,promotion_id,order_id,user_id,discount_saved,used_at) VALUES
(1,1,1,2,250000,'2026-10-24 09:00:00'),
(2,3,2,2,100000,'2026-10-24 10:00:00'),
(3,5,1,2,100000,'2026-10-24 09:00:00');

DELIMITER $$

CREATE PROCEDURE `sp_place_order_with_promotions`(
  IN p_user_id INT UNSIGNED,
  IN p_product_id INT UNSIGNED,
  IN p_quantity INT UNSIGNED,
  IN p_voucher_code VARCHAR(50),
  IN p_customer_name VARCHAR(150),
  IN p_customer_phone VARCHAR(20),
  IN p_customer_email VARCHAR(150),
  IN p_shipping_address TEXT,
  IN p_payment_method VARCHAR(20),
  OUT p_order_id INT UNSIGNED,
  OUT p_order_code VARCHAR(30),
  OUT p_message VARCHAR(255)
)
BEGIN
  DECLARE v_now DATETIME;
  DECLARE v_order_code VARCHAR(30);
  DECLARE v_main_name VARCHAR(300);
  DECLARE v_main_category_id INT UNSIGNED;
  DECLARE v_main_brand_id INT UNSIGNED;
  DECLARE v_main_series_id INT UNSIGNED;
  DECLARE v_main_original DECIMAL(15,2);
  DECLARE v_main_sale DECIMAL(15,2);
  DECLARE v_main_stock INT;
  DECLARE v_main_status VARCHAR(20);
  DECLARE v_main_deposit_percent DECIMAL(5,2);
  DECLARE v_main_is_active TINYINT(1);
  DECLARE v_flash_price DECIMAL(15,2);
  DECLARE v_flash_promotion_id INT UNSIGNED;
  DECLARE v_flash_usage_limit INT UNSIGNED;
  DECLARE v_flash_used_count INT UNSIGNED;
  DECLARE v_main_unit_price DECIMAL(15,2);

  DECLARE v_gift_promotion_id INT UNSIGNED;
  DECLARE v_gift_buy_qty INT UNSIGNED;
  DECLARE v_gift_get_qty INT UNSIGNED;
  DECLARE v_gift_usage_limit INT UNSIGNED;
  DECLARE v_gift_used_count INT UNSIGNED;
  DECLARE v_gift_product_id INT UNSIGNED;
  DECLARE v_gift_stock INT;
  DECLARE v_gift_price DECIMAL(15,2);
  DECLARE v_gift_qty INT UNSIGNED DEFAULT 0;

  DECLARE v_voucher_promotion_id INT UNSIGNED;
  DECLARE v_voucher_type VARCHAR(30);
  DECLARE v_voucher_value DECIMAL(15,2);
  DECLARE v_voucher_max_discount DECIMAL(15,2);
  DECLARE v_voucher_min_order DECIMAL(15,2);
  DECLARE v_voucher_usage_limit INT UNSIGNED;
  DECLARE v_voucher_used_count INT UNSIGNED;

  DECLARE v_subtotal DECIMAL(15,2) DEFAULT 0;
  DECLARE v_promo_discount DECIMAL(15,2) DEFAULT 0;
  DECLARE v_voucher_discount DECIMAL(15,2) DEFAULT 0;
  DECLARE v_total_discount DECIMAL(15,2) DEFAULT 0;
  DECLARE v_final_amount DECIMAL(15,2) DEFAULT 0;
  DECLARE v_deposit_paid DECIMAL(15,2) DEFAULT 0;
  DECLARE v_payment_status VARCHAR(20) DEFAULT 'UNPAID';
  DECLARE v_order_status VARCHAR(20) DEFAULT 'PENDING';
  DECLARE v_payment_method_final VARCHAR(20);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_order_id = NULL;
    SET p_order_code = NULL;
    SET p_message = 'Checkout failed and rolled back';
    RESIGNAL;
  END;

  SET v_now = NOW();
  SET p_order_id = NULL;
  SET p_order_code = NULL;
  SET p_message = NULL;

  IF p_quantity IS NULL OR p_quantity = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity must be greater than 0';
  END IF;

  IF p_customer_name IS NULL OR CHAR_LENGTH(TRIM(p_customer_name)) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer name is required';
  END IF;

  IF p_customer_phone IS NULL OR CHAR_LENGTH(TRIM(p_customer_phone)) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer phone is required';
  END IF;

  IF p_shipping_address IS NULL OR CHAR_LENGTH(TRIM(p_shipping_address)) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Shipping address is required';
  END IF;

  START TRANSACTION;

  SELECT
    p.name,
    p.category_id,
    p.brand_id,
    p.series_id,
    p.original_price,
    p.sale_price,
    p.stock_quantity,
    p.product_status,
    p.deposit_percent,
    p.is_active
  INTO
    v_main_name,
    v_main_category_id,
    v_main_brand_id,
    v_main_series_id,
    v_main_original,
    v_main_sale,
    v_main_stock,
    v_main_status,
    v_main_deposit_percent,
    v_main_is_active
  FROM products p
  WHERE p.product_id = p_product_id
  FOR UPDATE;

  IF v_main_name IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found';
  END IF;

  IF v_main_is_active <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product is not active';
  END IF;

  IF v_main_status NOT IN ('IN_STOCK','PRE_ORDER') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product status is not purchasable';
  END IF;

  IF v_main_stock < p_quantity THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient product stock';
  END IF;

  SET v_flash_price = NULL;
  SET v_flash_promotion_id = NULL;
  SELECT
    pm.promotion_id,
    r.flash_sale_price,
    pm.usage_limit,
    pm.used_count
  INTO
    v_flash_promotion_id,
    v_flash_price,
    v_flash_usage_limit,
    v_flash_used_count
  FROM promotions pm
  JOIN promotion_rules r ON r.promotion_id = pm.promotion_id
  WHERE pm.promotion_type = 'FLASH_SALE'
    AND pm.is_active = 1
    AND v_now BETWEEN pm.start_date AND pm.end_date
    AND r.role = 'APPLICABLE_ITEM'
    AND r.target_type = 'PRODUCT'
    AND r.target_id = p_product_id
    AND r.flash_sale_price IS NOT NULL
  ORDER BY pm.priority ASC, r.flash_sale_price ASC, pm.promotion_id ASC
  LIMIT 1
  FOR UPDATE;

  IF v_flash_promotion_id IS NOT NULL
     AND v_flash_usage_limit IS NOT NULL
     AND v_flash_used_count >= v_flash_usage_limit THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Flash sale usage limit reached';
  END IF;

  SET v_main_unit_price = COALESCE(v_flash_price, v_main_sale, v_main_original);

  IF v_main_unit_price IS NULL OR v_main_unit_price <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid selling price';
  END IF;

  SET v_subtotal = v_main_unit_price * p_quantity;

  SET v_gift_promotion_id = NULL;
  SELECT
    pm.promotion_id,
    pm.buy_quantity,
    pm.get_quantity,
    pm.usage_limit,
    pm.used_count,
    rg.target_id
  INTO
    v_gift_promotion_id,
    v_gift_buy_qty,
    v_gift_get_qty,
    v_gift_usage_limit,
    v_gift_used_count,
    v_gift_product_id
  FROM promotions pm
  JOIN promotion_rules rb ON rb.promotion_id = pm.promotion_id AND rb.role = 'BUY_CONDITION'
  JOIN promotion_rules rg ON rg.promotion_id = pm.promotion_id AND rg.role = 'GET_REWARD' AND rg.target_type = 'PRODUCT'
  WHERE pm.promotion_type = 'BUY_X_GET_Y'
    AND pm.is_active = 1
    AND v_now BETWEEN pm.start_date AND pm.end_date
    AND (
      rb.target_type = 'ALL'
      OR (rb.target_type = 'PRODUCT' AND rb.target_id = p_product_id)
      OR (rb.target_type = 'CATEGORY' AND rb.target_id = v_main_category_id)
      OR (rb.target_type = 'BRAND' AND rb.target_id = v_main_brand_id)
      OR (rb.target_type = 'SERIES' AND rb.target_id = v_main_series_id)
    )
  ORDER BY pm.priority ASC, pm.promotion_id ASC
  LIMIT 1
  FOR UPDATE;

  IF v_gift_promotion_id IS NOT NULL THEN
    IF v_gift_usage_limit IS NOT NULL AND v_gift_used_count >= v_gift_usage_limit THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gift promotion usage limit reached';
    END IF;

    IF v_gift_buy_qty = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gift promotion buy_quantity is invalid';
    END IF;

    SET v_gift_qty = FLOOR(p_quantity / v_gift_buy_qty) * v_gift_get_qty;

    IF v_gift_qty > 0 THEN
      SELECT stock_quantity, COALESCE(sale_price, original_price)
      INTO v_gift_stock, v_gift_price
      FROM products
      WHERE product_id = v_gift_product_id
        AND is_active = 1
      FOR UPDATE;

      IF v_gift_stock IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gift product does not exist or inactive';
      END IF;

      IF v_gift_stock < v_gift_qty THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient gift stock';
      END IF;

      SET v_promo_discount = v_gift_price * v_gift_qty;
    ELSE
      SET v_gift_qty = 0;
    END IF;
  END IF;

  SET v_voucher_promotion_id = NULL;
  IF p_voucher_code IS NOT NULL AND CHAR_LENGTH(TRIM(p_voucher_code)) > 0 THEN
    SELECT
      pm.promotion_id,
      pm.promotion_type,
      pm.discount_value,
      pm.max_discount_amount,
      pm.min_order_value,
      pm.usage_limit,
      pm.used_count
    INTO
      v_voucher_promotion_id,
      v_voucher_type,
      v_voucher_value,
      v_voucher_max_discount,
      v_voucher_min_order,
      v_voucher_usage_limit,
      v_voucher_used_count
    FROM promotions pm
    WHERE pm.code = TRIM(p_voucher_code)
      AND pm.promotion_type IN ('FIXED_AMOUNT','PERCENT_DISCOUNT')
      AND pm.is_active = 1
      AND v_now BETWEEN pm.start_date AND pm.end_date
    LIMIT 1
    FOR UPDATE;

    IF v_voucher_promotion_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Voucher is invalid or expired';
    END IF;

    IF v_voucher_usage_limit IS NOT NULL AND v_voucher_used_count >= v_voucher_usage_limit THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Voucher usage limit reached';
    END IF;

    IF v_subtotal < v_voucher_min_order THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order value does not meet voucher minimum';
    END IF;

    IF v_voucher_type = 'FIXED_AMOUNT' THEN
      SET v_voucher_discount = LEAST(v_voucher_value, v_subtotal);
    ELSEIF v_voucher_type = 'PERCENT_DISCOUNT' THEN
      SET v_voucher_discount = ROUND(v_subtotal * v_voucher_value / 100, 2);
      IF v_voucher_max_discount IS NOT NULL THEN
        SET v_voucher_discount = LEAST(v_voucher_discount, v_voucher_max_discount);
      END IF;
    END IF;
  END IF;

  SET v_total_discount = v_promo_discount + v_voucher_discount;
  SET v_final_amount = GREATEST(v_subtotal - v_voucher_discount, 0);

  IF v_main_status = 'PRE_ORDER' THEN
    SET v_deposit_paid = ROUND(v_final_amount * v_main_deposit_percent / 100, 2);
    IF v_deposit_paid > 0 THEN
      SET v_payment_status = 'DEPOSIT_PAID';
    ELSE
      SET v_payment_status = 'UNPAID';
    END IF;
    SET v_order_status = 'PRE_ORDER_WAITING';
  ELSE
    SET v_deposit_paid = 0;
    SET v_payment_status = 'UNPAID';
    SET v_order_status = 'PENDING';
  END IF;

  SET v_payment_method_final = CASE
    WHEN p_payment_method IN ('BANK_TRANSFER','COD','VNPAY','MOMO') THEN p_payment_method
    ELSE 'BANK_TRANSFER'
  END;

  SET v_order_code = CONCAT('OD', DATE_FORMAT(v_now, '%Y%m%d%H%i%s'), LPAD(FLOOR(RAND() * 10000), 4, '0'));

  INSERT INTO orders (
    order_code,
    user_id,
    customer_name,
    customer_phone,
    customer_email,
    shipping_address,
    subtotal_amount,
    promo_discount_amount,
    voucher_discount_amount,
    discount_amount,
    shipping_fee,
    final_amount,
    deposit_paid,
    applied_voucher_code,
    payment_method,
    payment_status,
    order_status
  ) VALUES (
    v_order_code,
    p_user_id,
    p_customer_name,
    p_customer_phone,
    p_customer_email,
    p_shipping_address,
    v_subtotal,
    v_promo_discount,
    v_voucher_discount,
    v_total_discount,
    0,
    v_final_amount,
    v_deposit_paid,
    CASE WHEN v_voucher_promotion_id IS NULL THEN NULL ELSE TRIM(p_voucher_code) END,
    v_payment_method_final,
    v_payment_status,
    v_order_status
  );

  SET p_order_id = LAST_INSERT_ID();

  INSERT INTO order_items (
    order_id,
    product_id,
    product_name_snapshot,
    quantity,
    unit_price,
    discount_per_unit,
    line_total,
    is_free_gift,
    is_preorder_item,
    applied_promotion_id
  ) VALUES (
    p_order_id,
    p_product_id,
    v_main_name,
    p_quantity,
    v_main_unit_price,
    GREATEST(v_main_original - v_main_unit_price, 0),
    v_main_unit_price * p_quantity,
    0,
    CASE WHEN v_main_status = 'PRE_ORDER' THEN 1 ELSE 0 END,
    NULL
  );

  UPDATE products
  SET stock_quantity = stock_quantity - p_quantity,
      sold_count = sold_count + p_quantity
  WHERE product_id = p_product_id;

  IF v_gift_promotion_id IS NOT NULL AND v_gift_qty > 0 THEN
    INSERT INTO order_items (
      order_id,
      product_id,
      product_name_snapshot,
      quantity,
      unit_price,
      discount_per_unit,
      line_total,
      is_free_gift,
      is_preorder_item,
      applied_promotion_id
    )
    SELECT
      p_order_id,
      gp.product_id,
      gp.name,
      v_gift_qty,
      COALESCE(gp.sale_price, gp.original_price),
      COALESCE(gp.sale_price, gp.original_price),
      0,
      1,
      0,
      v_gift_promotion_id
    FROM products gp
    WHERE gp.product_id = v_gift_product_id;

    UPDATE products
    SET stock_quantity = stock_quantity - v_gift_qty,
        sold_count = sold_count + v_gift_qty
    WHERE product_id = v_gift_product_id;

    INSERT INTO promotion_usages (promotion_id,order_id,user_id,discount_saved)
    VALUES (v_gift_promotion_id,p_order_id,p_user_id,v_promo_discount);

    UPDATE promotions
    SET used_count = used_count + 1
    WHERE promotion_id = v_gift_promotion_id;
  END IF;

  IF v_voucher_promotion_id IS NOT NULL THEN
    INSERT INTO promotion_usages (promotion_id,order_id,user_id,discount_saved)
    VALUES (v_voucher_promotion_id,p_order_id,p_user_id,v_voucher_discount);

    UPDATE promotions
    SET used_count = used_count + 1
    WHERE promotion_id = v_voucher_promotion_id;
  END IF;

  IF v_flash_promotion_id IS NOT NULL THEN
    INSERT INTO promotion_usages (promotion_id,order_id,user_id,discount_saved)
    VALUES (
      v_flash_promotion_id,
      p_order_id,
      p_user_id,
      GREATEST((COALESCE(v_main_sale, v_main_original) - v_main_unit_price) * p_quantity, 0)
    );

    UPDATE promotions
    SET used_count = used_count + 1
    WHERE promotion_id = v_flash_promotion_id;
  END IF;

  COMMIT;

  SET p_order_code = v_order_code;
  SET p_message = 'Order placed successfully';
END$$

DELIMITER ;

SET FOREIGN_KEY_CHECKS = 1;

-- Kiểm tra sau khi import:
-- SELECT * FROM vw_product_catalog_pricing;
-- SELECT * FROM vw_promotion_performance;
