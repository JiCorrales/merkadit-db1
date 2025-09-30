/**
 * @file saleHandler.ts
 * Handler Layer (API Routes/Endpoints):
 * @purpose This is the outermost layer that receives HTTP requests and sends HTTP responses.
 * @Responsibilities It handles protocol-specific tasks like parsing incoming request data 
 * (JSON, query parameters), validating basic input format, routing requests to the appropriate 
 * controller, and returning the controller's response to the client with the correct status codes 
 * and data formatting. 
 */
import type { Request, Response } from "express";
import { z, ZodError } from "zod";
import * as saleController from "../controllers/saleController";
import { SaleValidationError } from "../services/saleService";

/* The `basicSalePayloadSchema` constant is defining a schema using Zod, a TypeScript-first schema
declaration and validation library. This schema is used to validate the structure and data types of
the payload received in the HTTP request body for registering a sale. */
const basicSalePayloadSchema = z.object({
    productName: z.string().trim().min(1),
    localName: z.string().trim().min(1),
    qtySold: z.union([z.number(), z.string().trim().min(1)]),
    amountPaid: z.union([z.number(), z.string().trim().min(1)]),
    paymentMethod: z.string().trim().min(1),
    paymentConfirmations: z.string().trim().min(1),
    referenceNumbers: z.union([z.string().trim(), z.literal("")]).nullish(),
    invoiceNumber: z.union([z.number(), z.string().trim().min(1)]),
    clientCode: z.string().trim().min(1),
    discountApplied: z.union([z.number(), z.string().trim()]).default(0),
    userId: z.union([z.number(), z.string().trim().min(1)])
}).strict();

/**
 * The function `registerSaleHandler` handles the registration of a sale, parsing the payload, calling
 * the sale controller, and handling various types of errors that may occur.
 * @param {Request} req - The `req` parameter in the `registerSaleHandler` function represents the
 * incoming request object. It contains information about the HTTP request made to the server,
 * including headers, parameters, body, and other details sent by the client. In this specific
 * context, it is of type `Request`, which is
 * @param {Response} res - The `res` parameter in the `registerSaleHandler` function is an instance of
 * the `Response` class from an HTTP framework like Express.js. It is used to send the HTTP response
 * back to the client with the appropriate status code and response data. In this function, it is used
 * to send
 * @returns The `registerSaleHandler` function is returning different responses based on the type of
 * error encountered during the processing of a sale registration request. Here are the possible
 * return scenarios:
 */
export const registerSaleHandler = async (req: Request, res: Response) => {
    try {
        const payload = basicSalePayloadSchema.parse(req.body);
        const result = await saleController.registerSale(payload);
        res.status(201).json(result);
    } catch (error: unknown) {
        if (error instanceof ZodError) {
            return res.status(400).json({ message: "Invalid sale payload", errors: error.issues });
        }

        if (error instanceof SaleValidationError) {
            return res.status(400).json({ message: error.message });
        }

        const err = error as any;

        if (err?.http) {
            return res.status(err.http.status).json({ message: err.message, code: err.code });
        }

        if (err?.sqlState === "45000" || err?.errno === 1644) {
            return res.status(400).json({ message: err.sqlMessage || "Database validation error" });
        }

        if (err?.code === "ER_DUP_ENTRY") {
            return res.status(409).json({ message: err.sqlMessage || "Duplicate record" });
        }

        console.error(error);
        res.status(500).json({ message: "Unexpected server error" });
    }
};

