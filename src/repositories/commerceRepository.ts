import type { PoolConnection, ResultSetHeader, RowDataPacket } from "mysql2/promise";

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

type RawCallResult = RowDataPacket[][] | RowDataPacket[] | ResultSetHeader;

const normalizeResultSets = (rows: RawCallResult): RowDataPacket[][] => {
    if (!Array.isArray(rows)) {
        return [];
    }

    if (rows.length === 0) {
        return [];
    }

    if (Array.isArray(rows[0])) {
        return (rows as unknown as RowDataPacket[][]).filter((set) => Array.isArray(set));
    }

    return [rows as RowDataPacket[]];
};

const callSettleCommerce = async (connection: PoolConnection, params: SettleCommerceParams): Promise<RowDataPacket[][]> => {
    const args = [
        params.comercioNombre,
        params.localNombre,
        params.usuarioId,
        params.computadora
    ];

    const [rows] = await connection.query<RawCallResult>("CALL settleCommerce(?, ?, ?, ?)", args);
    return normalizeResultSets(rows);
};

/**
 * The function `settleCommerce` processes the settlement for a commerce/local combination
 * @param {SettleCommerceParams} params - The parameters object containing commerce settlement details
 * @returns The `settleCommerce` function returns a `Promise` that resolves to a `SettleCommerceResult`
 * object containing settlement information and confirmation of the operation.
 */
export const settleCommerceRepository = async (params: SettleCommerceParams): Promise<SettleCommerceResult> => {
    const connection = await pool.getConnection();
    try {
        const resultSets = await callSettleCommerce(connection, params);

        const primarySet = resultSets.find((set) => set.length > 0 && ("resultado" in (set[0] as RowDataPacket))) ?? resultSets[0];

        if (!primarySet || primarySet.length === 0) {
            return {
                success: false,
                message: "Settlement failed to produce a response"
            };
        }

        const row = primarySet[0] as RowDataPacket & {
            resultado?: string
            totalVentas?: number | string
            comisionPorcentaje?: number | string
            montoComision?: number | string
            montoTenant?: number | string
        };

        const message = typeof row.resultado === "string" ? row.resultado : "Settlement completed";
        const success = /settlement/i.test(message) && !/error/i.test(message);

        const toNumber = (value: unknown): number | undefined => {
            if (value === null || value === undefined) {
                return undefined;
            }
            const numeric = Number(value);
            return Number.isNaN(numeric) ? undefined : numeric;
        };

        return {
            success,
            message,
            totalVentas: toNumber(row.totalVentas),
            montoComision: toNumber(row.montoComision),
            montoTenant: toNumber(row.montoTenant)
        };
    } finally {
        connection.release();
    }
};
