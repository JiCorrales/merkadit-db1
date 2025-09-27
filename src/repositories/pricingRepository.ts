import type { RowDataPacket } from "mysql2/promise";

import pool from "../config/db";

export type SalePricing = {
    localId: number;
    kioskId: number;
    productId: number;
    productPriceId: number;
    unitPrice: number;
};

const pricingLookupQuery = [
    "SELECT",
    "    l.localID AS localId,",
    "    k.kioskID AS kioskId,",
    "    p.productID AS productId,",
    "    pp.productPriceID AS productPriceId,",
    "    pp.price AS unitPrice",
    "FROM mk_locals l",
    "    INNER JOIN mk_kiosks k ON k.localID = l.localID",
    "    INNER JOIN mk_products p ON p.kioskID = k.kioskID",
    "    INNER JOIN mk_productPrices pp ON pp.productID = p.productID",
    "WHERE l.localName = ?",
    "  AND p.name = ?",
    "  AND pp.currentPrice = 1",
    "ORDER BY pp.postTime DESC, pp.productPriceID DESC",
    "LIMIT 1;"
].join("\n");

/**
 * This TypeScript function retrieves sale pricing information based on the provided local name and
 * product name.
 * @param {string} localName - The `localName` parameter is a string that represents the name of the
 * local store where the product is being sold.
 * @param {string} productName - The `productName` parameter in the `getSalePricing` function is a
 * string that represents the name of the product for which you want to retrieve the sale pricing
 * information.
 * @returns The `getSalePricing` function returns a `Promise` that resolves to a `SalePricing` object
 * or `null`. The `SalePricing` object contains the following properties: `localId`, `kioskId`,
 * `productId`, `productPriceId`, and `unitPrice`, all of which are numbers. If no pricing information
 * is found for the specified `localName`
 */
export const getSalePricing = async (localName: string, productName: string): Promise<SalePricing | null> => {
    const [rows] = await pool.query<RowDataPacket[]>(pricingLookupQuery, [localName, productName]);
    const pricing = rows[0];
    if (!pricing) {
        return null;
    }

    return {
        localId: Number(pricing.localId),
        kioskId: Number(pricing.kioskId),
        productId: Number(pricing.productId),
        productPriceId: Number(pricing.productPriceId),
        unitPrice: Number(pricing.unitPrice)
    };
};

/**
 * The function `getUnitPrice` retrieves the unit price of a product for a specific location
 * asynchronously.
 * @param {string} localName - The `localName` parameter in the `getUnitPrice` function represents the
 * location or region where the product is being sold. It could be a specific store location, city, or
 * any other geographical identifier.
 * @param {string} productName - The `productName` parameter is a string that represents the name of
 * the product for which you want to retrieve the unit price.
 * @returns The function `getUnitPrice` is returning the unit price of a product for a specific
 * location. It first calls the `getSalePricing` function to retrieve pricing information for the given
 * `localName` and `productName`. If pricing information is available, it returns the `unitPrice` from
 * the pricing object. If pricing information is not available, it returns `null`.
 */
export const getUnitPrice = async (localName: string, productName: string): Promise<number | null> => {
    const pricing = await getSalePricing(localName, productName);
    return pricing ? pricing.unitPrice : null;
};
