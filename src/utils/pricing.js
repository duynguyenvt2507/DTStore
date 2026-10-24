function toMoney(value) {
  if (value === null || value === undefined) return null;
  const numberValue = Number(value);
  if (!Number.isFinite(numberValue)) return null;
  return Math.max(0, numberValue);
}

function computePricing(product, now = new Date()) {
  const original = toMoney(product.original_price) ?? 0;
  const sale = toMoney(product.sale_price);
  const flash = toMoney(product.flash_sale_price);

  let useFlash = false;
  if (flash !== null) {
    if (!product.flash_sale_end_time) {
      useFlash = true;
    } else {
      const flashEnd = new Date(product.flash_sale_end_time);
      useFlash = !Number.isNaN(flashEnd.getTime()) && flashEnd >= now;
    }
  }

  let finalPrice = original;
  if (useFlash) {
    finalPrice = flash;
  } else if (sale !== null && sale > 0) {
    finalPrice = sale;
  }

  finalPrice = Math.max(0, finalPrice);

  let discountPercent = 0;
  if (original > 0 && finalPrice < original) {
    discountPercent = Math.round(((original - finalPrice) / original) * 100);
  }

  return {
    original_price: original,
    sale_price: sale,
    final_display_price: finalPrice,
    discount_percent: Math.max(0, discountPercent),
    flash_sale: useFlash
      ? {
          flash_sale_price: flash,
          flash_sale_end_time: product.flash_sale_end_time,
          promotion_id: product.flash_sale_promotion_id ?? null,
          campaign_name: product.flash_sale_campaign_name ?? null,
        }
      : null,
  };
}

module.exports = {
  computePricing,
};
