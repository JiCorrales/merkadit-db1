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

/* The `basicSettlePayloadSchema` constant is defining a schema using the Zod library for validating
the payload received in the `settleCommerceHandler` function. */
const basicSettlePayloadSchema = z.object({
    comercioNombre: z.string().trim().min(1),
    localNombre: z.string().trim().min(1),
    usuarioId: z.union([z.number(), z.string().trim().min(1)]),
    computadora: z.string().trim().min(1)
}).strict(); 

/**
 * The function `settleCommerceHandler` handles settling commerce transactions, parsing the payload,
 * calling the commerce controller, and returning appropriate responses based on errors encountered.
 * @param {Request} req - The `req` parameter in the `settleCommerceHandler` function represents the
 * incoming request object. It contains information about the HTTP request made to the server, such as
 * headers, body, parameters, and query strings. In this specific context, it is of type `Request`,
 * which is likely from
 * @param {Response} res - The `res` parameter in the `settleCommerceHandler` function is an instance
 * of the `Response` class from an HTTP framework like Express.js. It is used to send the HTTP
 * response back to the client with the appropriate status code and data.
 * @returns The `settleCommerceHandler` function is returning different JSON responses based on the
 * type of error encountered:
 */
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
