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
