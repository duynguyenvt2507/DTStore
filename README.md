# DTStore Product Catalog API

Repository này ban đầu chỉ có SQL schema/seed (`mfigure_database_schema_and_seed.sql`).
Để triển khai Product Catalog API theo issue, project dùng **Node.js + Express tối giản** (không thay đổi database stack MySQL/MariaDB hiện có).

## 1) Yêu cầu môi trường

- Node.js 18+
- MySQL 8.0+ hoặc MariaDB 10.4+

## 2) Cài đặt

```bash
npm install
cp .env.example .env
```

Cập nhật `.env`:

```env
PORT=3000
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=mfigure_shop
DB_CONNECTION_LIMIT=10
```

## 3) Tạo schema + seed database

```bash
mysql -u root -p < /home/runner/work/DTStore/DTStore/mfigure_database_schema_and_seed.sql
```

## 4) Chạy server

```bash
npm start
```

Base URL mặc định: `http://localhost:3000`

## 5) API endpoints

### `GET /products`

Danh sách sản phẩm có phân trang, search, filter, sort.

Query params:

- `page` (default `1`)
- `limit` (default `20`, max `100`)
- `search` (tìm theo `name` hoặc `sku`)
- `category` (slug/code/tên category)
- `categoryCode`
- `brand`
- `series`
- `status` (`IN_STOCK`, `PRE_ORDER`, `OUT_OF_STOCK`, `CONTACT_PRICE`)
- `minPrice`, `maxPrice`
- `sort` (`newest`, `price_asc`, `price_desc`, `name_asc`, `name_desc`)

Ví dụ:

```bash
curl "http://localhost:3000/products?page=1&limit=10&search=miku&categoryCode=PRIZE&status=IN_STOCK&sort=price_asc"
```

Response có metadata phân trang:

- `page`
- `limit`
- `total`
- `totalPages`

### `GET /products/:slug`

Chi tiết sản phẩm theo slug (có `images` list).

Ví dụ:

```bash
curl "http://localhost:3000/products/asaba-harumasa-zzz-1-8"
```

## 6) Quy tắc giá hiển thị

Server-side pricing (không dùng giá từ client):

1. Ưu tiên `flash_sale_price` khi Flash Sale còn hiệu lực.
2. Nếu không có Flash Sale thì dùng `sale_price` (nếu có).
3. Cuối cùng dùng `original_price`.

`discount_percent` được tính an toàn, tránh chia cho 0.
Giá luôn được chặn âm (`>= 0`).

## 7) Test

Project dùng test integration nhẹ với mock repository:

```bash
npm test
```

Các ca test chính:

- list mặc định + metadata phân trang
- phân trang page/limit
- search theo tên/SKU
- filter category/brand/series/status + min/max giá
- product detail theo slug + 404
- ưu tiên giá Flash Sale / Sale / Original
- input không hợp lệ + giới hạn `limit`
- slug không hợp lệ

## 8) Lint/Build/Test đã chạy trong agent

- `npm test`
- `npm run lint` (placeholder vì repo chưa có linter thực tế)

## 9) Giới hạn trong môi trường agent

- Agent không có runtime MySQL/MariaDB mặc định, nên test tự động được chạy bằng mock repository.
- Khi chạy local với DB thật, cần import SQL seed trước và cấu hình `.env` đúng.
