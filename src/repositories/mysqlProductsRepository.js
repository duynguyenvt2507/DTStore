function createMySqlProductsRepository(pool) {
  const priceExpression = `GREATEST(0, CASE
    WHEN fs.flash_sale_price IS NOT NULL THEN fs.flash_sale_price
    WHEN p.sale_price IS NOT NULL AND p.sale_price > 0 THEN p.sale_price
    ELSE p.original_price
  END)`;

  const flashSaleJoin = `
  LEFT JOIN (
    SELECT
      r.target_id AS product_id,
      MIN(GREATEST(0, r.flash_sale_price)) AS flash_sale_price,
      MAX(pm.end_date) AS flash_sale_end_time,
      MIN(pm.promotion_id) AS flash_sale_promotion_id,
      SUBSTRING_INDEX(
        GROUP_CONCAT(pm.name ORDER BY pm.priority ASC, pm.end_date ASC SEPARATOR '||'),
        '||',
        1
      ) AS flash_sale_campaign_name
    FROM promotion_rules r
    JOIN promotions pm ON pm.promotion_id = r.promotion_id
    WHERE pm.promotion_type = 'FLASH_SALE'
      AND pm.is_active = 1
      AND NOW() BETWEEN pm.start_date AND pm.end_date
      AND r.target_type = 'PRODUCT'
      AND r.flash_sale_price IS NOT NULL
    GROUP BY r.target_id
  ) fs ON fs.product_id = p.product_id`;

  function buildWhere(filters) {
    const conditions = ['p.is_active = 1'];
    const params = [];

    if (filters.search) {
      conditions.push('(p.name LIKE ? OR p.sku LIKE ?)');
      const searchTerm = `%${filters.search}%`;
      params.push(searchTerm, searchTerm);
    }

    if (filters.category) {
      conditions.push('(c.slug = ? OR c.code = ? OR c.name LIKE ?)');
      params.push(filters.category, filters.category, `%${filters.category}%`);
    }

    if (filters.categoryCode) {
      conditions.push('c.code = ?');
      params.push(filters.categoryCode);
    }

    if (filters.brand) {
      conditions.push('(b.slug = ? OR b.name LIKE ?)');
      params.push(filters.brand, `%${filters.brand}%`);
    }

    if (filters.series) {
      conditions.push('(s.slug = ? OR s.name LIKE ?)');
      params.push(filters.series, `%${filters.series}%`);
    }

    if (filters.status) {
      conditions.push('p.product_status = ?');
      params.push(filters.status);
    }

    if (filters.minPrice !== null) {
      conditions.push(`${priceExpression} >= ?`);
      params.push(filters.minPrice);
    }

    if (filters.maxPrice !== null) {
      conditions.push(`${priceExpression} <= ?`);
      params.push(filters.maxPrice);
    }

    return {
      whereClause: `WHERE ${conditions.join(' AND ')}`,
      params,
    };
  }

  function resolveSort(sort) {
    switch (sort) {
      case 'price_asc':
        return `${priceExpression} ASC, p.product_id DESC`;
      case 'price_desc':
        return `${priceExpression} DESC, p.product_id DESC`;
      case 'name_asc':
        return 'p.name ASC, p.product_id DESC';
      case 'name_desc':
        return 'p.name DESC, p.product_id DESC';
      case 'newest':
      default:
        return 'p.created_at DESC, p.product_id DESC';
    }
  }

  async function listProducts(filters) {
    const { whereClause, params } = buildWhere(filters);
    const offset = (filters.page - 1) * filters.limit;
    const orderByClause = resolveSort(filters.sort);

    const listSql = `
      SELECT
        p.product_id,
        p.sku,
        p.name,
        p.slug,
        c.code AS category_code,
        c.name AS category_name,
        b.name AS brand_name,
        s.name AS series_name,
        GREATEST(0, p.original_price) AS original_price,
        CASE WHEN p.sale_price IS NULL THEN NULL ELSE GREATEST(0, p.sale_price) END AS sale_price,
        p.stock_quantity,
        p.product_status,
        p.deposit_percent,
        p.release_date,
        p.preorder_deadline,
        p.character_name,
        p.scale_ratio,
        p.height_cm,
        p.material,
        pi.image_url AS primary_image_url,
        fs.flash_sale_price,
        fs.flash_sale_end_time,
        fs.flash_sale_promotion_id,
        fs.flash_sale_campaign_name,
        p.created_at
      FROM products p
      JOIN categories c ON c.category_id = p.category_id
      LEFT JOIN brands b ON b.brand_id = p.brand_id
      LEFT JOIN series s ON s.series_id = p.series_id
      LEFT JOIN product_images pi ON pi.product_id = p.product_id AND pi.is_primary = 1
      ${flashSaleJoin}
      ${whereClause}
      ORDER BY ${orderByClause}
      LIMIT ? OFFSET ?`;

    const countSql = `
      SELECT COUNT(DISTINCT p.product_id) AS total
      FROM products p
      JOIN categories c ON c.category_id = p.category_id
      LEFT JOIN brands b ON b.brand_id = p.brand_id
      LEFT JOIN series s ON s.series_id = p.series_id
      ${flashSaleJoin}
      ${whereClause}`;

    const [rows] = await pool.execute(listSql, [...params, filters.limit, offset]);
    const [countRows] = await pool.execute(countSql, params);

    return {
      items: rows,
      total: Number(countRows[0]?.total || 0),
    };
  }

  async function getProductBySlug(slug) {
    const detailSql = `
      SELECT
        p.product_id,
        p.sku,
        p.name,
        p.slug,
        c.code AS category_code,
        c.name AS category_name,
        b.name AS brand_name,
        s.name AS series_name,
        GREATEST(0, p.original_price) AS original_price,
        CASE WHEN p.sale_price IS NULL THEN NULL ELSE GREATEST(0, p.sale_price) END AS sale_price,
        p.stock_quantity,
        p.product_status,
        p.deposit_percent,
        p.release_date,
        p.preorder_deadline,
        p.character_name,
        p.scale_ratio,
        p.height_cm,
        p.material,
        pi.image_url AS primary_image_url,
        fs.flash_sale_price,
        fs.flash_sale_end_time,
        fs.flash_sale_promotion_id,
        fs.flash_sale_campaign_name
      FROM products p
      JOIN categories c ON c.category_id = p.category_id
      LEFT JOIN brands b ON b.brand_id = p.brand_id
      LEFT JOIN series s ON s.series_id = p.series_id
      LEFT JOIN product_images pi ON pi.product_id = p.product_id AND pi.is_primary = 1
      ${flashSaleJoin}
      WHERE p.is_active = 1 AND p.slug = ?
      LIMIT 1`;

    const [rows] = await pool.execute(detailSql, [slug]);
    if (!rows[0]) {
      return null;
    }

    const product = rows[0];

    const [images] = await pool.execute(
      `SELECT image_url, alt_text, is_primary, sort_order
       FROM product_images
       WHERE product_id = ?
       ORDER BY is_primary DESC, sort_order ASC, image_id ASC`,
      [product.product_id],
    );

    return {
      ...product,
      images,
    };
  }

  return {
    listProducts,
    getProductBySlug,
  };
}

module.exports = {
  createMySqlProductsRepository,
};
