# DTStore SQL Foundation

Repository này chứa schema + seed cho MySQL/MariaDB và procedure checkout transaction an toàn.
Seed có kèm 1 đơn hàng demo (`orders`, `order_items`, `promotion_usages`) để tham chiếu dữ liệu lịch sử.

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
# DTStore Database Foundation

Repository này hiện tập trung vào **Database Foundation** cho MySQL/MariaDB (chưa bao gồm backend/frontend).

## Yêu cầu hệ thống

- MySQL **8.0+** hoặc MariaDB **10.4+**
- Quyền tạo database/table/view/procedure
- Charset: `utf8mb4`

## Import schema + seed

Tại thư mục repository:

```bash
mysql -u <user> -p < mfigure_database_schema_and_seed.sql
```

Script có thể chạy lại (idempotent) vì đã `DROP ... IF EXISTS` trước khi tạo lại object.

## Chạy SQL test

```bash
mysql -u <user> -p < mfigure_database_schema_and_seed_test.sql
```

Script test sẽ:

- Import lại schema/seed từ đầu (2 lần để kiểm tra re-run)
- Kiểm tra table/view/procedure tồn tại
- Kiểm tra số lượng seed tối thiểu
- Kiểm tra view pricing trả về giá hợp lệ
- Test checkout thành công với Scale + quà MICA
- Test pre-order deposit
- Test rollback khi đặt vượt tồn kho

## Demo gọi procedure checkout

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
  2,
  101,
  1,
  'MFIGURE100',
  'Nguyen Van A',
  '0901234567',
  'a@example.com',
  'Ha Noi',
  'BANK_TRANSFER',
  @order_id,
  @order_code,
  @message
);

SELECT @order_id, @order_code, @message;
```

## Giới hạn hiện tại

- Stored procedure hiện chỉ bao phủ **flow checkout demo cho 1 dòng sản phẩm chính** với voucher + quà tặng BUY_X_GET_Y.
- Promotion Engine đầy đủ cho cart nhiều sản phẩm/rule phức tạp sẽ được triển khai ở backend ở bước sau.

## Lưu ý bảo mật seed

Seed users chứa `password_hash` **chỉ để demo dữ liệu** (không dùng production).
