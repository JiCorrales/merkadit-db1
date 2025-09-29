import type { PoolConnection, RowDataPacket } from "mysql2/promise";

import pool from "../config/db";

export type SettleCommerceParams = {
    comercioNombre: string
    localNombre: string
    usuarioId: number
    computadora: string
}

export type SettleCommerceResult = {
    success: boolean
    message: string
    settlementId?: number
    totalVentas?: number
    montoComision?: number
    montoTenant?: number
}

const callSettleCommerce = async (connection: PoolConnection, params: SettleCommerceParams): Promise<void> => {
    const args = [
        params.comercioNombre,
        params.localNombre,
        params.usuarioId,
        params.computadora
    ]

    await connection.query("CALL settleCommerce(?, ?, ?, ?)", args)
}

/**
 * The function `settleCommerce` processes the settlement for a commerce/local combination
 * @param {SettleCommerceParams} params - The parameters object containing commerce settlement details
 * @returns The `settleCommerce` function returns a `Promise` that resolves to a `SettleCommerceResult`
 * object containing settlement information and confirmation of the operation.
 */
export const settleCommerce = async (params: SettleCommerceParams): Promise<SettleCommerceResult> => {
    const connection = await pool.getConnection()
    try {
        await callSettleCommerce(connection, params)

        // The stored procedure handles all the logic, so if we get here, it was successful
        return {
            success: true,
            message: "Commerce settlement completed successfully"
        }
    } finally {
        connection.release();
    }
}