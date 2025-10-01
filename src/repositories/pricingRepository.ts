import type { RowDataPacket } from "mysql2/promise";

import pool from "../config/db";

/**
 * The SalePricing type defines the pricing details for a product sale including kiosk, product,
 * and pricing identifiers.
 * @property {number} kioskId - Unique identifier of the kiosk associated with the sale pricing
 * record.
 * @property {number} productId - Unique identifier of the product being sold.
 * @property {number} productPriceId - Identifier of the active price entry used for the sale.
 * @property {number} unitPrice - Monetary value applied per unit for the product.
 */
export type SalePricing = {
    kioskId: number;
    productId: number;
    productPriceId: number;
    unitPrice: number;
}

/* The `pricingLookupQuery` constant contains a SQL statement used to resolve the current pricing
information for a given kiosk name and product name. */
const pricingLookupQuery = [
    "SELECT",
    "    k.kioskID AS kioskId,",
    "    p.productID AS productId,",
    "    pp.productPriceID AS productPriceId,",
    "    pp.price AS unitPrice",
    "FROM mk_kiosks k",
    "    INNER JOIN mk_products p ON p.kioskID = k.kioskID",
    "    INNER JOIN mk_productPrices pp ON pp.productID = p.productID",
    "",
    "WHERE k.kioskName = ?",
    "  AND p.name = ?",
    "  AND pp.currentPrice = 1",
    "ORDER BY pp.postTime DESC, pp.productPriceID DESC",
    "LIMIT 1;"
].join("\n")

/**
 * Retrieves sale pricing information for a product sold from a kiosk identified by name.
 * @param {string} localName - Logical kiosk identifier used by the API (matches `kioskName`).
 * @param {string} productName - Product name to resolve pricing information for.
 * @returns Pricing data if found; otherwise `null`.
 */
export const getSalePricing = async (localName: string, productName: string): Promise<SalePricing | null> => {
    const [rows] = await pool.query<RowDataPacket[]>(pricingLookupQuery, [localName, productName]);
    const pricing = rows[0];
    if (!pricing) {
        return null;
    }

    return {
        kioskId: Number(pricing.kioskId),
        productId: Number(pricing.productId),
        productPriceId: Number(pricing.productPriceId),
        unitPrice: Number(pricing.unitPrice)
    };
}

/**
 * Retrieves only the unit price for the requested kiosk/product combination.
 * @param {string} localName - Logical kiosk identifier used by the API (matches `kioskName`).
 * @param {string} productName - Product name to resolve pricing information for.
 * @returns Unit price if available, otherwise `null`.
 */
export const getUnitPrice = async (localName: string, productName: string): Promise<number | null> => {
    const pricing = await getSalePricing(localName, productName);
    return pricing ? pricing.unitPrice : null;
}
