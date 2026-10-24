const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const { createApp } = require('../src/app');

const now = new Date('2026-10-24T00:00:00.000Z');

function deriveFinalPrice(product) {
  if (product.flash_sale_price !== null && product.flash_sale_price !== undefined && (!product.flash_sale_end_time || new Date(product.flash_sale_end_time) >= now)) {
    return Math.max(0, Number(product.flash_sale_price));
  }
  if (product.sale_price !== null && product.sale_price !== undefined && Number(product.sale_price) > 0) {
    return Math.max(0, Number(product.sale_price));
  }
  return Math.max(0, Number(product.original_price));
}

const baseProducts = [
  {
    product_id: 1,
    sku: 'SKU-001',
    name: 'Asaba Harumasa Figure',
    slug: 'asaba-harumasa-figure',
    category_code: 'SCALE',
    category_name: 'Scale Figure',
    brand_name: 'Myethos',
    series_name: 'Zenless Zone Zero',
    original_price: 2000000,
    sale_price: 1700000,
    flash_sale_price: 1500000,
    flash_sale_end_time: '2099-12-31T23:59:59.000Z',
    flash_sale_promotion_id: 5,
    flash_sale_campaign_name: 'Flash Sale Đếm Ngược',
    stock_quantity: 8,
    product_status: 'IN_STOCK',
    deposit_percent: 0,
    release_date: '2026-08-15',
    preorder_deadline: null,
    character_name: 'Asaba Harumasa',
    scale_ratio: '1/8',
    height_cm: 24.5,
    material: 'PVC, ABS',
    primary_image_url: '/assets/images/products/asaba.jpg',
    images: [
      { image_url: '/assets/images/products/asaba.jpg', alt_text: 'Asaba', is_primary: 1, sort_order: 1 },
      { image_url: '/assets/images/products/asaba-2.jpg', alt_text: 'Asaba Side', is_primary: 0, sort_order: 2 },
    ],
    created_at: '2026-08-15T00:00:00.000Z',
  },
  {
    product_id: 2,
    sku: 'SKU-002',
    name: 'Kasane Teto Nendoroid',
    slug: 'kasane-teto-nendoroid',
    category_code: 'NENDOROID',
    category_name: 'Nendoroid',
    brand_name: 'Good Smile Company',
    series_name: 'Vocaloid / Hatsune Miku',
    original_price: 1500000,
    sale_price: 1200000,
    flash_sale_price: null,
    flash_sale_end_time: null,
    flash_sale_promotion_id: null,
    flash_sale_campaign_name: null,
    stock_quantity: 5,
    product_status: 'PRE_ORDER',
    deposit_percent: 30,
    release_date: '2026-12-20',
    preorder_deadline: '2026-11-30',
    character_name: 'Kasane Teto',
    scale_ratio: 'Non-scale',
    height_cm: 10,
    material: 'PVC, ABS',
    primary_image_url: '/assets/images/products/teto.jpg',
    images: [{ image_url: '/assets/images/products/teto.jpg', alt_text: 'Teto', is_primary: 1, sort_order: 1 }],
    created_at: '2026-07-01T00:00:00.000Z',
  },
  {
    product_id: 3,
    sku: 'SKU-003',
    name: 'Mica Display Box',
    slug: 'mica-display-box',
    category_code: 'ACCESSORY',
    category_name: 'Accessory',
    brand_name: 'M Figure Gear',
    series_name: null,
    original_price: 250000,
    sale_price: null,
    flash_sale_price: null,
    flash_sale_end_time: null,
    flash_sale_promotion_id: null,
    flash_sale_campaign_name: null,
    stock_quantity: 50,
    product_status: 'IN_STOCK',
    deposit_percent: 0,
    release_date: null,
    preorder_deadline: null,
    character_name: 'Display Box',
    scale_ratio: '30x25x25cm',
    height_cm: 30,
    material: 'Acrylic MICA + LED',
    primary_image_url: '/assets/images/products/mica.jpg',
    images: [{ image_url: '/assets/images/products/mica.jpg', alt_text: 'Mica', is_primary: 1, sort_order: 1 }],
    created_at: '2026-04-01T00:00:00.000Z',
  },
];

function createMockRepository(products = baseProducts) {
  return {
    async listProducts(filters) {
      let rows = products.slice();

      if (filters.search) {
        const search = filters.search.toLowerCase();
        rows = rows.filter((item) => item.name.toLowerCase().includes(search) || item.sku.toLowerCase().includes(search));
      }

      if (filters.category) {
        const category = filters.category.toLowerCase();
        rows = rows.filter((item) =>
          (item.category_name || '').toLowerCase().includes(category) ||
          (item.category_code || '').toLowerCase() === category,
        );
      }

      if (filters.categoryCode) {
        rows = rows.filter((item) => item.category_code === filters.categoryCode);
      }

      if (filters.brand) {
        const brand = filters.brand.toLowerCase();
        rows = rows.filter((item) => (item.brand_name || '').toLowerCase().includes(brand));
      }

      if (filters.series) {
        const series = filters.series.toLowerCase();
        rows = rows.filter((item) => (item.series_name || '').toLowerCase().includes(series));
      }

      if (filters.status) {
        rows = rows.filter((item) => item.product_status === filters.status);
      }

      if (filters.minPrice !== null) {
        rows = rows.filter((item) => deriveFinalPrice(item) >= filters.minPrice);
      }

      if (filters.maxPrice !== null) {
        rows = rows.filter((item) => deriveFinalPrice(item) <= filters.maxPrice);
      }

      if (filters.sort === 'price_asc') {
        rows.sort((a, b) => deriveFinalPrice(a) - deriveFinalPrice(b));
      }

      const total = rows.length;
      const start = (filters.page - 1) * filters.limit;
      const end = start + filters.limit;

      return {
        items: rows.slice(start, end),
        total,
      };
    },

    async getProductBySlug(slug) {
      return products.find((item) => item.slug === slug) || null;
    },
  };
}

test('GET /products returns default paginated list', async () => {
  const app = createApp({ productsRepository: createMockRepository() });
  const response = await request(app).get('/products');

  assert.equal(response.status, 200);
  assert.equal(response.body.metadata.page, 1);
  assert.equal(response.body.metadata.limit, 20);
  assert.equal(response.body.metadata.total, 3);
  assert.equal(response.body.data.length, 3);
});

test('GET /products supports pagination', async () => {
  const app = createApp({ productsRepository: createMockRepository() });
  const response = await request(app).get('/products?page=2&limit=1');

  assert.equal(response.status, 200);
  assert.equal(response.body.metadata.page, 2);
  assert.equal(response.body.metadata.limit, 1);
  assert.equal(response.body.metadata.totalPages, 3);
  assert.equal(response.body.data.length, 1);
});

test('GET /products supports search and filters', async () => {
  const app = createApp({ productsRepository: createMockRepository() });
  const response = await request(app).get('/products?search=SKU-002&categoryCode=NENDOROID&brand=good&series=vocaloid&status=PRE_ORDER&minPrice=1000000&maxPrice=1300000');

  assert.equal(response.status, 200);
  assert.equal(response.body.metadata.total, 1);
  assert.equal(response.body.data[0].sku, 'SKU-002');
});

test('GET /products uses flash sale then sale then original for display price', async () => {
  const app = createApp({ productsRepository: createMockRepository() });
  const response = await request(app).get('/products?sort=price_asc');

  assert.equal(response.status, 200);
  const bySku = Object.fromEntries(response.body.data.map((item) => [item.sku, item]));

  assert.equal(bySku['SKU-001'].final_display_price, 1500000);
  assert.equal(bySku['SKU-002'].final_display_price, 1200000);
  assert.equal(bySku['SKU-003'].final_display_price, 250000);
  assert.equal(bySku['SKU-001'].promotion_badge.type, 'FLASH_SALE');
});

test('GET /products rejects invalid query and limit overflow', async () => {
  const app = createApp({ productsRepository: createMockRepository() });
  const response = await request(app).get('/products?limit=999&status=INVALID');

  assert.equal(response.status, 400);
  assert.equal(response.body.error.code, 'INVALID_QUERY');
});

test('GET /products/:slug returns detail with images', async () => {
  const app = createApp({ productsRepository: createMockRepository() });
  const response = await request(app).get('/products/asaba-harumasa-figure');

  assert.equal(response.status, 200);
  assert.equal(response.body.data.slug, 'asaba-harumasa-figure');
  assert.equal(response.body.data.images.length, 2);
});

test('GET /products/:slug returns 404 when not found', async () => {
  const app = createApp({ productsRepository: createMockRepository() });
  const response = await request(app).get('/products/not-found-slug');

  assert.equal(response.status, 404);
  assert.equal(response.body.error.code, 'PRODUCT_NOT_FOUND');
});

test('GET /products/:slug rejects invalid slug format', async () => {
  const app = createApp({ productsRepository: createMockRepository() });
  const response = await request(app).get('/products/invalid_slug');

  assert.equal(response.status, 400);
  assert.equal(response.body.error.code, 'INVALID_SLUG');
});
