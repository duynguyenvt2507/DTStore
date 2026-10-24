const { ApiError } = require('../errors');

const ALLOWED_STATUSES = new Set(['IN_STOCK', 'PRE_ORDER', 'OUT_OF_STOCK', 'CONTACT_PRICE']);
const ALLOWED_SORTS = new Set(['newest', 'price_asc', 'price_desc', 'name_asc', 'name_desc']);
const MAX_LIMIT = 100;

function getSingleQueryValue(value, field) {
  if (Array.isArray(value)) {
    throw new ApiError(400, 'INVALID_QUERY', `Query parameter '${field}' must be a single value.`);
  }
  return value;
}

function parseInteger(value, field, fallback) {
  if (value === undefined || value === null || value === '') {
    return fallback;
  }
  const parsed = Number.parseInt(value, 10);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new ApiError(400, 'INVALID_QUERY', `Query parameter '${field}' must be a positive integer.`);
  }
  return parsed;
}

function parsePrice(value, field) {
  if (value === undefined || value === null || value === '') {
    return null;
  }
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < 0) {
    throw new ApiError(400, 'INVALID_QUERY', `Query parameter '${field}' must be a non-negative number.`);
  }
  return parsed;
}

function parseListQuery(query) {
  const pageRaw = getSingleQueryValue(query.page, 'page');
  const limitRaw = getSingleQueryValue(query.limit, 'limit');
  const statusRaw = getSingleQueryValue(query.status, 'status');
  const sortRaw = getSingleQueryValue(query.sort, 'sort');
  const minPriceRaw = getSingleQueryValue(query.minPrice, 'minPrice');
  const maxPriceRaw = getSingleQueryValue(query.maxPrice, 'maxPrice');

  const page = parseInteger(pageRaw, 'page', 1);
  const limit = parseInteger(limitRaw, 'limit', 20);

  if (limit > MAX_LIMIT) {
    throw new ApiError(400, 'INVALID_QUERY', `Query parameter 'limit' must be <= ${MAX_LIMIT}.`);
  }

  let status = null;
  if (statusRaw) {
    if (!ALLOWED_STATUSES.has(statusRaw)) {
      throw new ApiError(400, 'INVALID_QUERY', 'Invalid status value.');
    }
    status = statusRaw;
  }

  const sort = sortRaw || 'newest';
  if (!ALLOWED_SORTS.has(sort)) {
    throw new ApiError(400, 'INVALID_QUERY', 'Invalid sort value.');
  }

  const minPrice = parsePrice(minPriceRaw, 'minPrice');
  const maxPrice = parsePrice(maxPriceRaw, 'maxPrice');

  if (minPrice !== null && maxPrice !== null && minPrice > maxPrice) {
    throw new ApiError(400, 'INVALID_QUERY', 'minPrice must be less than or equal to maxPrice.');
  }

  return {
    page,
    limit,
    search: getSingleQueryValue(query.search, 'search') || null,
    category: getSingleQueryValue(query.category, 'category') || null,
    categoryCode: getSingleQueryValue(query.categoryCode, 'categoryCode') || null,
    brand: getSingleQueryValue(query.brand, 'brand') || null,
    series: getSingleQueryValue(query.series, 'series') || null,
    status,
    minPrice,
    maxPrice,
    sort,
  };
}

function validateSlug(slug) {
  if (typeof slug !== 'string' || slug.length === 0 || slug.length > 320) {
    throw new ApiError(400, 'INVALID_SLUG', 'Slug is invalid.');
  }

  if (!/^[A-Za-z0-9-]+$/.test(slug)) {
    throw new ApiError(400, 'INVALID_SLUG', 'Slug is invalid.');
  }

  return slug;
}

module.exports = {
  parseListQuery,
  validateSlug,
};
