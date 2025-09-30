/**
 * @file commerceHandler.ts
 * Handler Layer (API Routes/Endpoints):
 * @purpose This is the outermost layer that receives HTTP requests and sends HTTP responses.
 * @Responsibilities It handles protocol-specific tasks like parsing incoming request data 
 * (JSON, query parameters), validating basic input format, routing requests to the appropriate 
 * controller, and returning the controller's response to the client with the correct status codes 
 * and data formatting. 
 */

import type { Request, Response } from "express";
import { z, ZodError } from "zod";

import * as commerceController from "../controllers/commerceController";
import { CommerceValidationError } from "../services/commerceService";

const basicSettlePayloadSchema = z.object({
    comercioNombre: z.string().trim().min(1),
    localNombre: z.string().trim().min(1),
    usuarioId: z.union([z.number(), z.string().trim().min(1)]),
    computadora: z.string().trim().min(1)
}).strict(); 

export const settleCommerceHandler = async (req: Request, res: Response) => {
    try {
        const payload = basicSettlePayloadSchema.parse(req.body);
        const result = await commerceController.settleCommerce(payload);
        res.status(200).json(result);
    } catch (error: unknown) {
        if (error instanceof ZodError) {
            return res.status(400).json({ message: "Invalid settle payload", errors: error.issues });
        }

        if (error instanceof CommerceValidationError) {
            return res.status(400).json({ message: error.message });
        }

        const err = error as any;

        if (err?.http) {
            return res.status(err.http.status).json({ message: err.message, code: err.code });
        }

        if (err?.sqlState === "45000" || err?.errno === 1644) {
            return res.status(400).json({ message: err.sqlMessage || "Database validation error" });
        }

        console.error(error);
        res.status(500).json({ message: "Unexpected server error" });
    }
};
