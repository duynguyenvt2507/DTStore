# DTStore SQL Foundation

Repository này chứa schema + seed cho MySQL/MariaDB và procedure checkout transaction an toàn.

## Yêu cầu môi trường

- MySQL 8.0+ hoặc MariaDB 10.4+
- Quyền tạo database/table/view/procedure

## Import schema + seed

```bash
mysql -u <user> -p < /home/runner/work/DTStore/DTStore/mfigure_database_schema_and_seed.sql
```

## Procedure checkout

Procedure:

- `sp_place_order_with_promotions`
- Có dùng `START TRANSACTION`, `SELECT ... FOR UPDATE`, `COMMIT`, handler `ROLLBACK`
- Tự tính giá từ dữ liệu server và xử lý BUY_X_GET_Y + pre-order deposit

Ví dụ gọi:

```sql
USE mfigure_shop;

CALL sp_place_order_with_promotions(
  2,                    -- p_user_id (NULL nếu khách vãng lai)
  101,                  -- p_product_id
  1,                    -- p_quantity
  0,                    -- p_use_deposit (1 cho pre-order đặt cọc)
  'BANK_TRANSFER',      -- p_payment_method
  'Nguyen Van A',       -- p_customer_name
  '0900000000',         -- p_customer_phone
  'a@example.com',      -- p_customer_email
  'Ha Noi',             -- p_shipping_address
  @o_order_id,          -- OUT order id
  @o_message            -- OUT message
);

SELECT @o_order_id, @o_message;
```

## Chạy test SQL checkout

```bash
mysql -u <user> -p < /home/runner/work/DTStore/DTStore/checkout_transaction_tests.sql
```

Script test sẽ kiểm tra:

- Checkout thành công có tạo quà tặng.
- Tồn kho sản phẩm chính/quà giảm đúng.
- Pre-order deposit tính đúng.
- Thiếu tồn kho quà hoặc hết quota promotion thì rollback, không tạo order.
- Lỗi transaction/input không tạo duplicate order.

## Giới hạn khi chạy trong cloud agent

Trong môi trường agent hiện tại chỉ có `mysql` client nhưng không có MySQL server local đang chạy, nên không thể chạy integration test thực thi trực tiếp ở đây. Thay đổi đã được kiểm tra tĩnh trên SQL script và tổ chức theo cú pháp/luồng transaction tương thích MySQL 8.0+/MariaDB 10.4+.
