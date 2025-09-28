import type { PoolConnection, RowDataPacket } from "mysql2/promise";

import pool from "../config/db";

export type RegisterSaleParams = {
    productName: string
    localName: string
    qtySold: number
    amountPaid: number
    paymentMethod: string
    paymentConfirmations: string
    referenceNumbers: string | null
    invoiceNumber: number
    clientCode: string
    discountApplied: number
    userId: number
}

export type RegisterSaleResult = {
    receiptId: number
    invoiceNumber: number
    total: number
}

const receiptLookupQuery = [
    "SELECT",
    "    r.receiptID AS receiptId,",
    "    r.receiptNumber AS invoiceNumber,",
    "    r.total AS total",
    "FROM mk_receipts r",
    "    INNER JOIN mk_kiosks k ON k.kioskID = r.kioskID",
    "    INNER JOIN mk_locals l ON l.localID = k.localID",
    "WHERE r.receiptNumber = ?",
    "  AND l.localName = ?",
    "ORDER BY r.postTime DESC",
    "LIMIT 1;"
].join("\n")

const callRegisterSale = async (connection: PoolConnection, params: RegisterSaleParams): Promise<void> => {
    const args = [
        params.productName,
        params.localName,
        params.qtySold,
        params.amountPaid,
        params.paymentMethod,
        params.paymentConfirmations,
        params.referenceNumbers,
        params.invoiceNumber,
        params.clientCode,
        params.discountApplied,
        params.userId
    ]

    await connection.query("CALL registerSale(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", args)
}

/**
 * The function `registerSale` registers a sale, retrieves the receipt, and returns specific details of
 * the receipt.
 * @param {RegisterSaleParams} params - The `params` object in the `registerSale` function likely
 * contains information related to a sale transaction. It seems to include properties such as
 * `invoiceNumber` and `localName`. These parameters are used to register a sale, retrieve the
 * corresponding receipt, and then return specific details from that receipt like
 * @returns The `registerSale` function returns a `Promise` that resolves to a `RegisterSaleResult`
 * object. The `RegisterSaleResult` object contains the following properties:
 * - `receiptId`: A number representing the receipt ID retrieved after registering the sale.
 * - `invoiceNumber`: A number representing the invoice number used for the sale.
 * - `total`: A number representing the total amount of the sale
 */
export const registerSale = async (params: RegisterSaleParams): Promise<RegisterSaleResult> => {
    const connection = await pool.getConnection()
    try {
        await callRegisterSale(connection, params)

        const [rows] = await connection.query<RowDataPacket[]>(
            receiptLookupQuery,
            [params.invoiceNumber, params.localName]
        )

        const receipt = rows[0]
        if (!receipt) {
            throw new Error("Failed to retrieve receipt after registering sale")
        }

        return {
            receiptId: Number(receipt.receiptId),
            invoiceNumber: Number(receipt.invoiceNumber),
            total: Number(receipt.total)
        }
    } finally {
        connection.release();
    }
}
