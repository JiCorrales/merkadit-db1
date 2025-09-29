import { z } from "zod";

import {
    settleCommerce as settleCommerceRepository,
    SettleCommerceParams,
    SettleCommerceResult
} from "../repositories/commercerRepository";

const settleCommerceSchema = z.object({
    comercioNombre: z.string().trim().min(1).max(50),
    localNombre: z.string().trim().min(1).max(45),
    usuarioId: z.coerce.number().int().positive(),
    computadora: z.string().trim().min(1).max(120)
});

export class CommerceValidationError extends Error {
    constructor(message: string) {
        super(message);
        this.name = "CommerceValidationError";
    }
}

export type SettleCommerceInput = z.infer<typeof settleCommerceSchema>;
export type SettleCommerceResponse = SettleCommerceResult & {
    message: string
};

/**
 * The function `settleCommerce` processes commerce settlement based on the provided payload.
 * @param {unknown} payload - The payload contains information about the commerce settlement
 * @returns The function `settleCommerce` is returning a `SettleCommerceResponse` object.
 */
export const settleCommerce = async (payload: unknown): Promise<SettleCommerceResponse> => {
    const data = settleCommerceSchema.parse(payload)

    const repositoryParams: SettleCommerceParams = {
        comercioNombre: data.comercioNombre,
        localNombre: data.localNombre,
        usuarioId: data.usuarioId,
        computadora: data.computadora
    };

    const result = await settleCommerceRepository(repositoryParams);

    return {
        ...result
    };
}