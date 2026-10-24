const express = require('express');
const { ApiError } = require('./errors');
const { computePricing } = require('./utils/pricing');
const { parseListQuery, validateSlug } = require('./validation/products');

function toProductResponse(product, includeImages) {
  const pricing = computePricing(product);

  const response = {
    product_id: product.product_id,
    sku: product.sku,
    name: product.name,
    slug: product.slug,
    category: {
      code: product.category_code,
      name: product.category_name,
    },
    brand: product.brand_name,
    series: product.series_name,
    original_price: pricing.original_price,
    sale_price: pricing.sale_price,
    final_display_price: pricing.final_display_price,
    discount_percent: pricing.discount_percent,
    flash_sale: pricing.flash_sale,
    stock_quantity: product.stock_quantity,
    product_status: product.product_status,
    deposit_percent: Number(product.deposit_percent ?? 0),
    release_date: product.release_date,
    preorder_deadline: product.preorder_deadline,
    character_name: product.character_name,
    scale_ratio: product.scale_ratio,
    height_cm: product.height_cm,
    material: product.material,
    primary_image: product.primary_image_url,
    promotion_badge: pricing.flash_sale
      ? {
          type: 'FLASH_SALE',
          label: pricing.flash_sale.campaign_name || 'Flash Sale',
          ends_at: pricing.flash_sale.flash_sale_end_time,
        }
      : null,
  };

  if (includeImages) {
    response.images = Array.isArray(product.images)
      ? product.images.map((image) => ({
          image_url: image.image_url,
          alt_text: image.alt_text,
          is_primary: Boolean(image.is_primary),
          sort_order: image.sort_order,
        }))
      : [];
  }

  return response;
}

function createApp({ productsRepository }) {
  const app = express();

  app.get('/products', async (req, res, next) => {
    try {
      const filters = parseListQuery(req.query);
      const { items, total } = await productsRepository.listProducts(filters);

      const totalPages = total === 0 ? 0 : Math.ceil(total / filters.limit);

      return res.json({
        data: items.map((item) => toProductResponse(item, false)),
        metadata: {
          page: filters.page,
          limit: filters.limit,
          total,
          totalPages,
        },
      });
    } catch (error) {
      return next(error);
    }
  });

  app.get('/products/:slug', async (req, res, next) => {
    try {
      const slug = validateSlug(req.params.slug);
      const product = await productsRepository.getProductBySlug(slug);
      if (!product) {
        throw new ApiError(404, 'PRODUCT_NOT_FOUND', 'Product not found.');
      }

      return res.json({
        data: toProductResponse(product, true),
      });
    } catch (error) {
      return next(error);
    }
  });

  app.use((req, res) => {
    res.status(404).json({
      error: {
        code: 'NOT_FOUND',
        message: 'Resource not found.',
      },
    });
  });

  app.use((error, req, res, next) => {
    if (error instanceof ApiError) {
      return res.status(error.status).json({
        error: {
          code: error.code,
          message: error.message,
          details: error.details || null,
        },
      });
    }

    return res.status(500).json({
      error: {
        code: 'INTERNAL_SERVER_ERROR',
        message: 'Unexpected server error.',
      },
    });
  });

  return app;
}

module.exports = {
  createApp,
};
