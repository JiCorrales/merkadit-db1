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



/**
 * The function `registerSaleHandler` handles registering a sale and returns appropriate responses
 * based on different error scenarios.
 * @param {Request} req - The `req` parameter in the `registerSaleHandler` function is of type
 * `Request`, which typically represents the HTTP request in Express.js or similar frameworks. It
 * contains information about the incoming request such as headers, parameters, body, etc.
 * @param {Response} res - The `res` parameter in the `registerSaleHandler` function is an object
 * representing the HTTP response that the server sends back to the client. It allows you to send data
 * back to the client, set status codes, and more. In the provided code snippet, `res` is used to send
 * @returns The `registerSaleHandler` function is returning a response based on the outcome of
 * registering a sale. If the sale registration is successful, it returns a status of 201 (Created)
 * along with the result in JSON format. If an error occurs during the registration process, it handles
 * different types of errors as follows:
 */


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

